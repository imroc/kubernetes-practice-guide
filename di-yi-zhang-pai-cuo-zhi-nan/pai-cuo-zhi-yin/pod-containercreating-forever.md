# Pod 一直 ContainerCreating

查看 Pod 事件

```bash
$ kubectl describe pod/apigateway-6dc48bf8b6-l8xrw -n cn-staging
```

## no space left on device

```bash
...
Events:
  Type     Reason                  Age                  From                   Message
  ----     ------                  ----                 ----                   -------
  Warning  FailedCreatePodSandBox  2m (x4307 over 16h)  kubelet, 10.179.80.31  (combined from similar events): Failed create pod sandbox: rpc error: code = Unknown desc = failed to create a sandbox for pod "apigateway-6dc48bf8b6-l8xrw": Error response from daemon: mkdir /var/lib/docker/aufs/mnt/1f09d6c1c9f24e8daaea5bf33a4230de7dbc758e3b22785e8ee21e3e3d921214-init: no space left on device
```

node上磁盘满了，无法创建和删除 pod，解决方法参考Kubernetes最佳实践：[处理容器数据磁盘被写满](https://github.com/imroc/kubernetes-practice-guide/tree/e375974b6b4d8a6bda007b50c3894825bce26932/troubleshooting/best-practice/kubernetes-best-practice-handle-disk-full.md)

## Error syncing pod

![](https://github.com/imroc/kubernetes-practice-guide/tree/e375974b6b4d8a6bda007b50c3894825bce26932/troubleshooting/pod/images/pod-containercreating-event.png)

* 可能是节点的内存碎片化严重，导致无法创建pod

## signal: killed

![](https://github.com/imroc/kubernetes-practice-guide/tree/e375974b6b4d8a6bda007b50c3894825bce26932/troubleshooting/pod/images/pod-containercreating-bad-limit.png)

memory limit 单位写错，误将memory的limit单位像request一样设置为小 `m`，这个单位在memory不适用，应该用`Mi`或`M`，会被k8s识别成byte，所以pause容器一起来就会被 cgroup-oom kill 掉，导致pod状态一直处于ContainerCreating

## controller-manager 异常

查看 master 上 kube-controller-manager 状态，异常的话尝试重启

