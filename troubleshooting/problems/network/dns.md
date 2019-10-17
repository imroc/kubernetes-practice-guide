# DNS 解析异常

## 5 秒延时

如果DNS查询经常延时5秒才返回，通常是遇到内核 conntrack 冲突导致的丢包，详见 [案例分享: DNS 5秒延时](/troubleshooting/damn/cases/dns-lookup-5s-delay.md)

## 解析超时

如果容器内报 DNS 解析超时，先检查下集群 DNS 服务 \(`kube-dns`/`coredns`\) 的 Pod 是否 Ready，如果不是，请参考本章其它小节定位原因。如果运行正常，再具体看下超时现象。

### 解析外部域名超时

可能原因:

* 上游 DNS 故障
* 上游 DNS 的 ACL 或防火墙拦截了报文

### 所有解析都超时

如果集群内某个 Pod 不管解析 Service 还是外部域名都失败，通常是 Pod 与集群 DNS 之间通信有问题。

可能原因:

* 节点防火墙没放开集群网段，导致如果 Pod 跟集群 DNS 的 Pod 不在同一个节点就无法通信，DNS 请求也就无法被收到