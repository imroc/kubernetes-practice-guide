# 频繁 cgroup OOM 导致内核 crash

由于 linux 内核对 cgroup OOM 的处理，存在很多 bug，经常有由于频繁 cgroup OOM 导致节点故障(卡死， 重启， 进程异常但无法杀死)，于是 TKE 团队开发了 `oom-guard`，在用户态处理 cgroup OOM 规避了内核 bug。

## 原理

核心思想是在发生内核 cgroup OOM kill 之前，在用户空间杀掉超限的容器， 减少走到内核 cgroup 内存回收失败后的代码分支从而触发各种内核故障的机会。

### threshold notify

参考文档: https://lwn.net/Articles/529927/

`oom-guard` 会给 memory cgroup 设置 threshold notify， 接受内核的通知。

以一个例子来说明阀值计算通知原理: 一个 pod 设置的 memory limit 是 1000M， `oom-guard` 会根据配置参数计算出 margin:

``` txt
margin = 1000M * margin_ratio = 20M // 缺省margin_ratio是0.02
```

margin 最小不小于 mim_margin(缺省1M)， 最大不大于 max_margin(缺省为30M)。如果超出范围，则取 mim_margin 或 max_margin。计算 threshold = limit - margin ，也就是 1000M - 20M = 980M，把 980M 作为阈值设置给内核。当这个 pod 的内存使用量达到 980M 时， `oom-guard` 会收到内核的通知。

在触发阈值之前，`oom-gurad` 会先通过 `memory.force_empty` 触发相关 cgroup 的内存回收。 另外，如果触发阈值时，相关 cgroup 的 memory.stat 显示还有较多 cache， 则不会触发后续处理策略，这样当 cgroup 内存达到 limit 时，会内核会触发内存回收。 这个策略也会造成部分容器内存增长太快时，还是会触发内核 cgroup OOM

### 达到阈值后的处理策略

通过 `--policy` 参数来控制处理策略。目前有三个策略， 缺省策略是 process。

- `process`: 采用跟内核cgroup OOM killer相同的策略，在该cgroup内部，选择一个 oom_score 得分最高的进程杀掉。 通过 oom-guard 发送 SIGKILL 来杀掉进程
- `container`: 在该cgroup下选择一个 docker 容器，杀掉整个容器
- `noop`: 只记录日志，并不采取任何措施

### 事件上报

通过 webhook reporter 上报 k8s event，便于分析统计，使用`kubectl get event` 可以看到:

``` txt
LAST SEEN   FIRST SEEN   COUNT     NAME                            KIND      SUBOBJECT                  TYPE      REASON                   SOURCE                    MESSAGE
14s         14s          1         172.21.16.23.158b732d352bcc31   Node                                 Warning   OomGuardKillContainer    oom-guard, 172.21.16.23   {"hostname":"172.21.16.23","timestamp":"2019-03-13T07:12:14.561650646Z","oomcgroup":"/sys/fs/cgroup/memory/kubepods/burstable/pod3d6329e5-455f-11e9-a7e5-06925242d7ea/223d4795cc3b33e28e702f72e0497e1153c4a809de6b4363f27acc12a6781cdb","proccgroup":"/sys/fs/cgroup/memory/kubepods/burstable/pod3d6329e5-455f-11e9-a7e5-06925242d7ea/223d4795cc3b33e28e702f72e0497e1153c4a809de6b4363f27acc12a6781cdb","threshold":205520896,"usage":206483456,"killed":"16481(fakeOOM) ","stats":"cache 20480|rss 205938688|rss_huge 199229440|mapped_file 0|dirty 0|writeback 0|pgpgin 1842|pgpgout 104|pgfault 2059|pgmajfault 0|inactive_anon 8192|active_anon 203816960|inactive_file 0|active_file 0|unevictable 0|hierarchical_memory_limit 209715200|total_cache 20480|total_rss 205938688|total_rss_huge 199229440|total_mapped_file 0|total_dirty 0|total_writeback 0|total_pgpgin 1842|total_pgpgout 104|total_pgfault 2059|total_pgmajfault 0|total_inactive_anon 8192|total_active_anon 203816960|total_inactive_file 0|total_active_file 0|total_unevictable 0|","policy":"Container"}
```

## 使用方法

### 部署

保存部署 yaml: `oom-guard.yaml`:

``` yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: oomguard
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:oomguard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: oomguard
    namespace: kube-system
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: oom-guard
  namespace: kube-system
  labels:
    app: oom-guard
spec:
  selector:
    matchLabels:
      app: oom-guard
  template:
    metadata:
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: ""
      labels:
        app: oom-guard
    spec:
      serviceAccountName: oomguard
      hostPID: true
      hostNetwork: true
      dnsPolicy: ClusterFirst
      containers:
      - name: k8s-event-writer
        image: ccr.ccs.tencentyun.com/paas/k8s-event-writer:v1.6
        resources:
          limits:
            cpu: 10m
            memory: 60Mi
          requests:
            cpu: 10m
            memory: 30Mi
        args:
        - --logtostderr
        - --unix-socket=true
        env:
          - name: NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: status.hostIP
        volumeMounts:
        - name: unix
          mountPath: /unix
      - name: oomguard
        image: ccr.ccs.tencentyun.com/paas/oomguard:nosoft-v2
        imagePullPolicy: Always
        securityContext:
          privileged: true
        resources:
          limits:
            cpu: 10m
            memory: 60Mi
          requests:
            cpu: 10m
            memory: 30Mi
        volumeMounts:
        - name: cgroupdir
          mountPath: /sys/fs/cgroup/memory
        - name: unix
          mountPath: /unix
        - name: kmsg
          mountPath: /dev/kmsg
          readOnly: true
        command: ["/oom-guard"]
        args: 
        - --v=2
        - --logtostderr
        - --root=/sys/fs/cgroup/memory
        - --walkIntervalSeconds=277
        - --inotifyResetSeconds=701
        - --port=0
        - --margin-ratio=0.02
        - --min-margin=1
        - --max-margin=30
        - --guard-ms=50
        - --policy=container
        - --openSoftLimit=false
        - --webhook-url=http://localhost/message
        env:
          - name: NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: status.hostIP
      volumes:
      - name: cgroupdir
        hostPath:
          path: /sys/fs/cgroup/memory
      - name: unix
        emptyDir: {}
      - name: kmsg
        hostPath:
          path: /dev/kmsg
```

一键部署:

``` bash
kubectl apply -f oom-guard.yaml
```

检查是否部署成功：

``` bash
$ kubectl -n kube-system get ds oom-guard
NAME        DESIRED   CURRENT   READY     UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
oom-guard   2         2         2         2            2           <none>          6m
```

其中 **AVAILABLE** 数量跟节点数一致，说明所有节点都已经成功运行了 `oom-guard`。

### 查看 oom-guard 日志

``` bash
kubectl -n kube-system logs oom-guard-xxxxx oomguard
```

### 查看 oom 相关事件

``` bash
kubectl get events |grep CgroupOOM
kubectl get events |grep SystemOOM
kubectl get events |grep OomGuardKillContainer
kubectl get events |grep OomGuardKillProcess
```

### 卸载

``` bash
kubectl delete -f oom-guard.yaml
```

这个操作可能有点慢，如果一直不返回 (有节点 NotReady 时可能会卡住)，`ctrl+C` 终止，然后执行下面的脚本:

``` bash
for pod in `kubectl get pod -n kube-system | grep oom-guard | awk '{print $1}'`
do
 kubectl delete pod $pod -n kube-system --grace-period=0 --force
done
```

检查删除操作是否成功

``` bash
kubectl -n kube-system get ds oom-guard
```

提示 `...not found` 就说明删除成功了

## 关于开源

当前 `oom-gaurd` 暂未开源，正在做大量生产试验，后面大量反馈效果统计比较好的时候会考虑开源出来。
