# PID 爆满

## 如何判断 PID 爆满

首先要确认当前的 PID 限制，检查全局 PID 最大限制:

``` bash
cat /proc/sys/kernel/pid_max
```

也检查下当前用户是否还有 `ulimit` 限制最大进程数。

然后要确认当前实际 PID 数量，检查当前用户的 PID 数量:

``` bash
ps -eLf | wc -l
```

如果发现实际 PID 数量接近最大限制说明 PID 就可能会爆满导致经常有进程无法启动，报错: `Cannot allocate memory`

## 如何解决

临时调大：

``` bash
echo 65535 > /proc/sys/kernel/pid_max
```

永久调大:

``` bash
echo "kernel.pid_max=65535 " >> /etc/sysctl.conf && sysctl -p
```
