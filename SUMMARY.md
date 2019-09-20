# Table of contents

* [序言](README.md)

## 第一章: 排错指南

* [问题定位技巧](di-yi-zhang-pai-cuo-zhi-nan/debug-skill/README.md)
  * [分析 ExitCode 定位 Pod 异常退出原因](di-yi-zhang-pai-cuo-zhi-nan/debug-skill/analysis-exitcode.md)
  * [容器内抓包定位网络问题](di-yi-zhang-pai-cuo-zhi-nan/debug-skill/capture-packets-in-container.md)
  * [使用 systemtap 定位疑难杂症](di-yi-zhang-pai-cuo-zhi-nan/debug-skill/use-systemtap-to-locate-problems.md)
* [排错指引](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/README.md)
  * [健康检查失败](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/healthcheck-failed.md)
  * [Pod 异常重启](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/pod-restart.md)
  * [Pod 一直 Pending](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/pod-pending-forever.md)
  * [Pod 一直 ContainerCreating](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/pod-containercreating-forever.md)
  * [Pod 一直 Terminating](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/pod-terminating-forever.md)
  * [无法登录容器](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/pod-cannot-exec-or-logs.md)
  * [无法查看容器日志](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/wu-fa-cha-kan-rong-qi-ri-zhi.md)
  * [TODO:Pod Terminating 慢](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/slow-pod-terminating.md)
  * [Job 无法被删除](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/cannot-delete-job.md)
  * [no space left on device](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/no-space-left-on-device.md)
  * [arp\_cache: neighbor table overflow!](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/arp_cache-neighbor-table-overflow.md)
  * [Cannot allocate memory](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/cannot-allocate-memory.md)
  * [TODO:apiserver 响应慢](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/todoapiserver-xiang-ying-man.md)
  * [TODO:ETCD频繁选主](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/todoetcd-pin-fan-xuan-zhu.md)
  * [Service 访问不通](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/service-unreachable.md)
  * [Service 无法解析](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/service-cannot-resolve.md)
  * [LB 健康检查失败](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/lb-healthcheck-failed.md)
  * [DNS 5秒延时](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/dns-lookup-5s-delay.md)
  * [TODO:Pod 无法访问外网](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/todopod-wu-fa-fang-wen-wai-wang.md)
  * [TODO:Pod 无法访问集群外的内网服务](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/todopod-wu-fa-fang-wen-ji-qun-wai-de-nei-wang-fu-wu.md)
  * [TODO:容器内无法 mount](di-yi-zhang-pai-cuo-zhi-nan/pai-cuo-zhi-yin/todo-rong-qi-nei-wu-fa-mount.md)
* [处理实践](di-yi-zhang-pai-cuo-zhi-nan/chu-li-shi-jian/README.md)
  * [节点 NotReady](di-yi-zhang-pai-cuo-zhi-nan/chu-li-shi-jian/node-notready.md)
  * [Rancher 清除 Node 导致集群异常](di-yi-zhang-pai-cuo-zhi-nan/chu-li-shi-jian/rancher-remove-node-cause-cluster-abnormal.md)
  * [内存碎片化](di-yi-zhang-pai-cuo-zhi-nan/chu-li-shi-jian/memory-fragmentation.md)
  * [节点高负载](di-yi-zhang-pai-cuo-zhi-nan/chu-li-shi-jian/high-load-on-node.md)
  * [驱逐导致服务中断](di-yi-zhang-pai-cuo-zhi-nan/chu-li-shi-jian/eviction-leads-to-service-disruption.md)
  * [cgroup 泄露](di-yi-zhang-pai-cuo-zhi-nan/chu-li-shi-jian/cgroup-leaking.md)
  * [inotify watch 耗尽](di-yi-zhang-pai-cuo-zhi-nan/chu-li-shi-jian/runnig-out-of-inotify-watches.md)
  * [tcp\_tw\_recycle 导致在 NAT 环境会丢包](di-yi-zhang-pai-cuo-zhi-nan/chu-li-shi-jian/lost-packets-in-nat-environment-once-enable-tcp_tw_recycle.md)

## 最佳实践

* [集群权限控制](zui-jia-shi-jian/cluster-permission-control.md)
* [优雅热更新](zui-jia-shi-jian/kubernetes-grace-update.md)
* [解决长连接服务扩容失效](zui-jia-shi-jian/scale-keepalive-service.md)
* [使用 oom-guard 在用户态处理 cgroup OOM](zui-jia-shi-jian/handle-cgroup-oom-with-oom-guard-in-userspace.md)
* [泛域名动态 Service 转发解决方案](zui-jia-shi-jian/wildcard-domain-forward.md)
* [kubectl 高效技巧](zui-jia-shi-jian/efficient-kubectl.md)
* [TODO:处理容器磁盘被写满](zui-jia-shi-jian/handle-disk-full.md)
* [TODO:使用 MetalLB 创建负载均衡器](zui-jia-shi-jian/todo-shi-yong-metallb-chuang-jian-fu-zai-jun-heng-qi.md)
* [TODO:Pod 原地升级](zui-jia-shi-jian/todopod-yuan-di-sheng-ji.md)
* [TODO:Pod 固定 IP](zui-jia-shi-jian/todopod-gu-ding-ip.md)
* [TODO:使用 lxcfs 隔离 /proc](zui-jia-shi-jian/todo-shi-yong-lxcfs-ge-li-proc.md)
* [TODO:容器磁盘隔离](zui-jia-shi-jian/todo-rong-qi-ci-pan-ge-li.md)

## K8S 配置管理

* [Helm](k8s-pei-zhi-guan-li/helm/README.md)
  * [安装 Helm](k8s-pei-zhi-guan-li/helm/install-helm.md)
  * [Helm V2 迁移到 V3](k8s-pei-zhi-guan-li/helm/upgrade-helm-v2-to-v3.md)
* [TODO:Kustomize](k8s-pei-zhi-guan-li/todo-kustomize.md)

## 安全

* [cert-manager](an-quan/cert-manager/README.md)
  * [安装 cert-manager](an-quan/cert-manager/install-cert-manger.md)
  * [使用 cert-manager 自动生成证书](an-quan/cert-manager/autogenerate-certificate-with-cert-manager.md)

## Kubernetes 部署指南

* [TODO:二进制部署](kubernetes-bu-shu-zhi-nan/todo-er-jin-zhi-bu-shu.md)
* [TODO:使用 Kubeadm 部署](kubernetes-bu-shu-zhi-nan/todo-shi-yong-kubeadm-bu-shu.md)
* [TODO:使用 Minikube 部署](kubernetes-bu-shu-zhi-nan/todo-shi-yong-minikube-bu-shu.md)
* [TODO:使用 Bootkube 部署](kubernetes-bu-shu-zhi-nan/todo-shi-yong-bootkube-bu-shu.md)
* [TODO:使用 Ansible 部署](kubernetes-bu-shu-zhi-nan/todo-shi-yong-ansible-bu-shu.md)

## K8S 管理工具

* [TODO:Rancher](k8s-guan-li-gong-ju/todo-rancher.md)
* [TODO:Weave Scope](k8s-guan-li-gong-ju/todo-weave-scope.md)
* [TODO:Kui](k8s-guan-li-gong-ju/todo-kui.md)
* [TODO:Kubernetes Dashboard](k8s-guan-li-gong-ju/todo-kubernetes-dashboard.md)
* [TODO:Kubetail](k8s-guan-li-gong-ju/todo-kubetail.md)
* [TODO:Kubebox](k8s-guan-li-gong-ju/todo-kubebox.md)

## 运行时

* [TODO:Docker](yun-hang-shi/todo-docker.md)
* [TODO:Containerd](yun-hang-shi/todo-containerd.md)
* [TODO:CRI-O](yun-hang-shi/todo-cri-o.md)

## 服务发现

* [TODO:ETCD](fu-wu-fa-xian/todo-etcd.md)
* [TODO:Zookeeper](fu-wu-fa-xian/todo-zookeeper.md)
* [TODO:Consul](fu-wu-fa-xian/todo-consul.md)

## 存储

* [ElasticSearch](cun-chu/elasticsearch/README.md)
  * [使用 elastic-oparator 部署 Elasticsearch 和 Kibana](cun-chu/elasticsearch/install-elasticsearch-and-kibana-with-elastic-oparator.md)
* [TODO:Rook](cun-chu/todo-rook.md)
* [TODO:TiKV](cun-chu/todo-tikv.md)
* [TODO:ETCD](cun-chu/todo-etcd.md)
* [TODO:Zookeeper](cun-chu/todo-zookeeper.md)
* [TODO:Cassandra](cun-chu/todo-cassandra.md)
* [TODO:MySQL](cun-chu/todo-mysql.md)
* [TODO:TiDB](cun-chu/todo-tidb.md)
* [TODO:PostgreSQL](cun-chu/todo-postgresql.md)
* [TODO:MongoDB](cun-chu/todo-mongodb.md)
* [TODO:InfluxDB](cun-chu/todo-influxdb.md)
* [TODO:OpenTSDB](cun-chu/todo-opentsdb.md)

## 监控

* [TODO:Prometheus](jian-kong/todo-prometheus.md)
* [TODO:Grafana](jian-kong/todo-grafana.md)
* [TODO:Jaeger](jian-kong/todo-jaeger.md)

## Ingress

* [TODO:Nginx](ingress/todo-nginx.md)
* [TODO:Traefik](ingress/todo-traefik.md)
* [TODO:Envoy](ingress/todo-envoy.md)
* [TODO:Kong](ingress/todo-kong.md)
* [TODO:Gloo](ingress/todo-gloo.md)
* [TODO:Contour](ingress/todo-contour.md)
* [TODO:Ambassador](ingress/todo-ambassador.md)
* [TODO:HAProxy](ingress/todo-haproxy.md)
* [TODO:Skipper](ingress/todo-skipper.md)

## Service Mesh

* [TODO:Istio](service-mesh/todo-istio.md)
* [TODO:Maesh](service-mesh/todo-maesh.md)
* [TODO:Kuma](service-mesh/todo-kuma.md)

## Serverless

* [TODO:Knative](serverless/todo-knative.md)
* [TODO:Kubeless](serverless/todo-kubeless.md)
* [TODO:Fission](serverless/todo-fission.md)

## CI/CD

* [TODO:Jenkins X](ci-cd/todo-jenkins-x.md)
* [TODO:Tekton](ci-cd/todo-tekton.md)
* [TODO:Argo](ci-cd/todo-argo.md)
* [TODO:GoCD](ci-cd/todo-gocd.md)
* [TODO:GitLab CI](ci-cd/todo-gitlab-ci.md)

## 镜像相关

* [TODO:Harbor](jing-xiang-xiang-guan/todo-harbor.md)
* [TODO:Dragonfly](jing-xiang-xiang-guan/todo-dragonfly.md)
* [TODO:Kaniko](jing-xiang-xiang-guan/todo-kaniko.md)
* [TODO:kpack](jing-xiang-xiang-guan/todo-kpack.md)

## 网络方案

* [TODO:Flannel](wang-luo-fang-an/todo-flannel.md)
* [TODO:Macvlan](wang-luo-fang-an/todo-macvlan.md)
* [TODO:Calico](wang-luo-fang-an/todo-calico.md)
* [TODO:Cilium](wang-luo-fang-an/todo-cilium.md)
* [TODO:Kube-router](wang-luo-fang-an/todo-kube-router.md)
* [TODO:Kube-OVN](wang-luo-fang-an/todo-kube-ovn.md)
* [TODO:OpenVSwitch](wang-luo-fang-an/todo-openvswitch.md)

