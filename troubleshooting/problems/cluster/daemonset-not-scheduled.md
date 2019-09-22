# Daemonset 没有被调度

Daemonset 的期望实例为 0，可能原因:

* controller-manager 的 bug，重启 controller-manager 可以恢复
* controller-manager 挂了
