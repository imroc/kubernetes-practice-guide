# 序言

## Roadmap

本书正在起草初期，内容将包含大量 Kubernetes 实践干货，大量规划内容还正在路上，可以点击的表示是已经可以在左侧导航栏中找到的并预览的文章，但不代表已经完善，还会不断的补充和优化。

* 部署指南
  * 部署方案选型
  * 单机部署
  * [手工部署](/deploy/manual/README.md)
    * [部署前的准备工作](/deploy/manual/prepare.md)
    * [部署 ETCD](/deploy/manual/bootstrapping-etcd.md)
    * [部署 Master](/deploy/manual/bootstrapping-master.md)
    * [部署 Worker 节点](/deploy/manual/bootstrapping-worker-nodes.md)
    * [部署关键附加组件](/deploy/manual/deploy-critical-addons.md)
  * 使用 Kubeadm 部署集群
  * 使用 Minikube 部署测试集群
  * 使用 Bootkube 部署集群
  * 使用 Ansible 部署集群
  * [部署附加组件](/deploy/addons/README.md)
    * [部署 CoreDNS](/deploy/addons/coredns.md)
    * [以 Daemonset 方式部署 kube-proxy](/deploy/addons/kube-proxy.md)

* 集群方案
  * [网络方案](/plan/network/README.md)
    * 彻底理解集群网络
    * Network Policy
    * 开源网络方案
    * [Flannel](/plan/network/flannel/README.md)
      * Flannel 网络原理
      * [部署 Flannel](/plan/network/flannel/deploy.md)
    * Macvlan
    * Calico
    * Cilium
    * Kube-router
    * Kube-OVN
    * OpenVSwitch
  * 运行时方案
    * Docker
    * Containerd
    * CRI-O
  * 存储方案
    * Rook
    * OpenEBS
  * Ingress 方案
    * Nginx
    * Traefik
    * Contour
    * Ambassador
    * Kong
    * Gloo
    * HAProxy
    * Istio
    * Skipper
  * LoadBalancer 方案
    * MetalLB
    * Porter
  * metrics 方案
    * metrics-server

* 用法实践
  * 弹性伸缩
    * 使用 HPA 对 Pod 水平伸缩
    * 使用 VPA 对 Pod 垂直伸缩
    * 使用 Cluster Autoscaler 对节点水平伸缩
  * 资源分配与限制
    * 资源预留
    * Request 与 Limit
    * Resource Quotas
    * Limit Ranges
    * GPU
    * 大页内存
  * [集群权限控制](/usage/permission/README.md)
    * [控制用户权限](/usage/permission/user.md)
    * [控制应用权限](/usage/permission/app.md)
  * 有状态服务部署
  * [实用工具和技巧](/usage/useful/README.md)
    * [kubectl 高效技巧](/usage/useful/efficient-kubectl.md)
    * [实用 yaml 片段](/usage/useful/yaml.md)
    * 实用命令脚本

* 解决方案
  * [服务高可用](/solution/service-ha.md)
  * Master 高可用
  * 资源隔离
    * 利用 kata-container 隔离容器资源
    * 利用 gVisor 隔离容器资源
    * 利用 lvm 和 xfs 实现容器磁盘隔离
    * 利用 lxcfs 隔离 proc 提升容器资源可见性
  * 资源共享
    * 共享存储
    * 共享内存
  * 性能优化
    * 内核参数优化
    * 调度器优化
    * Pod 快速原地重启
    * ETCD 性能优化
  * 集群升级
  * 固定 IP
  * 备份与恢复
  * [泛域名动态转发 Service](/solution/wildcard-domain-forward.md)

* 排错指南
  * [问题排查](/troubleshooting/problems/README.md)
    * [Pod 排错](/troubleshooting/problems/pod/README.md)
      * [Pod 一直处于 Pending 状态](/troubleshooting/problems/pod/keep-pending.md)
      * [Pod 一直处于 ContainerCreating 或 Waiting 状态](/troubleshooting/problems/pod/keep-containercreating-or-waiting.md)
      * [Pod 一直处于 CrashLoopBackOff 状态](/troubleshooting/problems/pod/keep-crashloopbackoff.md)
      * [Pod 一直处于 Terminating 状态](/troubleshooting/problems/pod/keep-terminating.md)
      * [Pod 一直处于 Unknown 状态](/troubleshooting/problems/pod/keep-unkown.md)
      * [Pod 一直处于 Error 状态](/troubleshooting/problems/pod/keep-error.md)
      * [Pod 一直处于 ImagePullBackOff 状态](/troubleshooting/problems/pod/keep-imagepullbackoff.md)
      * [Pod 一直处于 ImageInspectError 状态](/troubleshooting/problems/pod/keep-imageinspecterror.md)
      * [Pod Terminating 慢](/troubleshooting/problems/pod/slow-terminating.md)
      * [Pod 健康检查失败](/troubleshooting/problems/pod/healthcheck-failed.md)
      * [容器进程主动退出](/troubleshooting/problems/pod/container-proccess-exit-by-itself.md)
    * 网络排错
      * [LB 健康检查失败](/troubleshooting/problems/network/lb-healthcheck-failed.md)
      * [DNS 解析异常](/troubleshooting/problems/network/dns.md)
      * [Service 不通](/troubleshooting/problems/network/service-unrecheable.md)
      * [Service 无法解析](/troubleshooting/problems/network/service-cannot-resolve.md)
      * [网络性能差](/troubleshooting/problems/network/low-throughput.md)
    * 集群排错
      * [Node 全部消失](/troubleshooting/problems/cluster/node-all-gone.md)
      * [Daemonset 没有被调度](/troubleshooting/problems/cluster/daemonset-not-scheduled.md)
      * Apiserver 响应慢
      * ETCD 频繁选主
      * Node 异常
    * 其它排错
      * [Job 无法被删除](/troubleshooting/problems/others/job-cannot-delete.md)
      * [kubectl 执行 exec 或 logs 失败](/troubleshooting/problems/others/kubectl-exec-or-logs-failed.md)
  * 经典报错
    * [no space left on device](/troubleshooting/errors/no-space-left-on-device.md)
    * [arp_cache: neighbor table overflow!](/troubleshooting/errors/arp_cache-neighbor-table-overflow.md)
    * [Cannot allocate memory](/troubleshooting/errors/cannot-allocate-memory.md)
  * 处理实践
    * [高负载](/troubleshooting/handle/high-load.md)
    * [内存碎片化](/troubleshooting/handle/memory-fragmentation.md)
    * [磁盘爆满](/troubleshooting/handle/disk-full.md)
    * [inotify watch 耗尽](/troubleshooting/handle/runnig-out-of-inotify-watches.md)
    * [PID 耗尽](/troubleshooting/handle/pid-full.md)
    * [arp_cache 溢出](/troubleshooting/handle/arp_cache-overflow.md)
  * 避坑宝典
    * 踩坑总结
      * [cgroup 泄露](/troubleshooting/damn/summary/cgroup-leaking.md)
      * [tcp\_tw\_recycle 引发丢包](/troubleshooting/damn/summary/tcp_tw_recycle-causes-packet-loss.md)
      * [使用 oom-guard 在用户态处理 cgroup OOM](/troubleshooting/damn/summary/handle-cgroup-oom-in-userspace-with-oom-guard.md)
      * conntrack 冲突导致丢包
    * 案例分享
      * [驱逐导致服务中断](/troubleshooting/damn/cases/eviction-leads-to-service-disruption.md)
      * [DNS 5 秒延时](/troubleshooting/damn/cases/dns-lookup-5s-delay.md)
      * [arp_cache 溢出导致健康检查失败](/troubleshooting/damn/cases/arp-cache-overflow-causes-healthcheck-failed.md)
      * LB 压测 NodePort CPS 低
  * 排错技巧
    * [分析 ExitCode 定位 Pod 异常退出原因](/troubleshooting/trick/analysis-exitcode.md)
    * [容器内抓包定位网络问题](/troubleshooting/trick/capture-packets-in-container.md)
    * [使用 Systemtap 定位疑难杂症](/troubleshooting/trick/use-systemtap-to-locate-problems.md)
    * 使用 kubectl-debug 帮助定位问题
    * 分析 Docker 磁盘占用

* 集群管理
  * 集群监控
    * Prometheus
    * Grafana
  * 日志搜集
    * EFK
  * 集群安全
    * 使用 PodSecurityPolicy 配置全局 Pod 安全策略
    * 集群审计
  * 集群可视化管理
    * Kubernetes Dashboard
    * KubSphere
    * Weave Scope
    * Rancher
    * Kui
    * Kubebox
  * 集群证书管理
    * [安装 cert\-manager](/manage/cert/install-cert-manger.md)
    * [使用 cert\-manager 自动生成证书](/manage/cert/autogenerate-certificate-with-cert-manager.md)
  * 集群配置管理
    * Helm
      * [安装 Helm](/manage/configuration/helm/install-helm.md)
      * [Helm V2 迁移到 V3](/manage/configuration/helm/upgrade-helm-v2-to-v3.md)
      * 使用 Helm 部署与管理应用
      * 开发 Helm Charts
    * Kustomize
      * Kustomize 基础入门
    * 集群镜像管理
      * Harbor
      * Dragonfly
      * Kaniko
      * kpack

* 基础设施
  * ETCD
  * Zookeeper
  * Kafka
  * Redis
  * TiKV
  * ElasticSearch
    * [使用 elastic-oparator 部署 Elasticsearch 和 Kibana](/infra/elasticsearch/install-elasticsearch-and-kibana-with-elastic-oparator.md)
  * MySQL
  * TiDB
  * PostgreSQL
  * MongoDB
  * Cassandra
  * InfluxDB
  * OpenTSDB

* 领域应用
  * 微服务架构
    * 服务发现
    * 服务治理
    * 分布式追踪
      * Jaeger
  * Service Mesh
    * Istio
    * Maesh
    * Kuma
  * Serverless
    * Knative
    * Kubeless
    * Fission
  * DevOps
    * Jenkins X
    * Tekton
    * Argo
    * GoCD
    * Argo
    * GitLab CI
    * Knative Build
    * Drone
  * 人工智能
    * nvidia-docker
    * Kubeflow
  * 大数据
    * Spark

* 开发指南
  * 开发环境搭建
  * [Go 语言编译原理与优化](/dev/golang-build.md)
  * Operator
    * Operator 概述
    * operator-sdk
    * kubebuilder
  * client-go
  * 社区贡献

## 在线阅读

本书将支持中英文两个语言版本，通常文章会先用中文起草并更新，等待其内容较为成熟完善，更新不再频繁的时候才会翻译成英文，点击左上角切换语言。

* 中文: https://k8s.imroc.io
* English: https://k8s.imroc.io/v/en

## 项目源码

项目源码存放于 Github 上: [https://github.com/imroc/kubernetes-practice-guide](https://github.com/imroc/kubernetes-practice-guide)

## 贡献

欢迎参与贡献和完善内容，贡献方法参考 [CONTRIBUTING](https://github.com/imroc/kubernetes-practice-guide/blob/master/CONTRIBUTING.md)

## License

![](https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png)

[署名-非商业性使用-相同方式共享 4.0 \(CC BY-NC-SA 4.0\)](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.zh)
