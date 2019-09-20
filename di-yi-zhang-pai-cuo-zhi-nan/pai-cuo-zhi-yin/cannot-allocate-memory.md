# Cannot allocate memory

容器启动失败，报错 `Cannot allocate memory`

## PID 满了

如果登录 ssh 困难，并且登录成功后执行任意命名经常报 `Cannot allocate memory`，多半是 PID 占满了。

看下 PID 限制:

```bash
cat /proc/sys/kernel/pid_max
```

也看下是否还有当前用户的 `ulimit` 限制最大进程数

再看下当前 PID 数量:

```bash
ps -eLf | wc -l
```

如果发现 PID 数量解决 limit，可以调大下限制:

临时调大：

```bash
echo 65535 > /proc/sys/kernel/pid_max
```

永久调大:

```bash
echo "kernel.pid_max=65535 " >> /etc/sysctl.conf && sysctl -p
```

