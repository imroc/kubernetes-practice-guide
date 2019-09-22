# Service 无法解析

## 集群 DNS 没有正常运行\(kube-dns或CoreDNS\)

检查集群 DNS 是否运行正常:

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

## Pod 与 DNS 服务之间网络不通

检查下 pod 是否连不上 dns 服务，可以在 pod 里 telnet 一下 dns 的 53 端口:

```bash
# 连 dns service 的 cluster ip
$ telnet 172.16.14.217 53
```

如果检查到是网络不通，就需要排查下网络设置:

* 检查节点的安全组设置，需要放开集群的容器网段
* 检查是否还有防火墙规则，检查 iptables
