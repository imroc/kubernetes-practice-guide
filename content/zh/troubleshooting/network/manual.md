---
title: "网络排错手册"
weight: 10
---

## 连接队列溢出

查看是否全连接或半连接队列溢出导致丢包，造成部分连接异常 (timeout):

``` bash
$ netstat -s | grep -E 'overflow|drop'
3327 times the listen queue of a socket overflowed
32631 SYNs to LISTEN sockets dropped
```

进入容器 netns 后，查看各状态的连接数统计:

``` bash
netstat -n | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}'
```

故障案例:
* 健康检查失败
* 网络时同时不通

解决方案:
* 调大 sommaxconn
* 调大 backlog
* 若是 nginx，还受 nginx 本身的 backlog 配置，也调大下

## conntrack 表爆满

看内核日志:
``` bash
# demsg
$ journalctl -k | grep "nf_conntrack: table full"
nf_conntrack: nf_conntrack: table full, dropping packet
```

若有以上报错，证明 conntrack 表满了，需要调大 conntrack 表:

``` bash
sysctl -w net.netfilter.nf_conntrack_max=1000000
```

## arp 表爆满

看内核日志:

``` bash
# demsg
$ journalctl -k | grep "neighbor table overflow"
arp_cache: neighbor table overflow!
```

若有以上报错，证明 arp 表满了，查看当前 arp 记录数:

``` bash
$ arp -an | wc -l
1335
```

查看 arp gc 阀值:

``` bash
$ sysctl -a | grep gc_thresh
net.ipv4.neigh.default.gc_thresh1 = 128
net.ipv4.neigh.default.gc_thresh2 = 512
net.ipv4.neigh.default.gc_thresh3 = 1024
```

调大 arp 表:
``` bash
sysctl -w net.ipv4.neigh.default.gc_thresh1=80000
sysctl -w net.ipv4.neigh.default.gc_thresh2=90000
sysctl -w net.ipv4.neigh.default.gc_thresh3=100000
```

## 端口监听挂掉

如果容器内的端口已经没有进程监听了，内核就会返回 Reset 包，客户端就会报错连接被拒绝，可以进容器 netns 检查下端口是否存活:

``` bash
netstat -tunlp
```

## tcp_tw_recycle 导致丢包

在低版本内核中(比如 3.10)，支持使用 tcp_tw_recycle 内核参数来开启 TIME_WAIT 的快速回收，但如果 client 也开启了 timestamp (一般默认开启)，同时也就会导致在 NAT 环境丢包，甚至没有 NAT 时，稍微高并发一点，也会导致 PAWS 校验失败，导致丢包:
``` bash
# 看 SYN 丢包是否全都是 PAWS 校验失败
$ cat /proc/net/netstat | grep TcpE| awk '{print $15, $22}'
PAWSPassive ListenDrops
96305 96305
```

参考资料:
* https://github.com/torvalds/linux/blob/v3.10/net/ipv4/tcp_ipv4.c#L1465
* https://www.freesoft.org/CIE/RFC/1323/13.htm 
* https://zhuanlan.zhihu.com/p/35684094
* https://my.oschina.net/u/4270811/blog/3473655/print
