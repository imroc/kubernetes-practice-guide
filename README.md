# 序言

## Kubernetes 实践指南

本书正在起草初期，内容将包含大量 Kubernetes 实践干货，大量内容还正在路上，GitBook 左侧导航分不出哪些标题是有内容的，这里统一列举下，有超链接的是有内容的 \(请在 [https://k8s.imroc.io](https://k8s.imroc.io) 中打开\):

* 部署指南
  * 部署方案选型
  * 单机部署
  * 二进制部署
  * 工具部署
    * Kubeadm
    * Minikube
    * Bootkube
    * Ansible
* 插件扩展
  * 网络
  * 运行时
  * 存储
  * Ingress Controller
  * Scheduler Plugin
  * Device Plugin
  * Cloud Provider
  * Network Policy
* 排错指南
  * [问题排查](troubleshooting/problems/)
    * [Pod 排错](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/troubleshooting/problems/pod/README.md)
    * [网络排错](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/troubleshooting/problems/network/README.md)
    * [集群排错](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/troubleshooting/problems/cluster/README.md)
    * [其它排错](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/troubleshooting/problems/others/README.md)
  * [处理实践](troubleshooting/handling-practice/)
    * [高负载](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/troubleshooting/handling-practice/high-load/README.md)
    * [内存碎片化](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/troubleshooting/handling-practice/memory-fragmentation/README.md)
    * [磁盘空间满](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/troubleshooting/handling-practice/disk-full/README.md)
    * [inotify watch 耗尽](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/troubleshooting/handling-practice/runnig-out-of-inotify-watches/README.md)
  * [踩坑分享](troubleshooting/damn/)
    * [DNS 5 秒延时](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/troubleshooting/damn/dns-lookup-5s-delay/README.md)
    * [cgroup 泄露](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/troubleshooting/damn/cgroup-leaking/README.md)
    * [tcp\_tw\_recycle 引发丢包](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/troubleshooting/damn/lost-packets-in-nat-environment-once-enable-tcp_tw_recycle/README.md)
    * [驱逐导致服务中断](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/troubleshooting/damn/eviction-leads-to-service-disruption/README.md)
    * [conntrack 冲突导致丢包](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/troubleshooting/damn/conntrack-chong-tu-dao-zhi-diu-bao/README.md)
  * [排错技巧](troubleshooting/trick/)
    * [分析 ExitCode 定位 Pod 异常退出原因](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/troubleshooting/trick/analysis-exitcode/README.md)
    * [容器内抓包定位网络问题](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/troubleshooting/trick/capture-packets-in-container/README.md)
    * [使用 Systemtap 定位疑难杂症](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/troubleshooting/trick/use-systemtap-to-locate-problems/README.md)
* 最佳实践
  * 服务高可用
    * 使用反亲和性避免单点故障
    * [服务更新不中断](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/best-practice/ha/smooth-update/README.md)
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
    * [集群权限控制](best-practice/security/permission-control.md)
    * PodSecurityPolicy
    * 集群审计
  * GPU
  * 大页内存
  * 证书管理
    * [安装 cert-manager](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/best-practice/cert-manager/install-cert-manger/README.md)
    * [使用 cert-manager 自动生成证书](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/best-practice/cert-manager/autogenerate-certificate-with-cert-manager/README.md)
  * 配置管理
    * Helm
      * [安装 Helm](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/best-practice/configuration-management/helm/install-helm/README.md)
      * [Helm V2 迁移到 V3](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/best-practice/configuration-management/helm/upgrade-helm-v2-to-v3/README.md)
      * 使用 Helm 部署与管理应用
      * 开发 Helm Charts
    * Kustomize
      * Kustomize 基础入门
  * 备份恢复
  * 大规模集群
  * 集群迁移
  * 多集群
  * [泛域名转发](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/best-practice/wildcard-domain-forward/README.md)
  * [kubectl 实用技巧](https://github.com/imroc/kubernetes-practice-guide/tree/ad61a830bca96aaa0d2d8780b10e681fe9c15892/best-practice/kubectl-trick/README.md)
* 开发指南
  * 开发环境搭建
  * Operator
  * client-go
  * 社区贡献
* 领域应用
  * 微服务架构
  * Service Mesh
  * Serverless
  * DevOps
  * 人工智能
  * 大数据

## 在线阅读

本书将支持中英文两个语言版本，通常文章会先用中文起草并更新，等待其内容较为成熟完善，更新不再频繁的时候才会翻译成英文，点击左上角切换语言。

* 中文: [https://k8s.imroc.io](https://k8s.imroc.io)
* English: [https://k8s.imroc.io/v/en/](https://k8s.imroc.io/v/en/)

### 项目源码

项目源码存放于 Github 上: [https://github.com/imroc/kubernetes-practice-guide](https://github.com/imroc/kubernetes-practice-guide)

### 贡献

欢迎参与贡献和完善内容，贡献方法参考 [CONTRIBUTING](https://github.com/imroc/kubernetes-practice-guide/blob/master/CONTRIBUTING.md)

### License

![](https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png)

[署名-非商业性使用-相同方式共享 4.0 \(CC BY-NC-SA 4.0\)](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.zh)

