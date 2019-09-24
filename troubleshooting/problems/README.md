# 问题排查

本章包含使用 K8S 过程中可能会发生的各种问题现象及其对应的可能原因和排查方法，根据下面的问题导航可以快速定位问题现象，进一步排查分析。

## 问题导航

* [Pod 排错](pod/README.md)
  * [Pod 一直处于 Pending 状态](pod/keep-pending.md)
  * [Pod 一直处于 ContainerCreating 或 Waiting 状态](pod/keep-containercreating-or-waiting.md)
  * [Pod 一直处于 CrashLoopBackOff 状态](pod/keep-crashloopbackoff.md)
  * [Pod 一直处于 Terminating 状态](pod/keep-terminating.md)
  * [Pod 一直处于 Unknown 状态](pod/keep-unkown.md)
  * [Pod 一直处于 Error 状态](pod/keep-error.md)
  * [Pod 一直处于 ImagePullBackOff 状态](pod/keep-imagepullbackoff.md)
  * [Pod 一直处于 ImageInspectError 状态](pod/keep-imageinspecterror.md)
  * [Pod Terminating 慢](pod/slow-terminating.md)
  * [Pod 健康检查失败](pod/healthcheck-failed.md)
  * [容器进程主动退出](pod/container-proccess-exit-by-itself.md)
* [网络排错](network/README.md)
  * [LB 健康检查失败](network/lb-healthcheck-failed.md)
  * [DNS 解析异常](network/dns.md)
  * [Service 不通](network/service-unrecheable.md)
  * [Service 无法解析](network/service-cannot-resolve.md)
* [集群排错](cluster/README.md)
  * [Node 全部消失](cluster/node-all-gone.md)
  * [Daemonset 没有被调度](cluster/daemonset-not-scheduled.md)
* [其它排错](others/README.md)
  * [Job 无法被删除](others/job-cannot-delete.md)
  * [kubectl 执行 exec 或 logs 失败](others/kubectl-exec-or-logs-failed.md)
