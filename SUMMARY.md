# Table of contents

* [序言](README.md)

## 部署指南 <a id="deploy"></a>

* [手工部署](/deploy/manual/README.md)
  * [部署前的准备工作](/deploy/manual/prepare.md)
  * [部署 ETCD](/deploy/manual/bootstraping-etcd.md)
  * [部署 Master](/deploy/manual/bootstraping-master.md)
  * [部署 Worker 节点](/deploy/manual/bootstraping-worker-nodes.md)
  * [部署关键附加组件](/deploy/manual/deploy-critical-addons.md)

## 插件扩展 <a id="plugin"></a>

## 用法指南 <a id="usage">

* [集群权限控制](/usage/permission/README.md)
  * [控制用户权限](/usage/permission/user.md)
  * [控制应用权限](/usage/permission/app.md)
* [实用 yaml 片段](/usage/yaml.md)

## 最佳实践 <a id="best-practice"></a>

* [高可用](/best-practice/ha/README.md)
  * [服务平滑更新不中断](/best-practice/ha/smooth-update.md)
  * [解决长连接服务扩容失效](/best-practice/ha/scale-keepalive-service.md)
* [服务转发](/best-practice/forward/README.md)
  * [泛域名转发](/best-practice/forward/wildcard-domain-forward.md)
* [提高生产力](/best-practice/productive/README.md)
  * [kubectl 高效技巧](/best-practice/productive/efficient-kubectl.md)

## 排错指南 <a id="troubleshooting"></a>

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
  * [网络排错](/troubleshooting/problems/network/README.md)
    * [LB 健康检查失败](/troubleshooting/problems/network/lb-healthcheck-failed.md)
    * [DNS 解析异常](/troubleshooting/problems/network/dns.md)
    * [Service 不通](/troubleshooting/problems/network/service-unrecheable.md)
    * [Service 无法解析](/troubleshooting/problems/network/service-cannot-resolve.md)
    * [网络性能差](/troubleshooting/problems/network/low-throughput.md)
  * [集群排错](/troubleshooting/problems/cluster/README.md)
    * [Node 全部消失](/troubleshooting/problems/cluster/node-all-gone.md)
    * [Daemonset 没有被调度](/troubleshooting/problems/cluster/daemonset-not-scheduled.md)
  * [其它排错](/troubleshooting/problems/others/README.md)
    * [Job 无法被删除](/troubleshooting/problems/others/job-cannot-delete.md)
    * [kubectl 执行 exec 或 logs 失败](/troubleshooting/problems/others/kubectl-exec-or-logs-failed.md)
* [经典报错](/troubleshooting/errors/README.md)
  * [no space left on device](/troubleshooting/errors/no-space-left-on-device.md)
  * [arp_cache: neighbor table overflow!](/troubleshooting/errors/arp_cache-neighbor-table-overflow.md)
  * [Cannot allocate memory](/troubleshooting/errors/cannot-allocate-memory.md)
* [处理实践](/troubleshooting/handle/README.md)
  * [高负载](/troubleshooting/handle/high-load.md)
  * [内存碎片化](/troubleshooting/handle/memory-fragmentation.md)
  * [磁盘爆满](/troubleshooting/handle/disk-full.md)
  * [inotify watch 耗尽](/troubleshooting/handle/runnig-out-of-inotify-watches.md)
  * [PID 耗尽](/troubleshooting/handle/pid-full.md)
  * [arp_cache 溢出](/troubleshooting/handle/arp_cache-overflow.md)
* [避坑宝典](/troubleshooting/damn/README.md)
  * [踩坑总结](/troubleshooting/damn/summary/README.md)
    * [cgroup 泄露](/troubleshooting/damn/summary/cgroup-leaking.md)
    * [tcp\_tw\_recycle 引发丢包](/troubleshooting/damn/summary/tcp_tw_recycle-causes-packet-loss.md)
    * [使用 oom-guard 在用户态处理 cgroup OOM](/troubleshooting/damn/summary/handle-cgroup-oom-in-userspace-with-oom-guard.md)
  * [案例分享](/troubleshooting/damn/cases/README.md)
    * [驱逐导致服务中断](/troubleshooting/damn/cases/eviction-leads-to-service-disruption.md)
    * [DNS 5 秒延时](/troubleshooting/damn/cases/dns-lookup-5s-delay.md)
    * [arp_cache 溢出导致健康检查失败](/troubleshooting/damn/cases/arp-cache-overflow-causes-healthcheck-failed.md)
* [排错技巧](/troubleshooting/trick/README.md)
  * [分析 ExitCode 定位 Pod 异常退出原因](/troubleshooting/trick/analysis-exitcode.md)
  * [容器内抓包定位网络问题](/troubleshooting/trick/capture-packets-in-container.md)
  * [使用 Systemtap 定位疑难杂症](/troubleshooting/trick/use-systemtap-to-locate-problems.md)

## 运维管理 <a id="manage"></a>

* [证书管理](/manage/cert/README.md)
  * [安装 cert\-manager](/manage/cert/install-cert-manger.md)
  * [使用 cert\-manager 自动生成证书](/manage/cert/autogenerate-certificate-with-cert-manager.md)
* [集群配置管理](/manage/configuration/README.md)
  * [Helm](/manage/configuration/helm/README.md)
    * [安装 Helm](/manage/configuration/helm/install-helm.md)
    * [Helm V2 迁移到 V3](/manage/configuration/helm/upgrade-helm-v2-to-v3.md)

## 基础设施容器化部署 <a id="infra"></a>

* [ElasticSearch](/infra/elasticsearch/README.md)
  * [使用 elastic-oparator 部署 Elasticsearch 和 Kibana](/infra/elasticsearch/install-elasticsearch-and-kibana-with-elastic-oparator.md)

## 领域应用 <a id="domain"></a>

## 开发指南 <a id="dev"></a>

* [Go 语言编译原理与优化](/dev/golang-build.md)
