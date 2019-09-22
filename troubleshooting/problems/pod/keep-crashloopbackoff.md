# Pod 处于 CrashLoopBackOff 状态

Pod 如果处于 `CrashLoopBackOff` 状态说明之前是启动了，只是又异常退出了，只要 Pod 的 [restartPolicy](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy) 不是 Never 就可能被重启拉起，此时 Pod 的 `RestartCounts` 通常是大于 0 的，可以先看下容器进程的退出状态码来缩小问题范围，参考 [排错技巧: 分析 ExitCode 定位 Pod 异常退出原因](https://k8s.imroc.io/troubleshooting/trick/analysis-exitcode)

##  系统 OOM

TODO

## cgroup OOM

如果是 cgrou OOM 杀掉的进程，从 Pod 事件的下 `Reason` 可以看到是 `OOMKilled`，说明容器实际占用的内存超过 limit 了，可以根据需求调整下 limit。

## 节点内存碎片化

如果节点上内存碎片化严重，缺少大页内存，会导致即使总的剩余内存较多，但还是会申请内存失败，参考 [处理实践: 内存碎片化](https://k8s.imroc.io/troubleshooting/handling-practice/memory-fragmentation)

## 健康检查失败

TODO

## 镜像文件损坏

TODO