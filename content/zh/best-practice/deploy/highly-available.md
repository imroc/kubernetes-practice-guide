---
title: "如何提高服务可用性"
weight: 20
---

## 引言

[上一篇](../resource-utilization) 文章我们围绕如何合理利用资源的主题做了一些最佳实践的分享，这一次我们就如何提高服务可用性的主题来展开探讨。

怎样提高我们部署服务的可用性呢？K8S 设计本身就考虑到了各种故障的可能性，并提供了一些自愈机制以提高系统的容错性，但有些情况还是可能导致较长时间不可用，拉低服务可用性的指标。本文将结合生产实践经验，为大家提供一些最佳实践来最大化的提高服务可用性。


## 如何避免单点故障？

K8S 的设计就是假设节点是不可靠的。节点越多，发生软硬件故障导致节点不可用的几率就越高，所以我们通常需要给服务部署多个副本，根据实际情况调整 replicas 的值，如果值为 1 就必然存在单点故障，如果大于 1 但所有副本都调度到同一个节点了，那还是有单点故障，有时候还要考虑到灾难，比如整个机房不可用。

所以我们不仅要有合理的副本数量，还需要让这些不同副本调度到不同的拓扑域(节点、可用区)，打散调度以避免单点故障，这个可以利用 Pod 反亲和性来做到，反亲和主要分强反亲和与弱反亲和两种。

先来看个强反亲和的示例，将 dns 服务强制打散调度到不同节点上:

``` yaml
affinity:
 podAntiAffinity:
   requiredDuringSchedulingIgnoredDuringExecution:
   - labelSelector:
       matchExpressions:
       - key: k8s-app
         operator: In
         values:
         - kube-dns
     topologyKey: kubernetes.io/hostname
```

* `labelSelector.matchExpressions` 写该服务对应 pod 中 labels 的 key 与 value，因为 Pod 反亲和性是通过判断 replicas 的 pod label 来实现的。
* `topologyKey` 指定反亲和的拓扑域，即节点 label 的 key。这里用的 `kubernetes.io/hostname` 表示避免 pod 调度到同一节点，如果你有更高的要求，比如避免调度到同一个可用区，实现异地多活，可以用 `failure-domain.beta.kubernetes.io/zone`。通常不会去避免调度到同一个地域，因为一般同一个集群的节点都在一个地域，如果跨地域，即使用专线时延也会很大，所以 `topologyKey` 一般不至于用 `failure-domain.beta.kubernetes.io/region`。
* `requiredDuringSchedulingIgnoredDuringExecution` 调度时必须满足该反亲和性条件，如果没有节点满足条件就不调度到任何节点 (Pending)。


如果不用这种硬性条件可以使用 `preferredDuringSchedulingIgnoredDuringExecution` 来指示调度器尽量满足反亲和性条件，即弱反亲和性，如果实在没有满足条件的，只要节点有足够资源，还是可以让其调度到某个节点，至少不会 Pending。

我们再来看个弱反亲和的示例:

``` yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: k8s-app
            operator: In
            values:
            - kube-dns
      topologyKey: kubernetes.io/hostname
```

注意到了吗？相比强反亲和有些不同哦，多了一个 `weight`，表示此匹配条件的权重，而匹配条件被挪到了 `podAffinityTerm` 下面。

## 如何避免节点维护或升级时导致服务不可用？

有时候我们需要对节点进行维护或进行版本升级等操作，操作之前需要对节点执行驱逐 (kubectl drain)，驱逐时会将节点上的 Pod 进行删除，以便它们漂移到其它节点上，当驱逐完毕之后，节点上的 Pod 都漂移到其它节点了，这时我们就可以放心的对节点进行操作了。

有一个问题就是，驱逐节点是一种有损操作，驱逐的原理:

1. 封锁节点 (设为不可调度，避免新的 Pod 调度上来)。
2. 将该节点上的 Pod 删除。
3. ReplicaSet 控制器检测到 Pod 减少，会重新创建一个 Pod，调度到新的节点上。

这个过程是先删除，再创建，并非是滚动更新，因此更新过程中，如果一个服务的所有副本都在被驱逐的节点上，则可能导致该服务不可用。

我们再来下什么情况下驱逐会导致服务不可用:

1. 服务存在单点故障，所有副本都在同一个节点，驱逐该节点时，就可能造成服务不可用。
2. 服务没有单点故障，但刚好这个服务涉及的 Pod 全部都部署在这一批被驱逐的节点上，所以这个服务的所有 Pod 同时被删，也会造成服务不可用。
3. 服务没有单点故障，也没有全部部署到这一批被驱逐的节点上，但驱逐时造成这个服务的一部分 Pod 被删，短时间内服务的处理能力下降导致服务过载，部分请求无法处理，也就降低了服务可用性。

针对第一点，我们可以使用前面讲的反亲和性来避免单点故障。

针对第二和第三点，我们可以通过配置 PDB (PodDisruptionBudget) 来避免所有副本同时被删除，驱逐时 K8S 会 "观察" nginx 的当前可用与期望的副本数，根据定义的 PDB 来控制 Pod 删除速率，达到阀值时会等待 Pod 在其它节点上启动并就绪后再继续删除，以避免同时删除太多的 Pod 导致服务不可用或可用性降低，下面给出两个示例。

示例一 (保证驱逐时 nginx 至少有 90% 的副本可用):

``` yaml
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: zk-pdb
spec:
  minAvailable: 90%
  selector:
    matchLabels:
      app: zookeeper
```

示例二 (保证驱逐时 zookeeper 最多有一个副本不可用，相当于逐个删除并等待在其它节点完成重建):

``` yaml
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: zk-pdb
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app: zookeeper
```

## 如何让服务进行平滑更新？

解决了服务单点故障和驱逐节点时导致的可用性降低问题后，我们还需要考虑一种可能导致可用性降低的场景，那就是滚动更新。为什么服务正常滚动更新也可能影响服务的可用性呢？别急，下面我来解释下原因。

假如集群内存在服务间调用:

![](https://imroc.io/assets/blog/tke-best-practices-and-troubleshooting/rolling-update-interupt-connection-1.jpg)

当 server 端发生滚动更新时:

![](https://imroc.io/assets/blog/tke-best-practices-and-troubleshooting/rolling-update-interupt-connection-4.jpg)

发生两种尴尬的情况:
1. 旧的副本很快销毁，而 client 所在节点 kube-proxy 还没更新完转发规则，仍然将新连接调度给旧副本，造成连接异常，可能会报 "connection refused" (进程停止过程中，不再接受新请求) 或 "no route to host" (容器已经完全销毁，网卡和 IP 已不存在)。
2. 新副本启动，client 所在节点 kube-proxy 很快 watch 到了新副本，更新了转发规则，并将新连接调度给新副本，但容器内的进程启动很慢 (比如 Tomcat 这种 java 进程)，还在启动过程中，端口还未监听，无法处理连接，也造成连接异常，通常会报 "connection refused" 的错误。

针对第一种情况，可以给 container 加 preStop，让 Pod 真正销毁前先 sleep 等待一段时间，等待 client 所在节点 kube-proxy 更新转发规则，然后再真正去销毁容器。这样能保证在 Pod Terminating 后还能继续正常运行一段时间，这段时间如果因为 client 侧的转发规则更新不及时导致还有新请求转发过来，Pod 还是可以正常处理请求，避免了连接异常的发生。听起来感觉有点不优雅，但实际效果还是比较好的，分布式的世界没有银弹，我们只能尽量在当前设计现状下找到并实践能够解决问题的最优解。

针对第二种情况，可以给 container 加 ReadinessProbe (就绪检查)，让容器内进程真正启动完成后才更新 Service 的 Endpoint，然后 client 所在节点 kube-proxy 再更新转发规则，让流量进来。这样能够保证等 Pod 完全就绪了才会被转发流量，也就避免了链接异常的发生。

最佳实践 yaml 示例:

``` yaml
        readinessProbe:
          httpGet:
            path: /healthz
            port: 80
            httpHeaders:
            - name: X-Custom-Header
              value: Awesome
          initialDelaySeconds: 10
          timeoutSeconds: 1
        lifecycle:
          preStop:
            exec:
              command: ["/bin/bash", "-c", "sleep 10"]
```

## 健康检查怎么配才好？

我们都知道，给 Pod 配置健康检查也是提高服务可用性的一种手段，配置 ReadinessProbe (就绪检查) 可以避免将流量转发给还没启动完全或出现异常的 Pod；配置 LivenessProbe (存活检查) 可以让存在 bug 导致死锁或 hang 住的应用重启来恢复。但是，如果配置配置不好，也可能引发其它问题，这里根据一些踩坑经验总结了一些指导性的建议：

* 不要轻易使用 LivenessProbe，除非你了解后果并且明白为什么你需要它，参考 [Liveness Probes are Dangerous](https://srcco.de/posts/kubernetes-liveness-probes-are-dangerous.html)
* 如果使用 LivenessProbe，不要和 ReadinessProbe 设置成一样 (failureThreshold 更大)
* 探测逻辑里不要有外部依赖 (db, 其它 pod 等)，避免抖动导致级联故障
* 业务程序应尽量暴露 HTTP 探测接口来适配健康检查，避免使用 TCP 探测，因为程序 hang 死时， TCP 探测仍然能通过 (TCP 的 SYN 包探测端口是否存活在内核态完成，应用层不感知)

## 参考资料

* Affinity and anti-affinity: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity
* Specifying a Disruption Budget for your Application: https://kubernetes.io/docs/tasks/run-application/configure-pdb/
* Liveness Probes are Dangerous: https://srcco.de/posts/kubernetes-liveness-probes-are-dangerous.html
