# Pod 排错

## Pod 一直处于 Pending 状态

### 资源不够

通过 `kubectl describe node` 查看 node 资源情况，关注以下信息：

* `Allocatable` 表示此节点 k8s 能够申请的资源总和
* `Allocated resources` 表示此节点已分配的资源

前者与后者相减，可得出剩余可申请的资源。如果这个值小于 pod 的 request，就不满足 pod 的资源要求，也就不会调度上去

### 资源够用，但是未被调度

#### node 不满足 pod 的 nodeSelector 或 affinity

检查 pod 是否有 nodeSelector 或 affinity（亲和性）的配置，如果有，可能是 node 不满足要求导致无法被调度

#### 旧 pod 无法解挂云盘

可能是 pod 之前在另一个节点，但之前节点或kubelet挂了，现在漂移到新的节点上，但是之前pod挂载了cbs云盘，而由于之前节点或kubelet挂了导致无法对磁盘进行解挂，pod 漂移到新的节点时需要挂载之前的cbs云盘，但由于磁盘未被之前的节点解挂，所以新的节点无法进行挂载导致pod一直pending。

解决方法：在云控制台找到对应的云主机或磁盘，手动对磁盘进行卸载，然后pod自动重启时就可以成功挂载了（也可以delete pod让它立即重新调度）

#### 镜像无法下载

看下 pod 的 event，看下是否是因为网络原因无法下载镜像或者下载私有镜像给的 secret 不对

#### 低版本 kube-scheduler 的 bug

可能是低版本 `kube-scheduler` 的 bug, 可以升级下调度器版本

## Pod 一直处于 ContainerCreating 或 Waiting 状态

查看 Pod 事件

```bash
$ kubectl describe pod/apigateway-6dc48bf8b6-l8xrw -n cn-staging
```

### 容器数据磁盘被写满

启动 Pod 会调 CRI 接口创建容器，容器运行时创建容器时通常会在数据目录下为新建的容器创建一些目录和文件，如果数据目录所在的磁盘空间满了就会创建失败并报错:

```bash
Events:
  Type     Reason                  Age                  From                   Message
  ----     ------                  ----                 ----                   -------
  Warning  FailedCreatePodSandBox  2m (x4307 over 16h)  kubelet, 10.179.80.31  (combined from similar events): Failed create pod sandbox: rpc error: code = Unknown desc = failed to create a sandbox for pod "apigateway-6dc48bf8b6-l8xrw": Error response from daemon: mkdir /var/lib/docker/aufs/mnt/1f09d6c1c9f24e8daaea5bf33a4230de7dbc758e3b22785e8ee21e3e3d921214-init: no space left on device
```

解决方法参考Kubernetes最佳实践：[处理容器数据磁盘被写满](https://github.com/imroc/kubernetes-practice-guide/tree/08d0c3fe178f3d54ec7849d9497a4cd83853dffa/best-practice/kubernetes-best-practice-handle-disk-full.md)

### Error syncing pod

![](https://github.com/imroc/kubernetes-practice-guide/tree/08d0c3fe178f3d54ec7849d9497a4cd83853dffa/troubleshooting/images/pod-containercreating-event.png)

* 可能是节点的内存碎片化严重，导致无法创建pod

### signal: killed

![](https://github.com/imroc/kubernetes-practice-guide/tree/08d0c3fe178f3d54ec7849d9497a4cd83853dffa/troubleshooting/images/pod-containercreating-bad-limit.png)

memory limit 单位写错，误将memory的limit单位像request一样设置为小 `m`，这个单位在memory不适用，应该用`Mi`或`M`，会被k8s识别成byte，所以pause容器一起来就会被 cgroup-oom kill 掉，导致pod状态一直处于ContainerCreating

### controller-manager 异常

查看 master 上 kube-controller-manager 状态，异常的话尝试重启

## Pod 一直处于 Terminating 状态

### 容器数据磁盘被写满

如果 docker 的数据目录所在磁盘被写满，docker 无法正常运行，无法进行删除和创建操作，所以 kubelet 调用 docker 删除容器没反应，看 event 类似这样：

```bash
Normal  Killing  39s (x735 over 15h)  kubelet, 10.179.80.31  Killing container with id docker://apigateway:Need to kill Pod
```

处理建议是参考Kubernetes 最佳实践：[处理容器数据磁盘被写满](https://github.com/imroc/kubernetes-practice-guide/tree/08d0c3fe178f3d54ec7849d9497a4cd83853dffa/solution/handle-disk-full.html)

### docker 17 的 bug

docker hang 住，没有任何响应，看 event:

```bash
Warning FailedSync 3m (x408 over 1h) kubelet, 10.179.80.31 error determining status: rpc error: code = DeadlineExceeded desc = context deadline exceeded
```

怀疑是17版本dockerd的BUG。可通过 `kubectl -n cn-staging delete pod apigateway-6dc48bf8b6-clcwk --force --grace-period=0` 强制删除pod，但 `docker ps` 仍看得到这个容器

处置建议：

* 升级到docker 18. 该版本使用了新的 containerd，针对很多bug进行了修复。
* 如果出现terminating状态的话，可以提供让容器专家进行排查，不建议直接强行删除，会可能导致一些业务上问题。

### 存在 Finalizers

k8s 资源的 metadata 里如果存在 `finalizers`，那么该资源一般是由某程序创建的，并且在其创建的资源的 metadata 里的 `finalizers` 加了一个它的标识，这意味着这个资源被删除时需要由创建资源的程序来做删除前的清理，清理完了它需要将标识从该资源的 `finalizers` 中移除，然后才会最终彻底删除资源。比如 Rancher 创建的一些资源就会写入 `finalizers` 标识。

处理建议：`kubectl edit` 手动编辑资源定义，删掉 `finalizers`，这时再看下资源，就会发现已经删掉了

### 低版本 kubelet list-watch 的 bug

之前遇到过使用 v1.8.13 版本的 k8s，kubelet 有时 list-watch 出问题，删除 pod 后 kubelet 没收到事件，导致 kubelet 一直没做删除操作，所以 pod 状态一直是 Terminating

## Pod Terminating 慢

可能原因:

* 进程通过 bash -c 启动导致 kill 信号无法透传给业务进程

## Pod 一直处于 Unknown 状态

通常是节点失联，没有上报状态给 apiserver，到达阀值后 controller-manager 认为节点失联并将其状态置为 `Unknown`。

可能原因:

* 节点高负载导致无法上报
* 节点宕机
* 网络不通

## Pod 处于 CrashLoopBackOff 状态

Pod 如果处于 `CrashLoopBackOff` 状态说明之前是启动了，只是又异常退出了，只要 Pod 的 [restartPolicy](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy) 不是 Never 就可能被重启拉起，此时 Pod 的 `RestartCounts` 通常是大于 0 的，可以先看下容器进程的退出状态码来缩小问题范围，参考 [实用技巧: 分析 ExitCode 定位 Pod 异常退出原因](https://github.com/imroc/kubernetes-practice-guide/tree/08d0c3fe178f3d54ec7849d9497a4cd83853dffa/troubleshooting/trick/analysis-exitcode/README.md)

可能原因:

* 系统 OOM
* cgroup OOM
* 节点高负载

看下 pod 状态:

```bash
$ kubectl get pod task-process-server-5f5bccc77-vkgr2
NAME                                  READY     STATUS    RESTARTS   AGE
task-process-server-5f5bccc77-vkgr2   1/1       Running   128        2d
```

`RESTARTS` 次数可以看出 pod 被重启的次数，如果看到 pod 状态变 `CrashLoopBackOff`，然后被自动重新拉起变成 Running，导致这个问题的可能原因有多个，我们来一步步排查。

describe 一下 pod，如果 event 还没被冲刷掉 \(k8s默认只保留1小时的 event\)，通常可以看到 `BackOff` 的 event:

```bash
Events:
  Type     Reason   Age                From               Message
  ----     ------   ----               ----               -------
  Warning  BackOff  15m (x6 over 4h)   kubelet, 10.0.8.4  Back-off restarting failed container
```

再看一下 pod 中容器上次的退出状态:

```bash
    Last State:     Terminated
      Reason:       Error
      Exit Code:    137
      Started:      Thu, 05 Sep 2019 19:22:30 +0800
      Finished:     Thu, 05 Sep 2019 19:33:44 +0800
```

* 先看下 `Reason`，如果是 `OOMKilled`，那说明是由于 OOM 被 kill 的 \(通常这种情况 Last State 里也没有 Finished 

## Pod 一直处于 ImagePullBackOff 状态

## Pod 无法登录或查看日志

通常是 apiserver --&gt; kubelet:10250 之间的网络不通，10250 是 kubelet 提供接口的端口，`kubectl exec`和`kubectl logs` 的原理就是 apiserver 调 kubelet，kubelet 再调 dockerd 来实现的，所以要保证 kubelet 10250 端口对 apiserver 放通。

* TKE托管集群通常不会出现此情况，master 不受节点安全组限制
* 如果是TKE独立集群，检查节点安全组是否对master节点放通了 10250 端口，如果没放通会导致 apiserver 无法访问 kubelet 10250 端口，从而导致无法进入容器或查看log\(`kubectl exec`和`kubectl logs`\)
* 检查防火墙、iptables规则是否对 10250 端口数据包进行了拦截

:\#\# Pod 健康检查失败

* Kubernetes 健康检查包含就绪检查\(readinessProbe\)和存活检查\(livenessProbe\)
* pod 如果就绪检查失败会将此 pod ip 从 service 中摘除，通过 service 访问，流量将不会被转发给就绪检查失败的 pod
* pod 如果存活检查失败，kubelet 将会杀死容器并尝试重启

健康检查失败的可能原因有多种，下面我们来逐个排查。

### 健康检查配置不合理

`initialDelaySeconds` 太短，容器启动慢，导致容器还没完全启动就开始探测，如果 successThreshold 是默认值 1，检查失败一次就会被 kill，然后 pod 一直这样被 kill 重启。

### 节点负载过高

cpu 占用高（比如跑满）会导致进程无法正常发包收包，通常会 timeout，导致 kubelet 认为 pod 不健康。参考本书 [节点高负载](https://github.com/imroc/kubernetes-practice-guide/tree/08d0c3fe178f3d54ec7849d9497a4cd83853dffa/node/high-load-on-node.html) 一节。

### 容器进程被木马进程杀死

参考 [使用 systemtap 定位疑难杂症](https://github.com/imroc/kubernetes-practice-guide/tree/08d0c3fe178f3d54ec7849d9497a4cd83853dffa/troubleshooting/trick/use-systemtap-to-locate-problems/README.md) 进一步定位。

### 容器内进程端口监听挂掉

使用 `netstat -tunlp` 检查端口监听是否还在，如果不在了会直接 reset 掉健康检查探测的连接:

```bash
20:15:17.890996 IP 172.16.2.1.38074 > 172.16.2.23.8888: Flags [S], seq 96880261, win 14600, options [mss 1424,nop,nop,sackOK,nop,wscale 7], length 0
20:15:17.891021 IP 172.16.2.23.8888 > 172.16.2.1.38074: Flags [R.], seq 0, ack 96880262, win 0, length 0
20:15:17.906744 IP 10.0.0.16.54132 > 172.16.2.23.8888: Flags [S], seq 1207014342, win 14600, options [mss 1424,nop,nop,sackOK,nop,wscale 7], length 0
20:15:17.906766 IP 172.16.2.23.8888 > 10.0.0.16.54132: Flags [R.], seq 0, ack 1207014343, win 0, length 0
```

连接异常，从而健康检查失败

