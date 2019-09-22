# Pod 排错

本章介绍 Pod 运行状态异常的排错方法，可能的原因以及解决方法，**利用右侧文章目录结构导航可以快速找到相应的问题和解决方案**。

排查过程常用的命名如下:

* 查看 Pod 状态: `kubectl get pod <pod-name> -o wide`
* 查看 Pod 的 yaml 配置: `kubectl get pod <pod-name> -o yaml`
* 查看 Pod 事件: `kubectl describe pod <pod-name>`
* 查看容器日志: `kubectl logs <pod-name> [-c <container-name>]`

## Pod 一直处于 Pending 状态

Pending 状态说明 Pod 还没有被调度到某个节点上，需要看下 Pod 事件进一步判断原因，比如:

``` bash
$ kubectl describe pod tikv-0
...
Events:
  Type     Reason            Age                 From               Message
  ----     ------            ----                ----               -------
  Warning  FailedScheduling  3m (x106 over 33m)  default-scheduler  0/4 nodes are available: 1 node(s) had no available volume zone, 2 Insufficient cpu, 3 Insufficient memory.
```

下面列举下可能原因和解决方法。

### 节点资源不够

节点资源不够有以下几种情况:

* CPU 负载过高
* 剩余可以被分配的内存不够
* 剩余可用 GPU 数量不够 (通常在机器学习场景，GPU 集群环境)

``` bash
```

如果判断某个 Node 资源是否足够？ 通过 `kubectl describe node <node-name>` 查看 node 资源情况，关注以下信息：

* `Allocatable`: 表示此节点能够申请的资源总和
* `Allocated resources`: 表示此节点已分配的资源 (Allocatable 减去节点上所有 Pod 总的 Request)

前者与后者相减，可得出剩余可申请的资源。如果这个值小于 Pod 的 request，就不满足 Pod 的资源要求，Scheduler 在 Predicates (预选) 阶段就会剔除掉这个 Node，也就不会调度上去。

### 不满足 nodeSelector 与 affinity

如果 Pod 包含 nodeSelector 指定了节点需要包含的 label，调度器将只会考虑将 Pod 调度到包含这些 label 的 Node 上，如果没有 Node 有这些 label 或者有这些 label 的 Node 其它条件不满足也将会无法调度。参考官方文档：https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector

如果 Pod 包含 affinity（亲和性）的配置，调度器根据调度算法也可能算出没有满足条件的 Node，从而无法调度。affinity 有以下几类:

* nodeAffinity: 节点亲和性，可以看成是增强版的 nodeSelector，用于限制 Pod 只允许被调度到某一部分 Node。
* podAffinity: Pod 亲和性，用于将一些有关联的 Pod 调度到同一个地方，同一个地方可以是指同一个节点或同一个可用区的节点等。
* podAntiAffinity: Pod 反亲和性，用于避免将某一类 Pod 调度到同一个地方避免单点故障，比如将集群 DNS 服务的 Pod 副本都调度到不同节点，避免一个节点挂了造成整个集群 DNS 解析失败，使得业务中断。

### Node 存在 Pod 没有容忍的污点

如果节点上存在污点 (Taints)，而 Pod 没有响应的容忍 (Tolerations)，Pod 也将不会调度上去。通过 describe node 可以看下 Node 有哪些 Taints:

``` bash
$ kubectl describe nodes host1
...
Taints:             special=true:NoSchedule
...
```

污点既可以是手动添加也可以是被自动添加，下面来深入分析一下。

#### 手动添加的污点

通过类似以下方式可以给节点添加污点:

``` bash
$ kubectl taint node host1 special=true:NoSchedule
node "host1" tainted
```

另外，有些场景下希望新加的节点默认不调度 Pod，直到调整完节点上某些配置才允许调度，就给新加的节点都加上 `node.kubernetes.io/unschedulable` 这个污点。

#### 自动添加的污点

如果节点运行状态不正常，污点也可以被自动添加，从 v1.12 开始，`TaintNodesByCondition` 特性进入 Beta 默认开启，controller manager 会检查 Node 的 Condition，如果命中条件就自动为 Node 加上相应的污点，这些 Condition 与 Taints 的对应关系如下:

``` txt
Conditon               Value       Taints
--------               -----       ------
OutOfDisk              True        node.kubernetes.io/out-of-disk
Ready                  False       node.kubernetes.io/not-ready
Ready                  Unknown     node.kubernetes.io/unreachable
MemoryPressure         True        node.kubernetes.io/memory-pressure
PIDPressure            True        node.kubernetes.io/pid-pressure
DiskPressure           True        node.kubernetes.io/disk-pressure
NetworkUnavailable     True        node.kubernetes.io/network-unavailable
```

解释下上面各种条件的意思:

* OutOfDisk 为 True 表示节点磁盘空间不够了
* Ready 为 False 表示节点不健康
* Ready 为 Unknown 表示节点失联，在 `node-monitor-grace-period` 这么长的时间内没有上报状态 controller-manager 就会将 Node 状态置为 Unknown (默认 40s)
* MemoryPressure 为 True 表示节点内存压力大，实际可用内存很少
* PIDPressure 为 True 表示节点上运行了太多进程，PID 数量不够用了
* DiskPressure 为 True 表示节点上的磁盘可用空间太少了
* NetworkUnavailable 为 True 表示节点上的网络没有正确配置，无法跟其它 Pod 正常通信

另外，在云环境下，比如腾讯云 TKE，添加新节点会先给这个 Node 加上 `node.cloudprovider.kubernetes.io/uninitialized` 的污点，等 Node 初始化成功后才自动移除这个污点，避免 Pod 被调度到没初始化好的 Node 上。

#### 镜像无法下载

看下 pod 的 event，看下是否是因为网络原因无法下载镜像或者下载私有镜像给的 secret 不对

#### 低版本 kube-scheduler 的 bug

可能是低版本 `kube-scheduler` 的 bug, 可以升级下调度器版本。

#### kube-scheduler 没有正常运行

检查 maser 上的 `kube-scheduler` 是否运行正常，异常的话可以尝试重启临时恢复。

## Pod 一直处于 ContainerCreating 或 Waiting 状态

### Pod 配置错误

* 检查是否打包了正确的镜像
* 检查配置了正确的容器参数

### 挂载 Volume 失败

Volume 挂载失败也分许多种情况，先列下我这里目前已知的。

#### Pod 漂移没有正常解挂之前的磁盘

在云尝试托管的 K8S 服务环境下，默认挂载的 Volume 一般是块存储类型的云硬盘，如果某个节点挂了，kubelet 无法正常运行或与 apiserver 通信，到达时间阀值后会触发驱逐，自动在其它节点上启动相同的副本 (Pod 漂移)，但是由于被驱逐的 Node 无法正常运行并不知道自己被驱逐了，也就没有正常执行解挂，cloud-controller-manager 也在等解挂成功后再调用云厂商的接口将磁盘真正从节点上解挂，通常会等到一个时间阀值后 cloud-controller-manager 会强制解挂云盘，然后再将其挂载到 Pod 最新所在节点上，这种情况下 ContainerCreating 的时间相对长一点，但一般最终是可以启动成功的，除非云厂商的 cloud-controller-manager 逻辑有 bug。

#### 命中 K8S 挂载 configmap/secret 的 subpath 的 bug

最近发现如果 Pod 挂载了 configmap 或 secret， 如果后面修改了 configmap 或 secret 的内容，Pod 里的容器又原地重启了(比如存活检查失败被 kill 然后重启拉起)，就会触发 K8S 的这个 bug，团队的小伙伴已提 PR: https://github.com/kubernetes/kubernetes/pull/82784

如果是这种情况，容器会一直启动不成功，可以看到类似以下的报错:

``` bash
$ kubectl -n prod get pod -o yaml manage-5bd487cf9d-bqmvm
...
lastState: terminated
containerID: containerd://e6746201faa1dfe7f3251b8c30d59ebf613d99715f3b800740e587e681d2a903
exitCode: 128
finishedAt: 2019-09-15T00:47:22Z
message: 'failed to create containerd task: OCI runtime create failed: container_linux.go:345:
starting container process caused "process_linux.go:424: container init
caused \"rootfs_linux.go:58: mounting \\\"/var/lib/kubelet/pods/211d53f4-d08c-11e9-b0a7-b6655eaf02a6/volume-subpaths/manage-config-volume/manage/0\\\"
to rootfs \\\"/run/containerd/io.containerd.runtime.v1.linux/k8s.io/e6746201faa1dfe7f3251b8c30d59ebf613d99715f3b800740e587e681d2a903/rootfs\\\"
at \\\"/run/containerd/io.containerd.runtime.v1.linux/k8s.io/e6746201faa1dfe7f3251b8c30d59ebf613d99715f3b800740e587e681d2a903/rootfs/app/resources/application.properties\\\"
caused \\\"no such file or directory\\\"\"": unknown'
```

### 容器数据磁盘被写满

启动 Pod 会调 CRI 接口创建容器，容器运行时创建容器时通常会在数据目录下为新建的容器创建一些目录和文件，如果数据目录所在的磁盘空间满了就会创建失败并报错:

```bash
Events:
  Type     Reason                  Age                  From                   Message
  ----     ------                  ----                 ----                   -------
  Warning  FailedCreatePodSandBox  2m (x4307 over 16h)  kubelet, 10.179.80.31  (combined from similar events): Failed create pod sandbox: rpc error: code = Unknown desc = failed to create a sandbox for pod "apigateway-6dc48bf8b6-l8xrw": Error response from daemon: mkdir /var/lib/docker/aufs/mnt/1f09d6c1c9f24e8daaea5bf33a4230de7dbc758e3b22785e8ee21e3e3d921214-init: no space left on device
```

解决方法参考处理实践：处理容器数据磁盘被写满(TODO)

### 节点内存碎片化

如果节点上内存碎片化严重，缺少大页内存，会导致即使总的剩余内存较多，但还是会申请内存失败，参考 [处理实践: 内存碎片化](https://k8s.imroc.io/troubleshooting/handling-practice/memory-fragmentation)

### limit 设置太小或者单位不对

如果 limit 设置过小以至于不足以成功运行 Sandbox 也会造成这种状态，常见的是因为 memory limit 单位设置不对造成的 limit 过小，比如误将 memory 的 limit 单位像 request 一样设置为小 `m`，这个单位在 memory 不适用，会被 k8s 识别成 byte，  应该用 `Mi` 或 `M`。，

举个例子: 如果 memory limit 设为 1024m 表示限制 1.024 Byte，这么小的内存， pause 容器一起来就会被 cgroup-oom kill 掉，导致 pod 状态一直处于 ContainerCreating。

这种情况通常会报下面的 event:

``` txt
Pod sandbox changed, it will be killed and re-created。
```

kubelet 报错:

``` txt
to start sandbox container for pod ... Error response from daemon: OCI runtime create failed: container_linux.go:348: starting container process caused "process_linux.go:301: running exec setns process for init caused \"signal: killed\"": unknown
```

### 拉取镜像失败

镜像拉取失败也分很多情况，这里列举下:

* 配置了错误的镜像
* Kubelet 无法访问镜像仓库（比如默认 pause 镜像在 gcr.io 上，国内环境访问需要特殊处理）
* 拉取私有镜像的 imagePullSecret 没有配置或配置有误
* 镜像太大，拉取超时（可以适当调整 kubelet 的 --image-pull-progress-deadline 和 --runtime-request-timeout 选项）

### CNI 网络错误

如果发生 CNI 网络错误通常需要检查下网络插件的配置和运行状态，如果没有正确配置或正常运行通常表现为:

* 无法配置 Pod 网络
* 无法分配 Pod IP

### controller-manager 异常

查看 master 上 kube-controller-manager 状态，异常的话尝试重启。

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

## Pod 一直处于 Error 状态

TODO: 展开优化

通常处于 Error 状态说明 Pod 启动过程中发生了错误。常见的原因包括：

* 依赖的 ConfigMap、Secret 或者 PV 等不存在
* 请求的资源超过了管理员设置的限制，比如超过了 LimitRange 等
* 违反集群的安全策略，比如违反了 PodSecurityPolicy 等
* 容器无权操作集群内的资源，比如开启 RBAC 后，需要为 ServiceAccount 配置角色绑定

## Pod 处于 CrashLoopBackOff 状态

Pod 如果处于 `CrashLoopBackOff` 状态说明之前是启动了，只是又异常退出了，只要 Pod 的 [restartPolicy](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy) 不是 Never 就可能被重启拉起，此时 Pod 的 `RestartCounts` 通常是大于 0 的，可以先看下容器进程的退出状态码来缩小问题范围，参考 [排错技巧: 分析 ExitCode 定位 Pod 异常退出原因](https://k8s.imroc.io/troubleshooting/trick/analysis-exitcode)

###  系统 OOM

TODO

### cgroup OOM

如果是 cgrou OOM 杀掉的进程，从 Pod 事件的下 `Reason` 可以看到是 `OOMKilled`，说明容器实际占用的内存超过 limit 了，可以根据需求调整下 limit。

### 节点内存碎片化

如果节点上内存碎片化严重，缺少大页内存，会导致即使总的剩余内存较多，但还是会申请内存失败，参考 [处理实践: 内存碎片化](https://k8s.imroc.io/troubleshooting/handling-practice/memory-fragmentation)

### 健康检查失败

TODO

### 镜像文件损坏

TODO

## Pod 一直处于 ImagePullBackOff 状态

### http 类型 registry，地址未加入到 insecure-registry

dockerd 默认从 https 类型的 registry 拉取镜像，如果使用 https 类型的 registry，则必须将它添加到 insecure-registry 参数中，然后重启或 reload dockerd 生效。

### https 自签发类型 resitry，没有给节点添加 ca 证书

如果 registry 是 https 类型，但证书是自签发的，dockerd 会校验 registry 的证书，校验成功才能正常使用镜像仓库，要想校验成功就需要将 registry 的 ca 证书放置到 `/etc/docker/certs.d/<registry:port>/ca.crt` 位置。

### 私有镜像仓库认证失败

如果 registry 需要认证，但是 Pod 没有配置 imagePullSecret，配置的 Secret 不存在或者有误都会认证失败。

### 镜像文件损坏

如果 push 的镜像文件损坏了，下载下来也用不了，需要重新 push 镜像文件。

### 镜像拉取超时

如果节点上新起的 Pod 太多就会有许多可能会造成容器镜像下载排队，如果前面有许多大镜像需要下载很长时间，后面排队的 Pod 就会报拉取超时。

kubelet 默认串行下载镜像:

``` txt
--serialize-image-pulls   Pull images one at a time. We recommend *not* changing the default value on nodes that run docker daemon with version < 1.9 or an Aufs storage backend. Issue #10959 has more details. (default true)
```

也可以开启并行下载并控制并发:

``` txt
--registry-qps int32   If > 0, limit registry pull QPS to this value.  If 0, unlimited. (default 5)
--registry-burst int32   Maximum size of a bursty pulls, temporarily allows pulls to burst to this number, while still not exceeding registry-qps. Only used if --registry-qps > 0 (default 10)

```

## Pod 一直处于 ImageInspectError 状态

通常是镜像文件损坏了，可以尝试删除损坏的镜像重新拉取

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

