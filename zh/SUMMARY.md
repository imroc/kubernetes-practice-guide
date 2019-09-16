# Summary

- [Introduction](README.md)

## 问题排查

- [问题定位技巧](troubleshooting/debug-skill/README.md)
  - [分析 ExitCode 定位 Pod 异常退出原因](troubleshooting/debug-skill/analysis-exitcode.md)
  - [容器内抓包定位网络问题](troubleshooting/debug-skill/capture-packets-in-container.md)
  - [使用 systemtap 定位疑难杂症](troubleshooting/debug-skill/use-systemtap-to-locate-problems.md)
- [Pod 问题]()
  - [健康检查失败](troubleshooting/pod/healthcheck-failed.md)
  - [Pod 异常重启](troubleshooting/pod/pod-restart.md)
  - [Pod 一直 Pending](troubleshooting/pod/pod-pending-forever.md)
  - [Pod 一直 ContainerCreating](troubleshooting/pod/pod-containercreating-forever.md)
  - [Pod 一直 Terminating](troubleshooting/pod/pod-terminating-forever.md)
  - [Pod 无法被 exec 和 logs](troubleshooting/pod/pod-cannot-exec-or-logs.md)
- [Job 无法被删除](troubleshooting/cannot-delete-job.md)
- [节点问题]()
  - [节点 NotReady](troubleshooting/node/node-notready.md)
  - [no space left on device](troubleshooting/node/no-space-left-on-device.md)
  - [Rancher 清除 Node 导致集群异常](troubleshooting/node/rancher-remove-node-cause-cluster-abnormal.md)
  - [内存碎片化](troubleshooting/node/memory-fragmentation.md)
  - [节点高负载](troubleshooting/node/high-load-on-node.md)
  - [驱逐导致服务中断](troubleshooting/node/eviction-leads-to-service-disruption.md)
- [Master 问题]()
  - [TODO:apiserver 响应慢]()
- [网络问题]()
  - [Service 访问不通](troubleshooting/network/service-unreachable.md)
  - [Service 无法解析](troubleshooting/network/service-cannot-resolve.md)
  - [LB 健康检查失败](troubleshooting/network/lb-healthcheck-failed.md)
  - [DNS 5秒延时](troubleshooting/network/dns-lookup-5s-delay.md)
  - [TODO:Pod 无法访问外网]()
  - [TODO:Pod 无法访问集群外的内网服务]()
- [Docker 问题]()
  - [TODO:容器内无法 mount]()
- [内核问题]()
  - [cgroup 泄露](troubleshooting/kernel/cgroup-leaking.md)
  - [inotify watch 耗尽](troubleshooting/kernel/runnig-out-of-inotify-watches.md)
  - [tcp_tw_recycle 导致在 NAT 环境会丢包](troubleshooting/kernel/lost-packets-in-nat-environment-once-enable-tcp_tw_recycle.md)
  - [arp_cache: neighbor table overflow!](troubleshooting/kernel/arp_cache-neighbor-table-overflow.md)
  - [TODO: cgroup oom 导致内核 crash]()

## 最佳实践

- [泛域名动态 Service 转发解决方案](solution/wildcard-domain-forward.md)
- [优雅热更新](solution/kubernetes-grace-update.md)
- [解决长连接服务扩容失效](solution/scale-keepalive-service.md)
- [TODO:处理容器磁盘被写满](solution/handle-disk-full.md)
- [TODO:Pod 原地升级]()
- [TODO:Pod 固定 IP]()

## 奇淫技巧

- [kubectl 高效技巧](trick/efficient-kubectl.md)

## Ingress

- [TODO:Nginx]()
- [TODO:Traefik]()
- [TODO:Envoy]()
- [TODO:Kong]()
- [TODO:Gloo]()
- [TODO:Contour]()
- [TODO:Ambassador]()
- [TODO:HAProxy]()
- [TODO:Skipper]()

## Service Mesh

- [TODO:Istio]()
- [TODO:Maesh]()
- [TODO:Kuma]()

## Serverless

- [TODO:Knative]()

## K8S 配置管理

- [TODO:Helm]()
- [TODO:Kustomize]()

## 网络方案

- [TODO:Flannel]()
- [TODO:Macvlan]()
- [TODO:Calico]()
- [TODO:Cilium]()
- [TODO:Kube-router]()
- [TODO:Kube-OVN]()
- [TODO:OpenVSwitch]()
