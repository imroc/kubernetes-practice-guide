---
title: "使用反亲和性避免单点故障"
---

k8s 的设计就是假设节点是不可靠的，节点越多，发生软硬件故障导致节点不可用的几率就越高，所以我们通常需要给服务部署多个副本，根据实际情况调整 `replicas` 的值，如果值为 1 就必然存在单点故障，如果大于 1 但所有副本都调度到同一个节点，那还是有单点故障，所以我们不仅要有合理的副本数量，还需要让这些不同副本调度到不同的节点，打散开来避免单点故障，这个可以利用反亲和性来实现，示例:

``` yaml
affinity:
 podAntiAffinity:
   requiredDuringSchedulingIgnoredDuringExecution:
   - weight: 100
     labelSelector:
       matchExpressions:
       - key: k8s-app
         operator: In
         values:
         - kube-dns
     topologyKey: kubernetes.io/hostname
```

* `requiredDuringSchedulingIgnoredDuringExecution` 调度时必须满足该反亲和性条件，如果没有节点满足条件就不调度到任何节点 (Pending)。如果不用这种硬性条件可以使用 `preferredDuringSchedulingIgnoredDuringExecution` 来指示调度器尽量满足反亲和性条件，如果没有满足条件的也可以调度到某个节点。
* `labelSelector.matchExpressions` 写该服务对应 pod 中 labels 的 key 与 value。
* `topologyKey` 这里用 `kubernetes.io/hostname` 表示避免 pod 调度到同一节点，如果你有更高的要求，比如避免调度到同一个可用区，实现异地多活，可以用 `failure-domain.beta.kubernetes.io/zone`。通常不会去避免调度到同一个地域，因为一般同一个集群的节点都在一个地域，如果跨地域，即使用专线时延也会很大，所以 `topologyKey` 一般不至于用 `failure-domain.beta.kubernetes.io/region`。
