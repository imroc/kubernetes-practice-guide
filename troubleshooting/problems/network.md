# 网络排错

## LB 健康检查失败

可能原因:

* 节点防火墙规则没放开 nodeport 区间端口 \(默认 30000-32768\) 检查iptables和云主机安全组
* LB IP 绑到 `kube-ipvs0` 导致丢源 IP为 LB IP 的包: [https://github.com/kubernetes/kubernetes/issues/79783](https://github.com/kubernetes/kubernetes/issues/79783)

## DNS 解析异常

### 5 秒延时

如果DNS查询经常延时5秒才返回，通常是遇到内核 conntrack 冲突导致的丢包，详见 [踩坑分享: DNS 5秒延时](https://github.com/imroc/kubernetes-practice-guide/tree/08d0c3fe178f3d54ec7849d9497a4cd83853dffa/damn/dns-lookup-5s-delay/README.md)

### 解析超时

如果容器内报 DNS 解析超时，先检查下集群 DNS 服务 \(`kube-dns`/`coredns`\) 的 Pod 是否 Ready，如果不是，请参考本章其它小节定位原因。如果运行正常，再具体看下超时现象。

#### 解析外部域名超时

可能原因:

* 上游 DNS 故障
* 上游 DNS 的 ACL 或防火墙拦截了报文

#### 所有解析都超时

如果集群内某个 Pod 不管解析 Service 还是外部域名都失败，通常是 Pod 与集群 DNS 之间通信有问题。

可能原因:

* 节点防火墙没放开集群网段，导致如果 Pod 跟集群 DNS 的 Pod 不在同一个节点就无法通信，DNS 请求也就无法被收到

## Service 访问不通

可能原因：

* 集群 dns 故障
* 节点防火墙没放开集群容器网络 \(iptables/安全组\)

## Service 无法解析

### 检查 dns 服务是否正常\(kube-dns或CoreDNS\)

* kubelet 启动参数 `--cluster-dns` 可以看到 dns 服务的 cluster ip:

```bash
$ ps -ef | grep kubelet
... /usr/bin/kubelet --cluster-dns=172.16.14.217 ...
```

* 找到 dns 的 service:

```bash
$ kubectl get svc -n kube-system | grep 172.16.14.217
kube-dns              ClusterIP   172.16.14.217   <none>        53/TCP,53/UDP              47d
```

* 看是否存在 endpoint:

```bash
$ kubectl -n kube-system describe svc kube-dns | grep -i endpoints
Endpoints:         172.16.0.156:53,172.16.0.167:53
Endpoints:         172.16.0.156:53,172.16.0.167:53
```

* 检查 endpoint 的 对应 pod 是否正常:

```bash
$ kubectl -n kube-system get pod -o wide | grep 172.16.0.156
kube-dns-898dbbfc6-hvwlr            3/3       Running   0          8d        172.16.0.156   10.0.0.3
```

### dns 服务正常，pod 与 dns 服务之间网络不通

* 检查 dns 服务运行正常，再检查下 pod 是否连不上 dns 服务，可以在 pod 里 telnet 一下 dns 的 53 端口:

```bash
# 连 dns service 的 cluster ip
$ telnet 172.16.14.217 53
```

* 如果检查到是网络不通，就需要排查下网络设置
  * 检查节点的安全组设置，需要放开集群的容器网段
  * 检查是否还有防火墙规则，检查 iptables

