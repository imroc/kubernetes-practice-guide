---
title: "利用 Loki/Promtail/Grafana 收集分析日志"
weight: 20
state: Alpha
LastModifierDisplayName: "roc"
LastModifierURL: "https://imroc.io"
date: 2020-03-12
---

## Loki/Promtail/Grafana vs EFK

Loki Stack 包含三个组件：

* Loki: 相当于 EFK 中的 ElasticSearch，用于存储和查询日志
* Promtail: 相当于 EFK 中的 Filebeat/Fluentd，用于采集和发送日志
* Grafana: 相当于 EFK 中的 Kibana，用于 UI 展示

## 使用 Helm 部署 Loki Stack 到 Kubernetes

> 参考官方文档: https://github.com/grafana/loki/blob/master/docs/installation/helm.md

`loki/loki-stack` 这个 chart 包含 loki stack 涉及的各个组件:

* loki: 以 Statefulset 方式部署，可横向扩容
* promtail: 以 Daemonset 方式部署，采集每个节点上容器日志并发送给 loki
* grafana: 默认不开启，如果集群中已经有 grafana 就可以不用在部署 grafana，如果没有，部署时可以选择也同时部署 grafana

首先添加 repo:

``` bash
helm repo add loki https://grafana.github.io/loki/charts
helm repo update
```

执行安装:

{{< tabs name="tab_with_code" >}}
{{{< tab name="Helm 2" codelang="bash" >}}
helm upgrade --install loki loki/loki-stack
# 安装到指定命名空间
# helm upgrade --install loki loki/loki-stack -n monitoring
# 持久化 loki 的数据，避免 loki 重启后数据丢失
# helm upgrade --install loki loki/loki-stack --set="loki.persistence.enabled=ture,loki.persistence.size=100G"
# 部署 grafana
# helm upgrade --install loki loki/loki-stack --set="grafana=true"
{{< /tab >}}
{{< tab name="Helm 3" codelang="bash" >}}
helm install loki loki/loki-stack
# 安装到指定命名空间
# helm install loki loki/loki-stack -n monitoring
# 持久化 loki 的数据，避免 loki 重启后数据丢失
# helm install loki loki/loki-stack --set="loki.persistence.enabled=ture,loki.persistence.size=100G"
# 部署 grafana
# helm install loki loki/loki-stack --set="grafana.enabled=true"
{{< /tab >}}}
{{< /tabs >}}

进入 grafana 界面，添加 loki 作为数据源：Configuration-Data Sources-Add data source-Loki，然后填入 loki 在集群中的地址，比如: http://loki.monitoring.svc.cluster.local:3100

![](/images/loki-grafana-data-source.png)

数据源添加好了，我们就可以开始查询分析日志了，点击 `Explore`，下拉选择 loki 作为数据源，切到 `Logs` 模式(不用 `Metrics` 模式)，在 `Log labels` 按钮那里就能通过 label 筛选日志了。更多用法请参考 [官方文档](https://github.com/grafana/loki/tree/master/docs)

![](/images/loki-log.png)
