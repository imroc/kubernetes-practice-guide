# 大规模集群优化

Kubernetes 自 v1.6 以来，官方就宣称单集群最大支持 5000 个节点。不过这只是理论上，在具体实践中从 0 到 5000，还是有很长的路要走，需要见招拆招。

官方标准如下：

* 不超过 5000 个节点
* 不超过 150000 个 pod
* 不超过 300000 个容器
* 每个节点不超过 100 个 pod

## 内核参数调优

``` bash
# max-file 表示系统级别的能够打开的文件句柄的数量， 一般如果遇到文件句柄达到上限时，会碰到
# "Too many open files" 或者 Socket/File: Can’t open so many files 等错误
fs.file-max=1000000

# 配置 arp cache 大小
# 存在于 ARP 高速缓存中的最少层数，如果少于这个数，垃圾收集器将不会运行。缺省值是 128
net.ipv4.neigh.default.gc_thresh1=1024
# 保存在 ARP 高速缓存中的最多的记录软限制。垃圾收集器在开始收集前，允许记录数超过这个数字 5 秒。缺省值是 512
net.ipv4.neigh.default.gc_thresh2=4096
# 保存在 ARP 高速缓存中的最多记录的硬限制，一旦高速缓存中的数目高于此，垃圾收集器将马上运行。缺省值是 1024
net.ipv4.neigh.default.gc_thresh3=8192
# 以上三个参数，当内核维护的 arp 表过于庞大时候，可以考虑优化

# 允许的最大跟踪连接条目，是在内核内存中 netfilter 可以同时处理的“任务”（连接跟踪条目）
net.netfilter.nf_conntrack_max=10485760
net.netfilter.nf_conntrack_tcp_timeout_established=300
# 哈希表大小（只读）（64位系统、8G内存默认 65536，16G翻倍，如此类推）
net.netfilter.nf_conntrack_buckets=655360

# 每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目
net.core.netdev_max_backlog=10000

# 默认值: 128 指定了每一个 real user ID 可创建的 inotify instatnces 的数量上限
fs.inotify.max_user_instances=524288
# 默认值: 8192 指定了每个inotify instance相关联的watches的上限
fs.inotify.max_user_watches=524288
```

## ETCD 优化

### 高可用部署

部署一个高可用ETCD集群可以参考官方文档: https://github.com/etcd-io/etcd/blob/master/Documentation/op-guide/clustering.md

> 如果是 self-host 方式部署的集群，可以用 etcd-operator 部署 etcd 集群；也可以使用另一个小集群专门部署 etcd (使用 etcd-operator)

### 提高磁盘 IO 性能

ETCD 对磁盘写入延迟非常敏感，对于负载较重的集群建议磁盘使用 SSD 固态硬盘。可以使用 diskbench 或 fio 测量磁盘实际顺序 IOPS。

### 提高 ETCD 的磁盘 IO 优先级

由于 ETCD 必须将数据持久保存到磁盘日志文件中，因此来自其他进程的磁盘活动可能会导致增加写入时间，结果导致 ETCD 请求超时和临时 leader 丢失。当给定高磁盘优先级时，ETCD 服务可以稳定地与这些进程一起运行:

``` bash
sudo ionice -c2 -n0 -p $(pgrep etcd)
```

### 提高存储配额

默认 ETCD 空间配额大小为 2G，超过 2G 将不再写入数据。通过给 ETCD 配置 `--quota-backend-bytes` 参数增大空间配额，最大支持 8G。

### 分离 events 存储

集群规模大的情况下，集群中包含大量节点和服务，会产生大量的 event，这些 event 将会对 etcd 造成巨大压力并占用大量 etcd 存储空间，为了在大规模集群下提高性能，可以将 events 存储在单独的 ETCD 集群中。

配置 kube-apiserver：

``` bash
--etcd-servers="http://etcd1:2379,http://etcd2:2379,http://etcd3:2379" --etcd-servers-overrides="/events#http://etcd4:2379,http://etcd5:2379,http://etcd6:2379"
```

### 减小网络延迟

如果有大量并发客户端请求 ETCD leader 服务，则可能由于网络拥塞而延迟处理 follower 对等请求。在 follower 节点上的发送缓冲区错误消息：

``` bash
dropped MsgProp to 247ae21ff9436b2d since streamMsg's sending buffer is full
dropped MsgAppResp to 247ae21ff9436b2d since streamMsg's sending buffer is full
```

可以通过在客户端提高 ETCD 对等网络流量优先级来解决这些错误。在 Linux 上，可以使用 tc 对对等流量进行优先级排序：

``` bash
$ tc qdisc add dev eth0 root handle 1: prio bands 3
$ tc filter add dev eth0 parent 1: protocol ip prio 1 u32 match ip sport 2380 0xffff flowid 1:1
$ tc filter add dev eth0 parent 1: protocol ip prio 1 u32 match ip dport 2380 0xffff flowid 1:1
$ tc filter add dev eth0 parent 1: protocol ip prio 2 u32 match ip sport 2379 0xffff flowid 1:1
$ tc filter add dev eth0 parent 1: protocol ip prio 2 u32 match ip dport 2379 0xffff flowid 1:1
```

## Master 节点配置优化

GCE 推荐配置：

* 1-5 节点: n1-standard-1
* 6-10 节点: n1-standard-2
* 11-100 节点: n1-standard-4
* 101-250 节点: n1-standard-8
* 251-500 节点: n1-standard-16
* 超过 500 节点: n1-standard-32

AWS 推荐配置：

* 1-5 节点: m3.medium
* 6-10 节点: m3.large
* 11-100 节点: m3.xlarge
* 101-250 节点: m3.2xlarge
* 251-500 节点: c4.4xlarge
* 超过 500 节点: c4.8xlarge

对应 CPU 和内存为：

* 1-5 节点: 1vCPU 3.75G内存
* 6-10 节点: 2vCPU 7.5G内存
* 11-100 节点: 4vCPU 15G内存
* 101-250 节点: 8vCPU 30G内存
* 251-500 节点: 16vCPU 60G内存
* 超过 500 节点: 32vCPU 120G内存

## kube-apiserver 优化

### 高可用

* 方式一: 启动多个 kube-apiserver 实例通过外部 LB 做负载均衡。
* 方式二: 设置 `--apiserver-count` 和 `--endpoint-reconciler-type`，可使得多个 kube-apiserver 实例加入到 Kubernetes Service 的 endpoints 中，从而实现高可用。

不过由于 TLS 会复用连接，所以上述两种方式都无法做到真正的负载均衡。为了解决这个问题，可以在服务端实现限流器，在请求达到阀值时告知客户端退避或拒绝连接，客户端则配合实现相应负载切换机制。

### 控制连接数

kube-apiserver 以下两个参数可以控制连接数:

``` bash
--max-mutating-requests-inflight int           The maximum number of mutating requests in flight at a given time. When the server exceeds this, it rejects requests. Zero for no limit. (default 200)
--max-requests-inflight int                    The maximum number of non-mutating requests in flight at a given time. When the server exceeds this, it rejects requests. Zero for no limit. (default 400)
```

节点数量在 1000 - 3000 之间时，推荐：

``` bash
--max-requests-inflight=1500
--max-mutating-requests-inflight=500
```

节点数量大于 3000 时，推荐：

``` bash
--max-requests-inflight=3000
--max-mutating-requests-inflight=1000
```

## kube-scheduler 与 kube-controller-manager 优化

### 高可用

kube-controller-manager 和 kube-scheduler 是通过 leader election 实现高可用，启用时需要添加以下参数:

``` bash
--leader-elect=true
--leader-elect-lease-duration=15s
--leader-elect-renew-deadline=10s
--leader-elect-resource-lock=endpoints
--leader-elect-retry-period=2s
```

### 控制 QPS

与 kube-apiserver 通信的 qps 限制，推荐为：

``` bash
--kube-api-qps=100
```

## 集群 DNS 高可用

设置反亲和，让集群 DNS (kube-dns 或 coredns) 分散在不同节点，避免单点故障:

``` bash
affinity:
 podAntiAffinity:
   requiredDuringSchedulingIgnoredDuringExecution:
   - weight: 100
     labelSelector:
       matchExpressions:
       - key: k8s-app
         operator: In
         values:
         - kube-dns
     topologyKey: kubernetes.io/hostname
```