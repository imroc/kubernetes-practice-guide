# Table of contents

* [序言](README.md)

## 部署指南 <a id="deploy"></a>

## 插件扩展 <a id="plugin"></a>

## 最佳实践 <a id="best-practice"></a>

* [高可用](best-practice/ha/README.md)
  * [服务更新不中断](best-practice/ha/smooth-update.md)
  * [解决长连接服务扩容失效](best-practice/ha/scale-keepalive-service.md)
* [服务转发](best-practice/forward/README.md)
  * [泛域名转发](best-practice/forward/wildcard-domain-forward.md)
* [提高生产力](best-practice/productive/README.md)
  * [kubectl 高效技巧](best-practice/productive/efficient-kubectl.md)

## 排错指南 <a id="troubleshooting"></a>

* [问题排查](troubleshooting/problems/README.md)
  * [Pod 排错](troubleshooting/problems/pod/README.md)
    * [Pod 一直处于 ContainerCreating 或 Waiting 状态](troubleshooting/problems/pod/keep-containercreating-or-waiting.md)
    * [Pod 一直处于 Pending 状态](troubleshooting/problems/pod/keep-pending.md)
    * [Pod 一直处于 Terminating 状态](troubleshooting/problems/pod/keep-terminating.md)
    * [Pod Terminating 慢](troubleshooting/problems/pod/slow-terminating.md)
    * [Pod 一直处于 Unknown 状态](troubleshooting/problems/pod/keep-unkown.md)
    * [Pod 一直处于 Error 状态](troubleshooting/problems/pod/keep-error.md)
    * [Pod 一直处于 CrashLoopBackOff 状态](troubleshooting/problems/pod/keep-crashloopbackoff.md)
    * [Pod 一直处于 ImagePullBackOff 状态](troubleshooting/problems/pod/keep-imagepullbackoff.md)
    * [Pod 一直处于 ImageInspectError 状态](troubleshooting/problems/pod/keep-imageinspecterror.md)
    * [Pod 健康检查失败](troubleshooting/problems/pod/healthcheck-failed.md)
    * [Pod 无法被 exec 或查 logs](troubleshooting/problems/pod/cannot-exec-or-logs.md)
  * [网络排错](troubleshooting/problems/network/README.md)
    * [LB 健康检查失败](troubleshooting/problems/network/lb-healthcheck-failed.md)
    * [DNS 解析异常](troubleshooting/problems/network/dns.md)
    * [Service 不通](troubleshooting/problems/network/service-unrecheable.md)
    * [Service 无法解析](troubleshooting/problems/network/service-cannot-resolve.md)
  * [集群排错](troubleshooting/problems/cluster/README.md)
    * [Node 全部消失](troubleshooting/problems/cluster/node-all-gone.md)
    * [Daemonset 没有被调度](troubleshooting/problems/cluster/daemonset-not-scheduled.md)
  * [其它排错](troubleshooting/problems/others/README.md)
    * [Job 无法被删除](troubleshooting/problems/others/job-cannot-delete.md)
* [处理实践](troubleshooting/handling-practice/README.md)
  * [高负载](troubleshooting/handling-practice/high-load.md)
  * [内存碎片化](troubleshooting/handling-practice/memory-fragmentation.md)
  * [磁盘空间满](troubleshooting/handling-practice/disk-full.md)
  * [inotify watch 耗尽](troubleshooting/handling-practice/runnig-out-of-inotify-watches.md)
* [踩坑分享](troubleshooting/damn/README.md)
  * [cgroup 泄露](troubleshooting/damn/cgroup-leaking.md)
  * [tcp\_tw\_recycle 引发丢包](troubleshooting/damn/tcp_tw_recycle-causes-packet-loss.md)
  * [驱逐导致服务中断](troubleshooting/damn/eviction-leads-to-service-disruption.md)
  * [频繁 cgroup OOM 导致内核 crash](troubleshooting/damn/cgroup-oom-cause-kernel-crash.md)
* [排错技巧](troubleshooting/trick/README.md)
  * [分析 ExitCode 定位 Pod 异常退出原因](troubleshooting/trick/analysis-exitcode.md)
  * [容器内抓包定位网络问题](troubleshooting/trick/capture-packets-in-container.md)
  * [使用 Systemtap 定位疑难杂症](troubleshooting/trick/use-systemtap-to-locate-problems.md)

## 集群管理 <a id="manage"></a>

* [集群安全管理](manage/security/README.md)
  * [集群权限控制](manage/security/permission-control.md)
* [集群证书管理](manage/cert/README.md)
  * [安装 cert-manager](manage/cert/install-cert-manger.md)
  * [使用 cert-manager 自动生成证书](manage/cert/autogenerate-certificate-with-cert-manager.md)
* [集群配置管理](manage/configuration/README.md)
  * [Helm](manage/configuration/helm/README.md)
    * [安装 Helm](manage/configuration/helm/install-helm.md)
    * [Helm V2 迁移到 V3](manage/configuration/helm/upgrade-helm-v2-to-v3.md)

## 基础设施容器化部署 <a id="infra"></a>

* [ElasticSearch](infra/elasticsearch/README.md)
  * [使用 elastic-oparator 部署 Elasticsearch 和 Kibana](infra/elasticsearch/install-elasticsearch-and-kibana-with-elastic-oparator.md)

## 领域应用 <a id="domain"></a>

## 开发指南 <a id="dev"></a>
