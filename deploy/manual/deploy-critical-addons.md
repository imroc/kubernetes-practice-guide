# 部署关键附加组件

## 部署 kube-proxy

kube-proxy 会请求 apiserver 获取 Service 及其 Endpoint，将 Service 的 ClUSTER IP 与对应 Endpoint 的 Pod IP 映射关系转换成 iptables 或 ipvs 规则写到节点上，实现 Service 转发。

部署方法参考 [以 Daemonset 方式部署 kube-proxy](/deploy/addons/kube-proxy.md)

## 部署网络插件

参考 [部署 Flannel](/plugins/network/flannel/deploy.md)

## 部署集群 DNS

集群 DNS 是 Kubernetes 的核心功能之一，被许多服务所依赖，用于解析集群内 Pod 的 DNS 请求，包括:

* 解析 service 名称成对应的 CLUSTER IP
* 解析 headless service 名称成对应 Pod IP (选取一个 endpoint 的 Pod IP 返回)
* 解析外部域名(代理 Pod 请求上游 DNS)

可以通过部署 kube-dns 或 CoreDNS 作为集群的必备扩展来提供命名服务，推荐使用 CoreDNS，效率更高，资源占用率更小，部署方法参考 [部署 CoreDNS](/deploy/addons/coredns.md)
