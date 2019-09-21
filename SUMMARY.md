# Table of contents

* [序言](README.md)

## 部署指南 <a id="deploy"></a>

## 插件扩展 <a id="plugin"></a>

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
  * [频繁 cgroup OOM 导致内核 crash](troubleshooting/damn/cgroup-oom-cause-kernel-crash.md)
* [排错技巧](troubleshooting/trick/README.md)
  * [分析 ExitCode 定位 Pod 异常退出原因](troubleshooting/trick/analysis-exitcode.md)
  * [容器内抓包定位网络问题](troubleshooting/trick/capture-packets-in-container.md)
  * [使用 Systemtap 定位疑难杂症](troubleshooting/trick/use-systemtap-to-locate-problems.md)

## 最佳实践 <a id="best-practice"></a>

* [服务高可用](best-practice/ha/README.md)
  * [服务更新不中断](best-practice/ha/smooth-update.md)
  * [解决长连接服务扩容失效](best-practice/ha/scale-keepalive-service.md)
* [集群安全](best-practice/security/README.md)
  * [集群权限控制](best-practice/security/permission-control.md)
* [证书管理](best-practice/cert-manager/README.md)
  * [安装 cert-manager](best-practice/cert-manager/install-cert-manger.md)
  * [使用 cert-manager 自动生成证书](best-practice/cert-manager/autogenerate-certificate-with-cert-manager.md)
* [配置管理](best-practice/configuration-management/README.md)
  * [Helm](best-practice/configuration-management/helm/README.md)
    * [安装 Helm](best-practice/configuration-management/helm/install-helm.md)
    * [Helm V2 迁移到 V3](best-practice/configuration-management/helm/upgrade-helm-v2-to-v3.md)
* [泛域名转发](best-practice/wildcard-domain-forward.md)
* [kubectl 实用技巧](best-practice/kubectl-trick.md)
* [基础设施容器化](best-practice/infra-containerization/README.md)
  * [ElasticSearch](best-practice/infra-containerization/elasticsearch/README.md)
    * [使用 elastic-oparator 部署 Elasticsearch 和 Kibana](best-practice/infra-containerization/elasticsearch/install-elasticsearch-and-kibana-with-elastic-oparator.md)

## 开发指南 <a id="dev"></a>

## 领域应用 <a id="domain"></a>
