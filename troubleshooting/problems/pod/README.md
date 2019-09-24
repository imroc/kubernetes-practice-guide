# Pod 排错

本章介绍 Pod 运行状态异常的排错方法，可能的原因以及解决方法。

排查过程常用的命名如下:

* 查看 Pod 状态: `kubectl get pod <pod-name> -o wide`
* 查看 Pod 的 yaml 配置: `kubectl get pod <pod-name> -o yaml`
* 查看 Pod 事件: `kubectl describe pod <pod-name>`
* 查看容器日志: `kubectl logs <pod-name> [-c <container-name>]`

## 问题导航

* [Pod 一直处于 Pending 状态](troubleshooting/problems/pod/keep-pending.md)
* [Pod 一直处于 ContainerCreating 或 Waiting 状态](troubleshooting/problems/pod/keep-containercreating-or-waiting.md)
* [Pod 一直处于 CrashLoopBackOff 状态](troubleshooting/problems/pod/keep-crashloopbackoff.md)
* [Pod 一直处于 Terminating 状态](troubleshooting/problems/pod/keep-terminating.md)
* [Pod 一直处于 Unknown 状态](troubleshooting/problems/pod/keep-unkown.md)
* [Pod 一直处于 Error 状态](troubleshooting/problems/pod/keep-error.md)
* [Pod 一直处于 ImagePullBackOff 状态](troubleshooting/problems/pod/keep-imagepullbackoff.md)
* [Pod 一直处于 ImageInspectError 状态](troubleshooting/problems/pod/keep-imageinspecterror.md)
* [Pod Terminating 慢](troubleshooting/problems/pod/slow-terminating.md)
* [Pod 健康检查失败](troubleshooting/problems/pod/healthcheck-failed.md)
