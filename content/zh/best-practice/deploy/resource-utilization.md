---
title: "如何合理利用资源"
weight: 10
---

## 引言

业务容器化后，如何将其部署在 K8S 上？如果仅仅是将它跑起来，很简单，但如果是上生产，我们有许多地方是需要结合业务场景和部署环境进行方案选型和配置调优的。比如，如何设置容器的 Request 与 Limit、如何让部署的服务做到高可用、如何配置健康检查、如何进行弹性伸缩、如何更好的进行资源调度、如何选择持久化存储、如何对外暴露服务等。

对于这一系列高频问题，这里将会出一个 Kubernetes 服务部署最佳实践的系列的文章来为大家一一作答，本文将先围绕如何合理利用资源的主题来进行探讨。

## Request 与 Limit 怎么设置才好

如何为容器配置 Request 与 Limit? 这是一个即常见又棘手的问题，这个根据服务类型，需求与场景的不同而不同，没有固定的答案，这里结合生产经验总结了一些最佳实践，可以作为参考。

### 所有容器都应该设置 request

request 的值并不是指给容器实际分配的资源大小，它仅仅是给调度器看的，调度器会 "观察" 每个节点可以用于分配的资源有多少，也知道每个节点已经被分配了多少资源。被分配资源的大小就是节点上所有 Pod 中定义的容器 request 之和，它可以计算出节点剩余多少资源可以被分配(可分配资源减去已分配的 request 之和)。如果发现节点剩余可分配资源大小比当前要被调度的 Pod 的 reuqest 还小，那么就不会考虑调度到这个节点，反之，才可能调度。所以，如果不配置 request，那么调度器就不能知道节点大概被分配了多少资源出去，调度器得不到准确信息，也就无法做出合理的调度决策，很容易造成调度不合理，有些节点可能很闲，而有些节点可能很忙，甚至 NotReady。

所以，建议是给所有容器都设置 request，让调度器感知节点有多少资源被分配了，以便做出合理的调度决策，让集群节点的资源能够被合理的分配使用，避免陷入资源分配不均导致一些意外发生。

### 老是忘记设置怎么办

有时候我们会忘记给部分容器设置 request 与 limit，其实我们可以使用 LimitRange 来设置 namespace 的默认 request 与 limit 值，同时它也可以用来限制最小和最大的 request 与 limit。
示例:

``` yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
  namespace: test
spec:
  limits:
  - default:
      memory: 512Mi
	  cpu: 500m
    defaultRequest:
      memory: 256Mi
	  cpu: 100m
    type: Container
```

### 重要的线上应用改如何设置

节点资源不足时，会触发自动驱逐，将一些低优先级的 Pod 删除掉以释放资源让节点自愈。没有设置 request，limit 的 Pod 优先级最低，容易被驱逐；request 不等于 limit 的其次； request 等于 limit 的 Pod 优先级较高，不容易被驱逐。所以如果是重要的线上应用，不希望在节点故障时被驱逐导致线上业务受影响，就建议将 request 和 limit 设成一致。

### 怎样设置才能提高资源利用率

如果给给你的应用设置较高的 request 值，而实际占用资源长期远小于它的 request 值，导致节点整体的资源利用率较低。当然这对时延非常敏感的业务除外，因为敏感的业务本身不期望节点利用率过高，影响网络包收发速度。所以对一些非核心，并且资源不长期占用的应用，可以适当减少 request 以提高资源利用率。

如果你的服务支持水平扩容，单副本的 request 值一般可以设置到不大于 1 核，CPU 密集型应用除外。比如 coredns，设置到 0.1 核就可以，即 100m。

### 尽量避免使用过大的 request 与 limit

如果你的服务使用单副本或者少量副本，给很大的 request 与 limit，让它分配到足够多的资源来支撑业务，那么某个副本故障对业务带来的影响可能就比较大，并且由于 request 较大，当集群内资源分配比较碎片化，如果这个 Pod 所在节点挂了，其它节点又没有一个有足够的剩余可分配资源能够满足这个 Pod 的 request 时，这个 Pod 就无法实现漂移，也就不能自愈，加重对业务的影响。

相反，建议尽量减小 request 与 limit，通过增加副本的方式来对你的服务支撑能力进行水平扩容，让你的系统更加灵活可靠。

### 避免测试 namespace 消耗过多资源影响生产业务

若生产集群有用于测试的 namespace，如果不加以限制，可能导致集群负载过高，从而影响生产业务。可以使用 ResourceQuota 来限制测试 namespace 的 request 与 limit 的总大小。
示例:

``` yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: quota-test
  namespace: test
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi
```

## 如何让资源得到更合理的分配

设置 Request 能够解决让 Pod 调度到有足够资源的节点上，但无法做到更细致的控制。如何进一步让资源得到合理的使用？我们可以结合亲和性、污点与容忍等高级调度技巧，让 Pod 能够被合理调度到合适的节点上，让资源得到充分的利用。

### 使用亲和性

* 对节点有特殊要求的服务可以用节点亲和性 (Node Affinity) 部署，以便调度到符合要求的节点，比如让 MySQL 调度到高 IO 的机型以提升数据读写效率。
* 可以将需要离得比较近的有关联的服务用 Pod 亲和性 (Pod Affinity) 部署，比如让 Web 服务跟它的 Redis 缓存服务都部署在同一可用区，实现低延时。
* 也可使用 Pod 反亲和 (Pod AntiAffinity) 将 Pod 进行打散调度，避免单点故障或者流量过于集中导致的一些问题。

### 使用污点与容忍

使用污点 (Taint) 与容忍 (Toleration) 可优化集群资源调度:
* 通过给节点打污点来给某些应用预留资源，避免其它 Pod 调度上来。
* 需要使用这些资源的 Pod 加上容忍，结合节点亲和性让它调度到预留节点，即可使用预留的资源。

## 弹性伸缩

### 如何支持流量突发型业务

通常业务都会有高峰和低谷，为了更合理的利用资源，我们为服务定义 HPA，实现根据 Pod 的资源实际使用情况来对服务进行自动扩缩容，在业务高峰时自动扩容 Pod 数量来支撑服务，在业务低谷时，自动缩容 Pod 释放资源，以供其它服务使用（比如在夜间，线上业务低峰，自动缩容释放资源以供大数据之类的离线任务运行) 。

使用 HPA 前提是让 K8S 得知道你服务的实际资源占用情况(指标数据)，需要安装 resource metrics (metrics.k8s.io) 或 custom metrics (custom.metrics.k8s.io) 的实现，好让 hpa controller 查询这些 API 来获取到服务的资源占用情况。早期 HPA 用 resource metrics 获取指标数据，后来推出 custom metrics，可以实现更灵活的指标来控制扩缩容。官方有个叫 [metrics-server](https://github.com/kubernetes-sigs/metrics-server) 的实现，通常社区使用的更多的是基于 prometheus 的 实现 [prometheus-adapter](https://github.com/DirectXMan12/k8s-prometheus-adapter)，而云厂商托管的 K8S 集群通常集成了自己的实现，比如 TKE，实现了 CPU、内存、硬盘、网络等维度的指标，可以在网页控制台可视化创建 HPA，但最终都会转成 K8S 的 yaml，示例:

``` yaml
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx
spec:
  scaleTargetRef:
    apiVersion: apps/v1beta2
    kind: Deployment
    name: nginx
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Pods
    pods:
      metric:
        name: k8s_pod_rate_cpu_core_used_request
      target:
        averageValue: "100"
        type: AverageValue
```

### 如何节约成本

HPA 能实现 Pod 水平扩缩容，但如果节点资源不够用了，Pod 扩容出来还是会 Pending。如果我们提前准备好大量节点，做好资源冗余，提前准备好大量节点，通常不会有 Pod Pending 的问题，但也意味着需要付出更高的成本。通常云厂商托管的 K8S 集群都会实现 [cluster-autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)，即根据资源使用情况，动态增删节点，让计算资源能够被最大化的弹性使用，按量付费，以节约成本。在 TKE 上的实现叫做伸缩组，以及一个包含伸缩功能组但更高级的特性：节点池(正在灰度)

### 无法水平扩容的服务怎么办

对于无法适配水平伸缩的单体应用，或者不确定最佳 request 与 limit 超卖比的应用，可以尝用 [VPA](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler) 来进行垂直伸缩，即自动更新 request 与 limit，然后重启 pod。不过这个特性容易导致你的服务出现短暂的不可用，不建议在生产环境中大规模使用。


## 参考资料

* Understanding Kubernetes limits and requests by example: https://sysdig.com/blog/kubernetes-limits-requests/
* Understanding resource limits in kubernetes: cpu time: https://medium.com/@betz.mark/understanding-resource-limits-in-kubernetes-cpu-time-9eff74d3161b
* Understanding resource limits in kubernetes: memory: https://medium.com/@betz.mark/understanding-resource-limits-in-kubernetes-memory-6b41e9a955f9
* Kubernetes best practices: Resource requests and limits: https://cloud.google.com/blog/products/gcp/kubernetes-best-practices-resource-requests-and-limits
* Kubernetes 资源分配之 Request 和 Limit 解析: https://cloud.tencent.com/developer/article/1004976
* Assign Pods to Nodes using Node Affinity: https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes-using-node-affinity/
* Taints and Tolerations: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
* metrics-server: https://github.com/kubernetes-sigs/metrics-server
* prometheus-adapter: https://github.com/DirectXMan12/k8s-prometheus-adapter
* cluster-autoscaler: https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler
* VPA: https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler