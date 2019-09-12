# Summary

- [Introduction](README.md)

## 问题排查

- [问题定位技巧](debug-skill/README.md)
  - [分析 ExitCode 定位 Pod 异常退出原因](debug-skill/analysis-exitcode.md)
  - [容器内抓包定位网络问题](debug-skill/capture-packets-in-container.md)
  - [使用 systemtap 定位疑难杂症](debug-skill/use-systemtap-to-locate-problems.md)
- [Pod 异常]()
  - [健康检查失败](pod-abnormal/healthcheck-failed.md)
  - [Pod 异常重启](pod-abnormal/pod-restart.md)
  - [Pod 一直 Pending](pod-abnormal/pod-pending-forever.md)
  - [Pod 一直 ContainerCreating](pod-abnormal/pod-containercreating-forever.md)
  - [Pod 一直 Terminating](pod-abnormal/pod-terminating-forever.md)
  - [Pod 无法被 exec 和 logs](pod-abnormal/pod-cannot-exec-or-logs.md)
- [节点异常]()
  - [节点 NotReady](node-abnormal/node-notready.md)
  - [no space left on device](node-abnormal/no-space-left-on-device.md)

## 内核相关

- [cgroup 泄露](kernel/cgroup-leaking.md)
- [inotify watch 耗尽](kernel/runnig-out-of-inotify-watches.md)
- [cgroup oom 导致内核 crash]()
