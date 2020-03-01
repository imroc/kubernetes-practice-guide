---
title: "神秘的溢出与丢包"
---

## 问题描述

有用户反馈大量图片加载不出来。

图片下载走的 k8s ingress，这个 ingress 路径对应后端 service 是一个代理静态图片文件的 nginx deployment，这个 deployment 只有一个副本，静态文件存储在 nfs 上，nginx 通过挂载 nfs 来读取静态文件来提供图片下载服务，所以调用链是：client --> k8s ingress --> nginx --> nfs。

## 猜测

猜测: ingress 图片下载路径对应的后端服务出问题了。

验证：在 k8s 集群直接 curl nginx 的 pod ip，发现不通，果然是后端服务的问题！

## 抓包

继续抓包测试观察，登上 nginx pod 所在节点，进入容器的 netns 中：

``` bash
# 拿到 pod 中 nginx 的容器 id
$ kubectl describe pod tcpbench-6484d4b457-847gl | grep -A10 "^Containers:" | grep -Eo 'docker://.*$' | head -n 1 | sed 's/docker:\/\/\(.*\)$/\1/'
49b4135534dae77ce5151c6c7db4d528f05b69b0c6f8b9dd037ec4e7043c113e

# 通过容器 id 拿到 nginx 进程 pid
$ docker inspect -f {{.State.Pid}} 49b4135534dae77ce5151c6c7db4d528f05b69b0c6f8b9dd037ec4e7043c113e
3985

# 进入 nginx 进程所在的 netns
$ nsenter -n -t 3985

# 查看容器 netns 中的网卡信息，确认下
$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
3: eth0@if11: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 56:04:c7:28:b0:3c brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.26.0.8/26 scope global eth0
       valid_lft forever preferred_lft forever
```

使用 tcpdump 指定端口 24568 抓容器 netns 中 eth0 网卡的包:

``` bash
tcpdump -i eth0 -nnnn -ttt port 24568
```

在其它节点准备使用 nc 指定源端口为 24568 向容器发包：

``` bash
nc -u 24568 172.16.1.21 80
```

观察抓包结果：

``` bash
00:00:00.000000 IP 10.0.0.3.24568 > 172.16.1.21.80: Flags [S], seq 416500297, win 29200, options [mss 1424,sackOK,TS val 3000206334 ecr 0,nop,wscale 9], length 0
00:00:01.032218 IP 10.0.0.3.24568 > 172.16.1.21.80: Flags [S], seq 416500297, win 29200, options [mss 1424,sackOK,TS val 3000207366 ecr 0,nop,wscale 9], length 0
00:00:02.011962 IP 10.0.0.3.24568 > 172.16.1.21.80: Flags [S], seq 416500297, win 29200, options [mss 1424,sackOK,TS val 3000209378 ecr 0,nop,wscale 9], length 0
00:00:04.127943 IP 10.0.0.3.24568 > 172.16.1.21.80: Flags [S], seq 416500297, win 29200, options [mss 1424,sackOK,TS val 3000213506 ecr 0,nop,wscale 9], length 0
00:00:08.192056 IP 10.0.0.3.24568 > 172.16.1.21.80: Flags [S], seq 416500297, win 29200, options [mss 1424,sackOK,TS val 3000221698 ecr 0,nop,wscale 9], length 0
00:00:16.127983 IP 10.0.0.3.24568 > 172.16.1.21.80: Flags [S], seq 416500297, win 29200, options [mss 1424,sackOK,TS val 3000237826 ecr 0,nop,wscale 9], length 0
00:00:33.791988 IP 10.0.0.3.24568 > 172.16.1.21.80: Flags [S], seq 416500297, win 29200, options [mss 1424,sackOK,TS val 3000271618 ecr 0,nop,wscale 9], length 0
```

SYN 包到容器内网卡了，但容器没回 ACK，像是报文到达容器内的网卡后就被丢了。看样子跟防火墙应该也没什么关系，也检查了容器 netns 内的 iptables 规则，是空的，没问题。

排除是 iptables 规则问题，在容器 netns 中使用 `netstat -s` 检查下是否有丢包统计:

``` bash
$ netstat -s | grep -E 'overflow|drop'
    12178939 times the listen queue of a socket overflowed
    12247395 SYNs to LISTEN sockets dropped
```

果然有丢包，为了理解这里的丢包统计，我深入研究了一下，下面插播一些相关知识。

<!--more-->
## syn queue 与 accept queue

Linux 进程监听端口时，内核会给它对应的 socket 分配两个队列：

* syn queue: 半连接队列。server 收到 SYN 后，连接会先进入 `SYN_RCVD` 状态，并放入 syn queue，此队列的包对应还没有完全建立好的连接（TCP 三次握手还没完成）。
* accept queue: 全连接队列。当 TCP 三次握手完成之后，连接会进入 `ESTABELISHED` 状态并从 syn queue 移到 accept queue，等待被进程调用 `accept()` 系统调用 "拿走"。

> 注意：这两个队列的连接都还没有真正被应用层接收到，当进程调用 `accept()` 后，连接才会被应用层处理，具体到我们这个问题的场景就是 nginx 处理 HTTP 请求。

为了更好理解，可以看下这张 TCP 连接建立过程的示意图：

![](https://imroc.io/assets/blog/troubleshooting-k8s-network/backlog.png)

## listen 与 accept

不管使用什么语言和框架，在写 server 端应用时，它们的底层在监听端口时最终都会调用 `listen()` 系统调用，处理新请求时都会先调用 `accept()` 系统调用来获取新的连接，然后再处理请求，只是有各自不同的封装而已，以 go 语言为例：

``` go
// 调用 listen 监听端口
l, err := net.Listen("tcp", ":80")
if err != nil {
	panic(err)
}
for {
	// 不断调用 accept 获取新连接，如果 accept queue 为空就一直阻塞
	conn, err := l.Accept()
	if err != nil {
		log.Println("accept error:", err)
		continue
    }
	// 每来一个新连接意味着一个新请求，启动协程处理请求
	go handle(conn)
}
```

## Linux 的 backlog

内核既然给监听端口的 socket 分配了 syn queue 与 accept queue 两个队列，那它们有大小限制吗？可以无限往里面塞数据吗？当然不行！ 资源是有限的，尤其是在内核态，所以需要限制一下这两个队列的大小。那么它们的大小是如何确定的呢？我们先来看下 listen 这个系统调用:

``` bash
int listen(int sockfd, int backlog)
```

可以看到，能够传入一个整数类型的 `backlog` 参数，我们再通过 `man listen` 看下解释：

`The behavior of the backlog argument on TCP sockets changed with Linux 2.2.  Now it specifies the queue length for completely established sockets waiting to  be  accepted,  instead  of  the  number  of  incomplete  connection requests.   The  maximum  length  of  the queue for incomplete sockets can be set using /proc/sys/net/ipv4/tcp_max_syn_backlog.  When syncookies are enabled there is no logical maximum length and this setting is ignored.  See tcp(7) for more information. `

`If the backlog argument is greater than the value in /proc/sys/net/core/somaxconn, then it is silently truncated to that value; the default value in this file is 128.  In kernels before 2.4.25, this limit  was  a  hard  coded value, SOMAXCONN, with the value 128.`

继续深挖了一下源码，结合这里的解释提炼一下：

* listen 的 backlog 参数同时指定了 socket 的 syn queue 与 accept queue 大小。
* accept queue 最大不能超过 `net.core.somaxconn` 的值，即: 
  ```
  max accept queue size = min(backlog, net.core.somaxconn)
  ```
* 如果启用了 syncookies (net.ipv4.tcp_syncookies=1)，当 syn queue 满了，server 还是可以继续接收 `SYN` 包并回复 `SYN+ACK` 给 client，只是不会存入 syn queue 了。因为会利用一套巧妙的 syncookies 算法机制生成隐藏信息写入响应的 `SYN+ACK` 包中，等 client 回 `ACK` 时，server 再利用 syncookies 算法校验报文，校验通过后三次握手就顺利完成了。所以如果启用了 syncookies，syn queue 的逻辑大小是没有限制的，
* syncookies 通常都是启用了的，所以一般不用担心 syn queue 满了导致丢包。syncookies 是为了防止 SYN Flood 攻击 (一种常见的 DDoS 方式)，攻击原理就是 client 不断发 SYN 包但不回最后的 ACK，填满 server 的 syn queue 从而无法建立新连接，导致 server 拒绝服务。
* 如果 syncookies 没有启用，syn queue 的大小就有限制，除了跟 accept queue 一样受 `net.core.somaxconn` 大小限制之外，还会受到 `net.ipv4.tcp_max_syn_backlog` 的限制，即:
  ```
  max syn queue size = min(backlog, net.core.somaxconn, net.ipv4.tcp_max_syn_backlog)
  ```

4.3 及其之前版本的内核，syn queue 的大小计算方式跟现在新版内核这里还不一样，详细请参考 commit [ef547f2ac16b](https://github.com/torvalds/linux/commit/ef547f2ac16bd9d77a780a0e7c70857e69e8f23f#diff-56ecfd3cd70d57cde321f395f0d8d743L43)

## 队列溢出

毫无疑问，在队列大小有限制的情况下，如果队列满了，再有新连接过来肯定就有问题。

翻下 linux 源码，看下处理 SYN 包的部分，在 `net/ipv4/tcp_input.c` 的 `tcp_conn_request` 函数:

``` c
if ((net->ipv4.sysctl_tcp_syncookies == 2 ||
     inet_csk_reqsk_queue_is_full(sk)) && !isn) {
	want_cookie = tcp_syn_flood_action(sk, rsk_ops->slab_name);
	if (!want_cookie)
		goto drop;
}

if (sk_acceptq_is_full(sk)) {
	NET_INC_STATS(sock_net(sk), LINUX_MIB_LISTENOVERFLOWS);
	goto drop;
}
```

`goto drop` 最终会走到 `tcp_listendrop` 函数，实际上就是将 `ListenDrops` 计数器 +1:

``` c
static inline void tcp_listendrop(const struct sock *sk)
{
	atomic_inc(&((struct sock *)sk)->sk_drops);
	__NET_INC_STATS(sock_net(sk), LINUX_MIB_LISTENDROPS);
}
```

大致可以看出来，对于 SYN 包：

* 如果 syn queue 满了并且没有开启 syncookies 就丢包，并将 `ListenDrops` 计数器 +1。
* 如果 accept queue 满了也会丢包，并将 `ListenOverflows` 和 `ListenDrops` 计数器 +1。

而我们前面排查问题通过 `netstat -s` 看到的丢包统计，其实就是对应的 `ListenOverflows` 和 `ListenDrops` 这两个计数器。

除了用 `netstat -s`，还可以使用 `nstat -az` 直接看系统内各个计数器的值:

``` bash
$ nstat -az | grep -E 'TcpExtListenOverflows|TcpExtListenDrops'
TcpExtListenOverflows           12178939              0.0
TcpExtListenDrops               12247395              0.0
```

另外，对于低版本内核，当 accept queue 满了，并不会完全丢弃 SYN 包，而是对 SYN 限速。把内核源码切到 3.10 版本，看 `net/ipv4/tcp_ipv4.c` 中 `tcp_v4_conn_request` 函数:

``` c
/* Accept backlog is full. If we have already queued enough
 * of warm entries in syn queue, drop request. It is better than
 * clogging syn queue with openreqs with exponentially increasing
 * timeout.
 */
if (sk_acceptq_is_full(sk) && inet_csk_reqsk_queue_young(sk) > 1) {
        NET_INC_STATS_BH(sock_net(sk), LINUX_MIB_LISTENOVERFLOWS);
        goto drop;
}
```

其中 `inet_csk_reqsk_queue_young(sk) > 1` 的条件实际就是用于限速，仿佛在对 client 说: 哥们，你慢点！我的 accept queue 都满了，即便咱们握手成功，连接也可能放不进去呀。

## 回到问题上来

总结之前观察到两个现象：

* 容器内抓包发现收到 client 的 SYN，但 nginx 没回包。
* 通过 `netstat -s` 发现有溢出和丢包的统计 (`ListenOverflows` 与 `ListenDrops`)。

根据之前的分析，我们可以推测是 syn queue 或 accept queue 满了。

先检查下 syncookies 配置:

``` bash
$ cat /proc/sys/net/ipv4/tcp_syncookies
1
```

确认启用了 `syncookies`，所以 syn queue 大小没有限制，不会因为 syn queue 满而丢包，并且即便没开启 `syncookies`，syn queue 有大小限制，队列满了也不会使 `ListenOverflows` 计数器 +1。

从计数器结果来看，`ListenOverflows` 和 `ListenDrops` 的值差别不大，所以推测很有可能是 accept queue 满了，因为当 accept queue 满了会丢 SYN 包，并且同时将 `ListenOverflows` 与 `ListenDrops` 计数器分别 +1。

如何验证 accept queue 满了呢？可以在容器的 netns 中执行 `ss -lnt` 看下:

``` bash
$ ss -lnt
State      Recv-Q Send-Q Local Address:Port                Peer Address:Port
LISTEN     129    128                *:80                             *:*
```

通过这条命令我们可以看到当前 netns 中监听 tcp 80 端口的 socket，`Send-Q` 为 128，`Recv-Q` 为 129。

什么意思呢？通过调研得知：

* 对于 `LISTEN` 状态，`Send-Q` 表示 accept queue 的最大限制大小，`Recv-Q` 表示其实际大小。
* 对于 `ESTABELISHED` 状态，`Send-Q` 和 `Recv-Q` 分别表示发送和接收数据包的 buffer。

所以，看这里输出结果可以得知 accept queue 满了，当 `Recv-Q` 的值比 `Send-Q` 大 1 时表明 accept queue 溢出了，如果再收到 SYN 包就会丢弃掉。

导致 accept queue 满的原因一般都是因为进程调用 `accept()` 太慢了，导致大量连接不能被及时 "拿走"。

那么什么情况下进程调用 `accept()` 会很慢呢？猜测可能是进程连接负载高，处理不过来。

而负载高不仅可能是 CPU 繁忙导致，还可能是 IO 慢导致，当文件 IO 慢时就会有很多 IO WAIT，在 IO WAIT 时虽然 CPU 不怎么干活，但也会占据 CPU 时间片，影响 CPU 干其它活。

最终进一步定位发现是 nginx pod 挂载的 nfs 服务对应的 nfs server 负载较高，导致 IO 延时较大，从而使 nginx 调用 `accept()` 变慢，accept queue 溢出，使得大量代理静态图片文件的请求被丢弃，也就导致很多图片加载不出来。

虽然根因不是 k8s 导致的问题，但也从中挖出一些在高并发场景下值得优化的点，请继续往下看。

## somaxconn 的默认值很小

我们再看下之前 `ss -lnt` 的输出:

``` bash
$ ss -lnt
State      Recv-Q Send-Q Local Address:Port                Peer Address:Port
LISTEN     129    128                *:80                             *:*
```

仔细一看，`Send-Q` 表示 accept queue 最大的大小，才 128 ？也太小了吧！

根据前面的介绍我们知道，accept queue 的最大大小会受 `net.core.somaxconn` 内核参数的限制，我们看下 pod 所在节点上这个内核参数的大小:

``` bash
$ cat /proc/sys/net/core/somaxconn
32768
```

是 32768，挺大的，为什么这里 accept queue 最大大小就只有 128 了呢？

`net.core.somaxconn` 这个内核参数是 namespace 隔离了的，我们在容器 netns 中再确认了下：

``` bash
$ cat /proc/sys/net/core/somaxconn
128
```

为什么只有 128？看下 stackoverflow [这里](https://stackoverflow.com/questions/26177059/refresh-net-core-somaxcomm-or-any-sysctl-property-for-docker-containers/26197875#26197875) 的讨论: 

`The "net/core" subsys is registered per network namespace. And the initial value for somaxconn is set to 128.`

原来新建的 netns 中 somaxconn 默认就为 128，在 `include/linux/socket.h` 中可以看到这个常量的定义:

``` c
/* Maximum queue length specifiable by listen.  */
#define SOMAXCONN	128
```

很多人在使用 k8s 时都没太在意这个参数，为什么大家平常在较高并发下也没发现有问题呢？

因为通常进程 `accept()` 都是很快的，所以一般 accept queue 基本都没什么积压的数据，也就不会溢出导致丢包了。

对于并发量很高的应用，还是建议将 somaxconn 调高。虽然可以进入容器 netns 后使用 `sysctl -w net.core.somaxconn=1024` 或 `echo 1024 > /proc/sys/net/core/somaxconn` 临时调整，但调整的意义不大，因为容器内的进程一般在启动的时候才会调用 `listen()`，然后 accept queue 的大小就被决定了，并且不再改变。

下面介绍几种调整方式:

### 方式一: 使用 k8s sysctls 特性直接给 pod 指定内核参数

示例 yaml:

``` yaml
apiVersion: v1
kind: Pod
metadata:
  name: sysctl-example
spec:
  securityContext:
    sysctls:
    - name: net.core.somaxconn
      value: "8096"
```

有些参数是 `unsafe` 类型的，不同环境不一样，我的环境里是可以直接设置 pod 的 `net.core.somaxconn` 这个 sysctl 的。如果你的环境不行，请参考官方文档 [Using sysctls in a Kubernetes Cluster](https://kubernetes-io-vnext-staging.netlify.com/docs/tasks/administer-cluster/sysctl-cluster/#enabling-unsafe-sysctls) 启用 `unsafe` 类型的 sysctl。

> 注：此特性在 k8s v1.12 beta，默认开启。

### 方式二: 使用 initContainers 设置内核参数

示例 yaml:

``` yaml
apiVersion: v1
kind: Pod
metadata:
  name: sysctl-example-init
spec:
  initContainers:
  - image: busybox
    command:
    - sh
    - -c
    - echo 1024 > /proc/sys/net/core/somaxconn
    imagePullPolicy: Always
    name: setsysctl
    securityContext:
      privileged: true
  Containers:
  ...
```

> 注: init container 需要 privileged 权限。

### 方式三: 安装 tuning CNI 插件统一设置 sysctl

tuning plugin 地址: https://github.com/containernetworking/plugins/tree/master/plugins/meta/tuning

CNI 配置示例:

``` bash
{
  "name": "mytuning",
  "type": "tuning",
  "sysctl": {
          "net.core.somaxconn": "1024"
  }
}
```

## nginx 的 backlog

我们使用方式一尝试给 nginx pod 的 somaxconn 调高到 8096 后观察:

``` bash
$ ss -lnt
State      Recv-Q Send-Q Local Address:Port                Peer Address:Port
LISTEN     512    511                *:80                             *:*
```

WTF? 还是溢出了，而且调高了 somaxconn 之后虽然 accept queue 的最大大小 (`Send-Q`) 变大了，但跟 8096 还差很远呀！

在经过一番研究，发现 nginx 在 `listen()` 时并没有读取 somaxconn 作为 backlog 默认值传入，它有自己的默认值，也支持在配置里改。通过 [ngx_http_core_module](http://nginx.org/en/docs/http/ngx_http_core_module.html) 的官方文档我们可以看到它在 linux 下的默认值就是 511:

```
backlog=number
   sets the backlog parameter in the listen() call that limits the maximum length for the queue of pending connections. By default, backlog is set to -1 on FreeBSD, DragonFly BSD, and macOS, and to 511 on other platforms.
```

配置示例:

``` bash
listen  80  default  backlog=1024;
```

所以，在容器中使用 nginx 来支撑高并发的业务时，记得要同时调整下 `net.core.somaxconn` 内核参数和 `nginx.conf` 中的 backlog 配置。

## 参考资料

* Using sysctls in a Kubernetes Cluster: https://kubernetes-io-vnext-staging.netlify.com/docs/tasks/administer-cluster/sysctl-cluster/
* SYN packet handling in the wild: https://blog.cloudflare.com/syn-packet-handling-in-the-wild/
