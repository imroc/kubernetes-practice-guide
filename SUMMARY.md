# Table of contents

* [序言](README.md)

## 部署指南 <a id="deploy"></a>

* 部署方案选型
* 单机部署
* 二进制部署
* 工具部署
  * Kubeadm
  * Minikube
  * Bootkube
  * Ansible

## 插件扩展 <a id="plugin"></a>

* 网络
* 运行时
* 存储
* Ingress Controller
* Scheduler Plugin
* Device Plugin
* Cloud Provider
* Network Policy

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

## 最佳实践

* 服务高可用
  * 使用反亲和性避免单点故障
  * [服务更新不中断](best-practice/ha/smooth-update)
  * 节点下线不停服
* 动态伸缩
  * 使用 HPA 对 Pod 水平伸缩
  * 使用 VPA 对 Pod 垂直伸缩
  * 使用 Cluster Autoscaler 对节点水平伸缩
* 资源限制
  * 资源预留
  * Request 与 Limit
  * Resource Quotas
  * Limit Ranges
* 资源隔离
  * 利用 kata-container 隔离容器资源
  * 利用 gVisor 隔离容器资源
  * 利用 lvm 和 xfs 实现容器磁盘隔离
  * 利用 lxcfs 隔离 proc 提升容器资源可见性
* 集群安全
  * [集群权限控制](best-practice/security/permission-control/README.md)
  * PodSecurityPolicy
  * 集群审计
* GPU
* 大页内存
* 证书管理
  * [安装 cert-manager](best-practice/cert-manager/install-cert-manger.md)
  * [使用 cert-manager 自动生成证书](best-practice/cert-manager/autogenerate-certificate-with-cert-manager.md)
* 配置管理
  * Helm
    * [安装 Helm](best-practice/configuration-management/helm/install-helm.md)
    * [Helm V2 迁移到 V3](best-practice/configuration-management/helm/upgrade-helm-v2-to-v3.md)
    * 使用 Helm 部署与管理应用
    * 开发 Helm Charts
  * Kustomize
    * Kustomize 基础入门
* 备份恢复
* 大规模集群
* 集群迁移
* 多集群
* [泛域名转发](best-practice/wildcard-domain-forward.md)
* [kubectl 实用技巧](best-practice/kubectl-trick.md)

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
