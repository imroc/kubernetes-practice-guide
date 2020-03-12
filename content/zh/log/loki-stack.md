---
title: "利用 Loki/Promtail/Grafana 收集分析日志"
weight: 20
state: TODO
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

`loki/loki-stack` 这个 chart 包含 loki stack 涉及的各个组件，首先添加 repo:

``` bash
helm repo add loki https://grafana.github.io/loki/charts
helm repo update
```

默认安装就只包含 loki 和 promtail 两个组件，如果你的集群中已有了 grafana，部署时可以直接用默认安装，不启用 grafana，当然也可以指定参数同时部署 grafana。

{{< tabs name="tab_with_code" >}}
{{{< tab name="Helm 2" codelang="bash" >}}
helm upgrade --install loki loki/loki-stack
# 安装到指定命名空间
# helm upgrade --install loki loki/loki-stack -n monitoring
# 部署 grafana
# helm upgrade --install loki loki/loki-stack -n monitoring --set="grafana=true"
{{< /tab >}}
{{< tab name="Helm 3" codelang="bash" >}}
helm install loki loki/loki-stack
# 安装到指定命名空间
# helm install loki loki/loki-stack -n monitoring
# 部署 grafana
# helm install loki loki/loki-stack -n monitoring --set="grafana=true"
{{< /tab >}}}
{{< /tabs >}}
