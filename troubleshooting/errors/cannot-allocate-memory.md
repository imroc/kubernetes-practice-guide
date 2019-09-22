# Cannot allocate memory

容器启动失败，报错 `Cannot allocate memory`。

## PID 爆满

如果登录 ssh 困难，并且登录成功后执行任意命名经常报 `Cannot allocate memory`，多半是 PID 占满了。

处理方法参考本书 [处理实践: PID 爆满](https://k8s.imroc.io/troubleshooting/errors/pid-full)