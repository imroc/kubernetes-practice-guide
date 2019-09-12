# 节点 NotReady

查看 Node 事件: `kubectl get node -o yaml` 看看 ready 状态

### 提示网络有问题
网络的初始化是在Master中做的，一般都是Master问题
 
### 没有找到什么特殊信息
一般需要到节点上看看kubelet或者docker日志
 
## 附录

节点 NotReady 原因一般分为以下三种情况：
1. node上报健康心跳超时，一般是kubelet有问题、docker有问题、节点卡死等，此时node会被kube-controller-manager设置为notReady
2. kubelet主动上报不健康，从yaml和event中能看到原因，一般是磁盘空间满，内存满等，这种是使用的问题；磁盘满考虑是否是在容器里写文件到可写层了（没有写到挂载的外部磁盘，写到本机磁盘了），更详细的参考 Kubernetes 最佳实践: [处理容器数据磁盘被写满](../best-practice/kubernetes-best-practice-handle-disk-full.md)；如果是发生系统OOM，参考 Kubernetes 最佳实践：[合理设置 request 和 limit](../best-practice/set-request-limit.md)
3. 初始化的时候NotReady，一般是网络没初始化好或者 （1）的变种，比如kubelet没有起来等