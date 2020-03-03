---
title: "Kubernetes Practice Guide"
---

## Roadmap

本书正在起草初期，内容将包含大量 Kubernetes 实践干货，大量规划内容还正在路上，可以点击的表示是已经可以在左侧导航栏中找到的并预览的文章，但不代表已经完善，还会不断的补充和优化。

### 部署指南

自建的 k8s 集群有很多种方式部署方式，k8s 知识库将列举手工二进制部署与各种辅助工具部署的方法，可以根据自己使用场景选择对应合适的部署方法。除此之外，还会包含大量的常用应用的部署方法，比如各种数据库和存储基础设施部署，不同的业务场景和解决方案都可能依赖这些应用，每种应用部署方法都可能被书内其它多处地方引用。

* 部署方案选型
* 单机部署
* [手工部署](/deploy/manual/)
  * [部署前的准备工作](/deploy/manual/prepare/)
  * [部署 ETCD](/deploy/manual/bootstrapping-etcd/)
  * [部署 Master](/deploy/manual/bootstrapping-master/)
  * [部署 Worker 节点](/deploy/manual/bootstrapping-worker-nodes/)
  * [部署关键附加组件](/deploy/manual/deploy-critical-addons/)
* 使用 Kubeadm 部署集群
* 使用 Minikube 部署测试集群
* 使用 Bootkube 部署集群
* 使用 Ansible 部署集群
* [部署附加组件](/deploy/addons/)
  * [部署 CoreDNS](/deploy/addons/coredns/)
  * [以 Daemonset 方式部署 kube-proxy](/deploy/addons/kube-proxy/)
* 常见应用部署
  * ElasticSearch 与 Kibana
    * [使用 elastic-oparator 部署](/deploy/common/elasticsearch/install-elasticsearch-and-kibana-with-elastic-oparator/)
  * ETCD
  * Zookeeper
  * Consul
  * Kafka
  * Redis
  * TiKV
  * MySQL
  * TiDB
  * PostgreSQL
  * MongoDB
  * Cassandra
  * InfluxDB
  * OpenTSDB

### 集群方案

k8s 拥有惊人的扩展能力，针对不同环境和场景可以使用不同的方案，涵盖网络、存储、运行时、Ingress、Metrics 等。k8s 知识库会帮助你彻底理清这些机制，并深入剖析各种方案的原理、用法与使用场景。

* [网络方案](/cluster/network/)
  * 彻底理解集群网络
  * Network Policy
  * 开源网络方案
  * [Flannel](/cluster/network/flannel/)
    * Flannel 网络原理
    * [部署 Flannel](/cluster/network/flannel/deploy/)
  * Macvlan
  * Calico
  * Cilium
  * Kube-router
  * Kube-OVN
  * OpenVSwitch
* [运行时方案](/cluster/runtime/)
  * Docker
    * Docker 介绍
    * Docker 安装
  * [Containerd](/cluster/runtime/containerd/)
    * containerd 介绍
    * [安装 containerd](/cluster/runtime/containerd/install-containerd/)
  * CRI-O
    * CRI-O 介绍
    * CRI-O 安装
* 存储方案
  * Rook
  * OpenEBS
* Ingress 方案
  * Nginx Ingress
    * [安装 nginx ingress controller](/cluster/ingress/nginx/install-nginx-ingress/)
  * Traefik Ingress
    * [安装 traefik ingress controller](/cluster/ingress/traefik/install-traefik-ingress/)
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
* Metrics 方案
  * [安装 metrics server](/cluster/metrics/install-metrics-server/)

### 最佳实践

k8s 有先进的设计理念，也包含了大量概念，并提供了非常丰富的能力，用法琳琅满目，但入门比较困难，k8s 知识库将提供使用 k8s 的各种场景里的最佳实践，帮助大家少走弯路，比如如何管理和运维集群、如何进行动态伸缩、如何保证部署的服务高可用、如何在更新服务或扩缩容节点保证业务零感知、如何部署有状态服务、如何针对大规模集群进行优化、如何对资源进行隔离和共享以及针对各种需求和问题的解决方案等。

* [应用部署最佳实践](/best-practice/deploy/)
* [本地 DNS 缓存](/best-practice/node-local-dns/)
* [泛域名动态转发 Service](/best-practice/wildcard-domain-forward/)
* [集群权限控制](/best-practice/permission/)
  * [利用 CSR API 创建用户](/best-practice/permission/create-user-using-csr-api/)
  * [控制用户权限](/best-practice/permission/user/)
  * [控制应用权限](/best-practice/permission/app/)
* 有状态服务部署
* [实用工具和技巧](/best-practice/useful/)
  * [kubectl 高效技巧](/best-practice/useful/efficient-kubectl/)
  * [实用 yaml 片段](/best-practice/useful/yaml/)
  * [实用命令与脚本](/best-practice/useful/shell/)
* 集群证书管理
  * [安装 cert\-manager](/best-practice/cert-management/install-cert-manger/)
  * [使用 cert\-manager 自动生成证书](/best-practice/cert-management/autogenerate-certificate-with-cert-manager/)
* 集群配置管理
  * Helm
    * [安装 Helm](/best-practice/configuration-management/helm/install-helm/)
    * [Helm V2 迁移到 V3](/best-practice/configuration-management/helm/upgrade-helm-v2-to-v3/)
    * 使用 Helm 部署与管理应用
    * 开发 Helm Charts
  * Kustomize
    * Kustomize 基础入门
* [大规模集群优化](/best-practice/big-cluster/)
* 弹性伸缩
  * 使用 HPA 对 Pod 水平伸缩
  * 使用 VPA 对 Pod 垂直伸缩
  * 使用 Cluster Autoscaler 对节点水平伸缩
* 资源分配与限制
* Master 高可用
* 资源隔离与共享
  * 利用 kata-container 隔离容器资源
  * 利用 gVisor 隔离容器资源
  * 利用 lvm 和 xfs 实现容器磁盘隔离
  * 利用 lxcfs 隔离 proc 提升容器资源可见性
  * 共享存储
  * 共享内存
* Pod 原地重启
* 集群升级
* 固定 IP
* 备份与恢复
* ETCD 性能优化
* 内核参数优化
* CPU 亲和性
* 使用大页内存
* 离在线混合部署
* 集群监控
  * Prometheus
  * Grafana
* 日志搜集
  * EFK/ELK
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
* 集群镜像管理
  * Harbor
  * Dragonfly
  * Kaniko
  * kpack

### 排错指南

正是 k8s 功能如此丰富强大，迭代速度如此之快，其复杂性和不确定性也非常之大。知识库会总结出各种问题的排查思路与可能原因，还有对应解决方案的最佳实践，也分享一些踩坑案例与排错技巧，与排错技巧，让大家少走弯路。

* [问题排查](/troubleshooting/problems/)
  * [Pod 排错](/troubleshooting/problems/pod/)
    * [Pod 一直处于 Pending 状态](/troubleshooting/problems/pod/keep-pending/)
    * [Pod 一直处于 ContainerCreating 或 Waiting 状态](/troubleshooting/problems/pod/keep-containercreating-or-waiting/)
    * [Pod 一直处于 CrashLoopBackOff 状态](/troubleshooting/problems/pod/keep-crashloopbackoff/)
    * [Pod 一直处于 Terminating 状态](/troubleshooting/problems/pod/keep-terminating/)
    * [Pod 一直处于 Unknown 状态](/troubleshooting/problems/pod/keep-unkown/)
    * [Pod 一直处于 Error 状态](/troubleshooting/problems/pod/keep-error/)
    * [Pod 一直处于 ImagePullBackOff 状态](/troubleshooting/problems/pod/keep-imagepullbackoff/)
    * [Pod 一直处于 ImageInspectError 状态](/troubleshooting/problems/pod/keep-imageinspecterror/)
    * [Pod 健康检查失败](/troubleshooting/problems/pod/healthcheck-failed/)
    * [容器进程主动退出](/troubleshooting/problems/pod/container-proccess-exit-by-itself/)
  * 网络排错
    * [LB 健康检查失败](/troubleshooting/problems/network/lb-healthcheck-failed/)
    * [DNS 解析异常](/troubleshooting/problems/network/dns/)
    * [Service 不通](/troubleshooting/problems/network/service-unrecheable/)
    * [网络性能差](/troubleshooting/problems/network/low-throughput/)
  * 集群排错
    * [Node 全部消失](/troubleshooting/problems/cluster/node-all-gone/)
    * [Daemonset 没有被调度](/troubleshooting/problems/cluster/daemonset-not-scheduled/)
    * Apiserver 响应慢
    * ETCD 频繁选主
    * Node 异常
  * 经典报错
    * [no space left on device](/troubleshooting/problems/errors/no-space-left-on-device/)
    * [arp_cache: neighbor table overflow!](/troubleshooting/problems/errors/arp_cache-neighbor-table-overflow/)
    * [Cannot allocate memory](/troubleshooting/problems/errors/cannot-allocate-memory/)
  * 其它排错
    * [Job 无法被删除](/troubleshooting/problems/others/job-cannot-delete/)
    * [kubectl 执行 exec 或 logs 失败](/troubleshooting/problems/others/kubectl-exec-or-logs-failed/)
    * [内核软死锁](/troubleshooting/problems/others/kernel-solft-lockup/)
* 处理实践
  * [高负载](/troubleshooting/handle/high-load/)
  * [内存碎片化](/troubleshooting/handle/memory-fragmentation/)
  * [磁盘爆满](/troubleshooting/handle/disk-full/)
  * [inotify watch 耗尽](/troubleshooting/handle/runnig-out-of-inotify-watches/)
  * [PID 耗尽](/troubleshooting/handle/pid-full/)
  * [arp_cache 溢出](/troubleshooting/handle/arp_cache-overflow/)
* 踩坑总结
  * [cgroup 泄露](/troubleshooting/summary/cgroup-leaking/)
  * [tcp\_tw\_recycle 引发丢包](/troubleshooting/summary/tcp_tw_recycle-causes-packet-loss/)
  * [使用 oom-guard 在用户态处理 cgroup OOM](/troubleshooting/summary/handle-cgroup-oom-in-userspace-with-oom-guard/)
  * conntrack 冲突导致丢包
* 案例分享
  * [驱逐导致服务中断](/troubleshooting/cases/eviction-leads-to-service-disruption/)
  * [DNS 5 秒延时](/troubleshooting/cases/dns-lookup-5s-delay/)
  * [arp_cache 溢出导致健康检查失败](/troubleshooting/cases/arp-cache-overflow-causes-healthcheck-failed/)
  * [跨 VPC 访问 NodePort 经常超时](/troubleshooting/cases/cross-vpc-connect-nodeport-timeout/)
  * [访问 externalTrafficPolicy 为 Local 的 Service 对应 LB 有时超时](/troubleshooting/cases/lb-with-local-externaltrafficpolicy-timeout-occasionally/)
  * [Pod 偶尔存活检查失败](/troubleshooting/cases/livenesprobe-failed-occasionally/)
  * [DNS 解析异常](/troubleshooting/cases/dns-resolution-abnormal/)
  * [Pod 访问另一个集群的 apiserver 有延时](/troubleshooting/cases/high-legacy-from-pod-to-another-apiserver/)
  * [LB 压测 NodePort CPS 低](/troubleshooting/cases/low-cps-from-lb-to-nodeport/)
  * [kubectl edit 或者 apply 报 SchemaError](/troubleshooting/cases/schemaerror-when-using-kubectl-apply-or-edit/)
  * [诡异的 No route to host](/troubleshooting/cases/no-route-to-host/)
  * [神秘的溢出与丢包](/troubleshooting/cases/kubernetes-overflow-and-drop/)
* 排错技巧
  * [分析 ExitCode 定位 Pod 异常退出原因](/troubleshooting/trick/analysis-exitcode/)
  * [容器内抓包定位网络问题](/troubleshooting/trick/capture-packets-in-container/)
  * [使用 Systemtap 定位疑难杂症](/troubleshooting/trick/use-systemtap-to-locate-problems/)
  * 使用 kubectl-debug 帮助定位问题
  * 分析 Docker 磁盘占用

### 领域应用

k8s 在各个领域都发挥了巨大作用，我们会将 k8s 在这些领域的应用汇总，给出各种场景化应用的指南，比如近年来如火如荼的 DevOps 领域，其中 CI/CD 的应用更是大家迫切期望想要的。还有 AI，大数据，微服务架构，Service Mesh，Serverless 等。

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
  * Drone
* AI
  * nvidia-docker
  * Kubeflow
* [大数据](/domains/big-data/)
  * [Flink on Kubernetes](/domains/big-data/flink-on-kubernetes/)
  * Hbase on Kubernetes
  * Spark on Kubernetes
  * Hadoop on Kubernetes

### 开发指南

k8s 开放了很多扩展能力，基于这些扩展机制可以开发出各种功能的应用，比如集群管理应用、部署有状态服务的应用（Operator）等，知识库将介绍如何开发这些应用。

* 开发环境搭建
* [Go 语言编译原理与优化](/dev/golang-build/)
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

欢迎参与贡献和完善内容，贡献方法参考 [CONTRIBUTING](https://github.com/imroc/kubernetes-practice-guide/blob/master/CONTRIBUTING/)

## License

![](https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png)

[署名-非商业性使用-相同方式共享 4.0 \(CC BY-NC-SA 4.0\)](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.zh)
