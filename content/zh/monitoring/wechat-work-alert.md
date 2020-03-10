---
title: "企业微信告警"
weight: 30
state: TODO
---

## 原生支持的企业微信告警

配置参考：https://prometheus.io/docs/alerting/configuration/#wechat_config
操作参考: https://songjiayang.gitbooks.io/prometheus/content/alertmanager/wechat.html

## 通过企业微信群机器人告警

计划开源一款适配 alertmanager 的 webhook 程序，调企业微信群机器人的 webhook 发送群消息告警，告警内容根据 alertmanager 传来的内容进行封装
