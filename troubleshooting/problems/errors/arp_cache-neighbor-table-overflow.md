# arp_cache: neighbor table overflow!

节点内核报这个错说明当前节点 arp 缓存满了。

查看当前 arp 记录数:

``` bash
$ arp -an | wc -l
1335
```

查看 gc 阀值:

``` bash
$ sysctl -a | grep net.ipv4.neigh.default.gc_thresh
net.ipv4.neigh.default.gc_thresh1 = 128
net.ipv4.neigh.default.gc_thresh2 = 512
net.ipv4.neigh.default.gc_thresh3 = 1024
```

当前 arp 记录数接近 gc_thresh3 比较容易 overflow，因为当 arp 记录达到 gc_thresh3 时会强制触发 gc 清理，当这时又有数据包要发送，并且根据目的 IP 在 arp cache 中没找到 mac 地址，这时会判断当前 arp cache 记录数加 1 是否大于 gc_thresh3，如果没有大于就会 时就会报错: `neighbor table overflow!`

## 什么场景下会发生

集群规模大，node 和 pod 数量超多，参考本书避坑宝典的 [案例分享: ARP 缓存爆满导致健康检查失败](https://k8s.imroc.io/troubleshooting/damn/cases/arp-cache-overflow-causes-healthcheck-failed)

## 解决方案

调整部分节点内核参数，将 arp cache 的 gc 阀值调高 (`/etc/sysctl.conf`):

``` bash
net.ipv4.neigh.default.gc_thresh1 = 80000
net.ipv4.neigh.default.gc_thresh2 = 90000
net.ipv4.neigh.default.gc_thresh3 = 100000
```

并给 node 打下label，修改 pod spec，加下 nodeSelector 或者 nodeAffnity，让 pod 只调度到这部分改过内核参数的节点

## 参考资料

- Scaling Kubernetes to 2,500 Nodes: https://openai.com/blog/scaling-kubernetes-to-2500-nodes/
