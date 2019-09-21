# Table of contents

* [序言](README.md)

## 部署指南 <a id="deploy"></a>

* 部署方案选型
* 单机部署
* 二进制部署
* 工具部署

## 插件扩展 <a id="plugin"></a>

* 网络
* 运行时
* 存储
* Ingress Controller
* Device 插件
* Cloud Provider

## 排错指南 <a id="troubleshooting"></a>

* [问题排查](troubleshooting/problems/README.md)
  * [Pod 排错](troubleshooting/problems/pod.md)
  * [网络排错](troubleshooting/problems/network.md)
  * [集群排错](troubleshooting/problems/cluster.md)
  * [其它排错](troubleshooting/problems/others.md)
* [处理实践](troubleshooting/handling-practice/README.md)
  * [高负载](troubleshooting/handling-practice/high-load.md)
  * [内存碎片化](troubleshooting/handling-practice/memory-fragmentation.md)
  * [磁盘空间满](troubleshooting/handling-practice/disk-full.md)
  * [inotify watch 耗尽](troubleshooting/handling-practice/runnig-out-of-inotify-watches.md)
* [踩坑分享](troubleshooting/damn/README.md)
  * [DNS 5 秒延时](troubleshooting/damn/dns-lookup-5s-delay.md)
  * [cgroup 泄露](troubleshooting/damn/cgroup-leaking.md)
  * [tcp\_tw\_recycle 引发丢包](troubleshooting/damn/lost-packets-in-nat-environment-once-enable-tcp_tw_recycle.md)
  * [驱逐导致服务中断](troubleshooting/damn/eviction-leads-to-service-disruption.md)
  * [conntrack 冲突导致丢包](troubleshooting/damn/conntrack-chong-tu-dao-zhi-diu-bao.md)
* [排错技巧](troubleshooting/trick/README.md)
  * [分析 ExitCode 定位 Pod 异常退出原因](troubleshooting/trick/analysis-exitcode.md)
  * [容器内抓包定位网络问题](troubleshooting/trick/capture-packets-in-container.md)
  * [使用 Systemtap 定位疑难杂症](troubleshooting/trick/use-systemtap-to-locate-problems.md)

## 开发指南 <a id="dev"></a>

* 开发环境搭建
* Operator
* client-go
* 社区贡献

## 领域应用 <a id="domain"></a>

* 微服务架构
* Service Mesh
* Serverless
* DevOps
* 人工智能
* 大数据
