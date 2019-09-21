# Table of contents

* [序言](README.md)

## 部署指南 <a id="deploy"></a>

* [部署方案选型](deploy/bu-shu-fang-an-xuan-xing.md)
* [单机部署](deploy/dan-ji-bu-shu.md)
* [二进制部署](deploy/er-jin-zhi-bu-shu.md)
* [工具部署](deploy/gong-ju-bu-shu/README.md)
  * [Kubeadm](deploy/gong-ju-bu-shu/kubeadm.md)
  * [Minikube](deploy/gong-ju-bu-shu/minikube.md)
  * [Bootkube](deploy/gong-ju-bu-shu/bootkube.md)
  * [Ansible](deploy/gong-ju-bu-shu/ansible.md)

## 插件扩展 <a id="plugin"></a>

* [网络](plugin/wang-luo.md)
* [运行时](plugin/yun-hang-shi.md)
* [存储](plugin/cun-chu.md)
* [Ingress Controller](plugin/ingress-controller.md)
* [Scheduler Plugin](plugin/scheduler-plugin.md)
* [Device Plugin](plugin/device-plugin.md)
* [Cloud Provider](plugin/cloud-provider.md)
* [Network Policy](plugin/network-policy.md)

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
  * [conntrack 冲突导致丢包](troubleshooting/damn/conntrack-conflict.md)
* [排错技巧](troubleshooting/trick/README.md)
  * [分析 ExitCode 定位 Pod 异常退出原因](troubleshooting/trick/analysis-exitcode.md)
  * [容器内抓包定位网络问题](troubleshooting/trick/capture-packets-in-container.md)
  * [使用 Systemtap 定位疑难杂症](troubleshooting/trick/use-systemtap-to-locate-problems.md)

## 最佳实践 <a id="best-practice"></a>

* [服务高可用](best-practice/ha/README.md)
  * [使用反亲和性避免单点故障](best-practice/ha/shi-yong-fan-qin-he-xing-bi-mian-dan-dian-gu-zhang.md)
  * [服务更新不中断](best-practice/ha/smooth-update.md)
  * [节点下线不停服](best-practice/ha/jie-dian-xia-xian-bu-ting-fu.md)
* [动态伸缩](best-practice/autoscale/README.md)
  * [使用 HPA 对 Pod 水平伸缩](best-practice/autoscale/shi-yong-hpa-dui-pod-shui-ping-shen-suo.md)
  * [使用 VPA 对 Pod 垂直伸缩](best-practice/autoscale/shi-yong-vpa-dui-pod-chui-zhi-shen-suo.md)
  * [使用 Cluster Autoscaler 对节点水平伸缩](best-practice/autoscale/shi-yong-cluster-autoscaler-dui-jie-dian-shui-ping-shen-suo.md)
* [资源限制](best-practice/resource-limit/README.md)
  * [资源预留](best-practice/resource-limit/zi-yuan-yu-liu.md)
  * [Request 与 Limit](best-practice/resource-limit/request-yu-limit.md)
  * [Resource Quotas](best-practice/resource-limit/resource-quotas.md)
  * [Limit Ranges](best-practice/resource-limit/limit-ranges.md)
* [资源隔离](best-practice/resource-isolation/README.md)
  * [利用 kata-container 隔离容器资源](best-practice/resource-isolation/li-yong-katacontainer-ge-li-rong-qi-zi-yuan.md)
  * [利用 gVisor 隔离容器资源](best-practice/resource-isolation/li-yong-gvisor-ge-li-rong-qi-zi-yuan.md)
  * [利用 lvm 和 xfs 实现容器磁盘隔离](best-practice/resource-isolation/li-yong-lvm-he-xfs-shi-xian-rong-qi-ci-pan-ge-li.md)
  * [利用 lxcfs 隔离 proc 提升容器资源可见性](best-practice/resource-isolation/li-yong-lxcfs-ge-li-proc-ti-sheng-rong-qi-zi-yuan-ke-jian-xing.md)
* [集群安全](best-practice/security/README.md)
  * [集群权限控制](best-practice/security/permission-control.md)
  * [PodSecurityPolicy](best-practice/security/podsecuritypolicy.md)
  * [集群审计](best-practice/security/ji-qun-shen-ji.md)
* [GPU](best-practice/gpu.md)
* [大页内存](best-practice/da-ye-nei-cun.md)
* [证书管理](best-practice/cert-manager/README.md)
  * [安装 cert-manager](best-practice/cert-manager/install-cert-manger.md)
  * [使用 cert-manager 自动生成证书](best-practice/cert-manager/autogenerate-certificate-with-cert-manager.md)
* [配置管理](best-practice/configuration-management/README.md)
  * [Helm](best-practice/configuration-management/helm/README.md)
    * [安装 Helm](best-practice/configuration-management/helm/install-helm.md)
    * [Helm V2 迁移到 V3](best-practice/configuration-management/helm/upgrade-helm-v2-to-v3.md)
    * [使用 Helm 部署与管理应用](best-practice/configuration-management/helm/shi-yong-helm-bu-shu-yu-guan-li-ying-yong.md)
    * [开发 Helm Charts](best-practice/configuration-management/helm/kai-fa-helm-charts.md)
  * [Kustomize](best-practice/configuration-management/kustomize/README.md)
    * [Kustomize 基础入门](best-practice/configuration-management/kustomize/kustomize-ji-chu-ru-men.md)
* [备份恢复](best-practice/bei-fen-hui-fu.md)
* [大规模集群](best-practice/da-gui-mo-ji-qun.md)
* [集群迁移](best-practice/ji-qun-qian-yi.md)
* [多集群](best-practice/duo-ji-qun.md)
* [泛域名转发](best-practice/wildcard-domain-forward.md)
* [kubectl 实用技巧](best-practice/kubectl-trick.md)

## 开发指南 <a id="dev"></a>

* [开发环境搭建](dev/kai-fa-huan-jing-da-jian.md)
* [Operator](dev/operator.md)
* [client-go](dev/client-go.md)
* [社区贡献](dev/she-qu-gong-xian.md)

## 领域应用 <a id="domain"></a>

* [微服务架构](domain/microservices.md)
* [Service Mesh](domain/servicemesh.md)
* [Serverless](domain/serverless.md)
* [DevOps](domain/devops.md)
* [人工智能](domain/ai.md)
* [大数据](domain/bigdata.md)

