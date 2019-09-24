# Pod 排错

本章介绍 Pod 运行状态异常的排错方法，可能的原因以及解决方法。

## 常用命令

排查过程常用的命名如下:

* 查看 Pod 状态: `kubectl get pod <pod-name> -o wide`
* 查看 Pod 的 yaml 配置: `kubectl get pod <pod-name> -o yaml`
* 查看 Pod 事件: `kubectl describe pod <pod-name>`
* 查看容器日志: `kubectl logs <pod-name> [-c <container-name>]`

## Pod 状态

Pod 有多种状态，这里罗列一下:

* `Error`: Pod 启动过程中发生错误
* `NodeLost`: Pod 所在节点失联
* `Unkown`: Pod 所在节点失联或其它未知异常
* `Waiting`: Pod 等待启动
* `Pending`: Pod 等待被调度
* `ContainerCreating`: Pod 容器正在被创建
* `Terminating`: Pod 正在被销毁
* `CrashLoopBackOff`： 容器退出，kubelet 正在将它重启
* `InvalidImageName`： 无法解析镜像名称
* `ImageInspectError`： 无法校验镜像
* `ErrImageNeverPull`： 策略禁止拉取镜像
* `ImagePullBackOff`： 正在重试拉取
* `RegistryUnavailable`： 连接不到镜像中心
* `ErrImagePull`： 通用的拉取镜像出错
* `CreateContainerConfigError`： 不能创建 kubelet 使用的容器配置
* `CreateContainerError`： 创建容器失败
* `RunContainerError`： 启动容器失败
* `PreStartHookError`: 执行 preStart hook 报错
* `PostStartHookError`： 执行 postStart hook 报错
* `ContainersNotInitialized`： 容器没有初始化完毕
* `ContainersNotReady`： 容器没有准备完毕
* `ContainerCreating`：容器创建中
* `PodInitializing`：pod 初始化中
* `DockerDaemonNotReady`：docker还没有完全启动
* `NetworkPluginNotReady`： 网络插件还没有完全启动

## 问题导航

有时候我们无法直接通过异常状态找到异常原因，这里我们罗列一下各种现象，点击即可进入相应的文章，帮助你分析问题，罗列各种可能的原因，进一步定位根因:

* [Pod 一直处于 Pending 状态](keep-pending.md)
* [Pod 一直处于 ContainerCreating 或 Waiting 状态](keep-containercreating-or-waiting.md)
* [Pod 一直处于 CrashLoopBackOff 状态](keep-crashloopbackoff.md)
* [Pod 一直处于 Terminating 状态](keep-terminating.md)
* [Pod 一直处于 Unknown 状态](keep-unkown.md)
* [Pod 一直处于 Error 状态](keep-error.md)
* [Pod 一直处于 ImagePullBackOff 状态](keep-imagepullbackoff.md)
* [Pod 一直处于 ImageInspectError 状态](keep-imageinspecterror.md)
* [Pod Terminating 慢](slow-terminating.md)
* [Pod 健康检查失败](healthcheck-failed.md)
