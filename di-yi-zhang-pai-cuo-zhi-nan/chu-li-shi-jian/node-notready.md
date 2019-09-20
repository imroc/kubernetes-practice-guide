# 节点 NotReady

TODO 优化

查看 Node 事件: `kubectl get node -o yaml` 看看 ready 状态

## 提示网络有问题

网络的初始化是在Master中做的，一般都是Master问题

## 没有找到什么特殊信息

一般需要到节点上看看kubelet或者docker日志

