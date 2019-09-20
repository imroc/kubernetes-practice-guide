# 无法登录容器

通常是 apiserver --&gt; kubelet:10250 之间的网络不通，10250 是 kubelet 提供接口的端口，`kubectl exec`和`kubectl logs` 的原理就是 apiserver 调 kubelet，kubelet 再调 dockerd 来实现的，所以要保证 kubelet 10250 端口对 apiserver 放通。

* TKE托管集群通常不会出现此情况，master 不受节点安全组限制
* 如果是TKE独立集群，检查节点安全组是否对master节点放通了 10250 端口，如果没放通会导致 apiserver 无法访问 kubelet 10250 端口，从而导致无法进入容器或查看log\(`kubectl exec`和`kubectl logs`\)
* 检查防火墙、iptables规则是否对 10250 端口数据包进行了拦截

