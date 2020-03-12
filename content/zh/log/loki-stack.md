---
title: "利用 Loki/Promtail/Grafana 收集分析日志"
weight: 20
state: TODO
---

## Loki/Promtail/Grafana vs EFK

* Loki 类似 EFK 中的 ElasticSearch，用于存储和查询日志
* Promtail 类似 EFK 中的 Filebeat/Fluentd，用于采集和发送日志
* Grafana 类似 EFK 中的 Kibana，用于 UI 展示

## 使用 Helm 安装

> 参考官方文档: https://github.com/grafana/loki/blob/master/docs/installation/helm.md

