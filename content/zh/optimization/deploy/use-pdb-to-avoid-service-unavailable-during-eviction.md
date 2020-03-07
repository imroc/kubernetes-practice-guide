---
title: "使用 PodDisruptionBudget 避免驱逐导致服务不可用"
---

驱逐节点是一种有损操作，驱逐的原理:

1. 封锁节点 (设为不可调度，避免新的 Pod 调度上来)。
2. 将该节点上的 Pod 删除。
3. ReplicaSet 控制器检测到 Pod 减少，会重新创建一个 Pod，调度到新的节点上。

这个过程是先删除，再创建，并非是滚动更新，因此更新过程中，如果一个服务的所有副本都在被驱逐的节点上，则可能导致该服务不可用。

我们再来下什么情况下驱逐会导致服务不可用:

1. 服务存在单点故障，所有副本都在同一个节点，驱逐该节点时，就可能造成服务不可用。
2. 服务在多个节点，但这些节点都被同时驱逐，所以这个服务的所有服务同时被删，也可能造成服务不可用。

针对第一点，我们可以 [使用反亲和性避免单点故障](#use-antiaffinity-to-avoid-single-points-of-failure)。

针对第二点，我们可以通过配置 PDB (PodDisruptionBudget) 来避免所有副本同时被删除，下面给出示例。

示例一 (保证驱逐时 zookeeper 至少有两个副本可用):

``` yaml
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: zk-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: zookeeper
```

示例二 (保证驱逐时 zookeeper 最多有一个副本不可用，相当于逐个删除并在其它节点重建):

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

更多请参考官方文档: https://kubernetes.io/docs/tasks/run-application/configure-pdb/