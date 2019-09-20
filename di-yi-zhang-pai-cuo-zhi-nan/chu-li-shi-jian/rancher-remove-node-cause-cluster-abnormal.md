# Rancher 清除 Node 导致集群异常

## 现象

安装了 rancher 的用户，在卸载 rancher 的时候，可能会手动执行 `kubectl delete ns local` 来删除这个 rancher 创建的 namespace，但直接这样做会导致所有 node 被清除，通过 `kubectl get node` 获取不到 node。

## 原因

看了下 rancher 源码，rancher 通过 `nodes.management.cattle.io` 这个 CRD 存储和管理 node，会给所有 node 创建对应的这个 CRD 资源，metadata 中加入了两个 finalizer，其中 `user-node-remove_local` 对应的 finalizer 处理逻辑就是删除对应的 k8s node 资源，也就是 `delete ns local` 时，会尝试删除 `nodes.management.cattle.io` 这些 CRD 资源，进而触发 rancher 的 finalizer 逻辑去删除对应的 k8s node 资源，从而清空了 node，所以 `kubectl get node` 就看不到 node 了，集群里的服务就无法被调度。

## 规避方案

不要在 rancher 组件卸载完之前手动 `delete ns local`。

