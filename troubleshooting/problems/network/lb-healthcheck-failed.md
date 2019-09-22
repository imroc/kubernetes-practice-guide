# LB 健康检查失败

可能原因:

* 节点防火墙规则没放开 nodeport 区间端口 \(默认 30000-32768\) 检查iptables和云主机安全组
* LB IP 绑到 `kube-ipvs0` 导致丢源 IP为 LB IP 的包: [https://github.com/kubernetes/kubernetes/issues/79783](https://github.com/kubernetes/kubernetes/issues/79783)

TODO: 完善
