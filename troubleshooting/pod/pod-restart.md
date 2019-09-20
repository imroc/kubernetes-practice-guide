# Pod 异常重启

TODO 优化

可能原因:

- 系统 OOM
- cgroup OOM
- 节点高负载

看下 pod 状态:

``` bash
$ kubectl get pod task-process-server-5f5bccc77-vkgr2
NAME                                  READY     STATUS    RESTARTS   AGE
task-process-server-5f5bccc77-vkgr2   1/1       Running   128        2d

```

`RESTARTS` 次数可以看出 pod 被重启的次数，如果看到 pod 状态变 `CrashLoopBackOff`，然后被自动重新拉起变成 Running，导致这个问题的可能原因有多个，我们来一步步排查。

describe 一下 pod，如果 event 还没被冲刷掉 (k8s默认只保留1小时的 event)，通常可以看到 `BackOff` 的 event:

``` bash
Events:
  Type     Reason   Age                From               Message
  ----     ------   ----               ----               -------
  Warning  BackOff  15m (x6 over 4h)   kubelet, 10.0.8.4  Back-off restarting failed container
```

再看一下 pod 中容器上次的退出状态:

``` bash
    Last State:     Terminated
      Reason:       Error
      Exit Code:    137
      Started:      Thu, 05 Sep 2019 19:22:30 +0800
      Finished:     Thu, 05 Sep 2019 19:33:44 +0800
```

- 先看下 `Reason`，如果是 `OOMKilled`，那说明是由于 OOM 被 kill 的 (通常这种情况 Last State 里也没有 Finished 