# Pod 一直 Pending

## 资源不够

通过 `kubectl describe node` 查看 node 资源情况，关注以下信息：

- `Allocatable` 表示此节点 k8s 能够申请的资源总和
- `Allocated resources` 表示此节点已分配的资源

前者与后者相减，可得出剩余可申请的资源。如果这个值小于 pod 的 request，就不满足 pod 的资源要求，也就不会调度上去

## 资源够用，但是未被调度

### node 不满足 pod 的 nodeSelector 或 affinity

检查 pod 是否有 nodeSelector 或 affinity（亲和性）的配置，如果有，可能是 node 不满足要求导致无法被调度

### 旧 pod 无法解挂 cbs 云盘

可能是 pod 之前在另一个节点，但之前节点或kubelet挂了，现在漂移到新的节点上，但是之前pod挂载了cbs云盘，而由于之前节点或kubelet挂了导致无法对磁盘进行解挂，pod 漂移到新的节点时需要挂载之前的cbs云盘，但由于磁盘未被之前的节点解挂，所以新的节点无法进行挂载导致pod一直pending。

解决方法：在腾讯云控制台找到对应的云主机或磁盘，手动对磁盘进行卸载，然后pod自动重启时就可以成功挂载了（也可以delete pod让它立即重新调度）

![](images/cvm-unmount-cbs.png)

### 镜像无法下载

看下 pod 的 event，看下是否是因为网络原因无法下载镜像或者下载私有镜像给的 secret 不对

### 低版本 kube-scheduler 的 bug

可能是低版本 `kube-scheduler` 的 bug, 可以升级下调度器版本