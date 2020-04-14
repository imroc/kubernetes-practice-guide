---
title: "Namespace 卡在 Terminating"
state: Alpha
---

## Namespace 上存在 Finalizers

删除 ns 后，一直卡在 Terminating 状态。通常是存在 finalizers，通过 `kubectl get ns xxx -o yaml` 可以看到是否有 finalizers:

``` bash
$ kubectl get ns -o yaml kube-node-lease
apiVersion: v1
kind: Namespace
metadata:
...
  finalizers:
  - finalizers.kubesphere.io/namespaces
  labels:
    kubesphere.io/workspace: system-workspace
  name: kube-node-lease
  ownerReferences:
  - apiVersion: tenant.kubesphere.io/v1alpha1
    blockOwnerDeletion: true
    controller: true
    kind: Workspace
    name: system-workspace
    uid: d4310acd-1fdc-11ea-a370-a2c490b9ae47
spec: {}
```

此例是因为之前装过 kubesphere，然后卸载了，但没有清理 finalizers，将其删除就可以了。

k8s 资源的 metadata 里如果存在 finalizers，那么该资源一般是由某应用创建的，或者是这个资源是此应用关心的。应用会在资源的 metadata 里的 finalizers 加了一个它自己可以识别的标识，这意味着这个资源被删除时需要由此应用来做删除前的清理，清理完了它需要将标识从该资源的 finalizers 中移除，然后才会最终彻底删除资源。比如 Rancher 创建的一些资源就会写入 finalizers 标识。

如果应用被删除，而finalizer没清理，删除资源时就会一直卡在terminating，可以手动删除finalizer来解决。

手动删除方法：
1. `kubectl edit ns xx` 删除 `spec.finalizers`。
2. 如果k8s版本较高会发现方法1行不通，因为高版本更改 namespace finalizers 被移到了 namespace 的 finalize 这个 subresource (参考[官方文档API文档](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/architecture/namespaces.md#rest-api))，并且需要使用 `PUT` 请求，可以先执行 `kubectl proxy` 然后再起一个终端用 curl 模拟请求去删 `finalizers`:
``` bash
curl -H "Content-Type: application/json" -XPUT -d '{"apiVersion":"v1","kind":"Namespace","metadata":{"name":"delete-me"},"spec":{"finalizers":[]}}' http://localhost:8001/api/v1/namespaces/delete-me/finalize
```
> 替换 `delete-me` 为你的 namespace 名称

参考资料:

* Node Lease 的 Proposal: https://github.com/kubernetes/enhancements/blob/master/keps/sig-node/0009-node-heartbeat.md

## metrics server 被删除

删除 ns 时，apiserver 会调注册上去的扩展 api 去清理资源，如果扩展 api 对应的服务也被删了，那么就无法清理完成，也就一直卡在 Terminating。

下面的例子就是使用 prometheus-adapter 注册的 resource metrics api，但 prometheus-adapter 已经被删除了:

``` bash
$ kubectl get apiservice
...
v1beta1.metrics.k8s.io                 monitoring/prometheus-adapter     False (ServiceNotFound)   75d
...
```
