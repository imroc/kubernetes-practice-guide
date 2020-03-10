---
title: "Native Kubernetes 模式部署"
weight: 40
state: Alpha
---

## 与 Kubernetes 集成

在 flink 1.10 之前，在 k8s 上运行 flink 任务都是需要事先指定 TaskManager 的个数以及CPU和内存的，存在一个问题：大多数情况下，你在任务启动前根本无法精确的预估这个任务需要多少个TaskManager，如果指定多了，会导致资源浪费，指定少了，会导致任务调度不起来。本质原因是在 Kubernetes 上运行的 Flink 任务并没有直接向 Kubernetes 集群去申请资源。

在 2020-02-11 发布了 flink 1.10，该版本完成了与 k8s 集成的第一阶段，实现了向 k8s 动态申请资源，就像跟 yarn 或 mesos 集成那样。

## 部署步骤

确定 flink 部署的 namespace，这里我选 "flink"，确保 namespace 已创建:

``` bash
kubectl create ns flink
```

创建 RBAC (创建 ServiceAccount 绑定 flink 需要的对 k8s 集群操作的权限):

``` yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flink
  namespace: flink

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: flink-role-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: edit
subjects:
- kind: ServiceAccount
  name: flink
  namespace: flink
```

利用 job 运行启动 flink 的引导程序 (请求 k8s 创建 jobmanager 相关的资源: service, deployment, configmap):

``` yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: boot-flink
  namespace: flink
spec:
  template:
    spec:
      serviceAccount: flink
      restartPolicy: OnFailure
      containers:
      - name: start
        image: flink:1.10
        workingDir: /opt/flink
        command: ["bash", "-c", "$FLINK_HOME/bin/kubernetes-session.sh \
          -Dkubernetes.cluster-id=roc \
          -Dkubernetes.jobmanager.service-account=flink \
          -Dtaskmanager.memory.process.size=1024m \
          -Dkubernetes.taskmanager.cpu=1 \
          -Dtaskmanager.numberOfTaskSlots=1 \
          -Dkubernetes.container.image=flink:1.10 \
          -Dkubernetes.namespace=flink"]
```

* `kubernetes.cluster-id`: 指定 flink 集群的名称，后续自动创建的 k8s 资源会带上这个作为前缀或后缀
* `kubernetes.namespace`: 指定 flink 相关的资源创建在哪个命名空间，这里我们用 `flink` 命名空间
* `kubernetes.jobmanager.service-account`: 指定我们刚刚为 flink 创建的 ServiceAccount
* `kubernetes.container.image`: 指定 flink 需要用的镜像，这里我们部署的 1.10 版本，所以镜像用 `flink:1.10`

部署完成后，我们可以看到有刚刚运行完成的 job 的 pod 和被这个 job 拉起的 flink jobmanager 的 pod，前缀与配置 `kubernetes.cluster-id` 相同:

``` bash
$ kubectl -n flink get pod
NAME                  READY   STATUS      RESTARTS   AGE
roc-cf9f6b5df-csk9z   1/1     Running     0          84m
boot-flink-nc2qx      0/1     Completed   0          84m
```

还有 jobmanager 的 service:

``` bash
$ kubectl -n flink get svc
NAME       TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
roc        ClusterIP      172.16.255.152   <none>           8081/TCP,6123/TCP,6124/TCP   88m
roc-rest   LoadBalancer   172.16.255.11    150.109.27.251   8081:31240/TCP               88m
```

访问 http://150.109.27.251:8081 即可进入此 flink 集群的 ui 界面。

## 参考资料

* Active Kubernetes integration phase 2 - Advanced Features: https://issues.apache.org/jira/browse/FLINK-14460
* Apache Flink 1.10.0 Release Announcement: https://flink.apache.org/news/2020/02/11/release-1.10.0.html
* Native Kubernetes Setup Beta (flink与kubernetes集成的官方教程): https://ci.apache.org/projects/flink/flink-docs-release-1.10/ops/deployment/native_kubernetes.html
