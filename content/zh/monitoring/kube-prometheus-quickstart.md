---
title: "使用 kube-promethues 快速上手集群监控"
weight: 10
state: Alpha
---

## kube-prometheus 介绍

kube-prometheus 包含了在 k8s 环境下各种主流的监控组件，将其安装到集群可以快速搭建我们自己的监控系统:

* prometheus-operator: 让 prometheus 更好的适配 k8s，可直接通过创建 k8s CRD 资源来创建 prometheus 与 alertmanager 实例及其监控告警规则 (默认安装时也会创建这些 CRD 资源，也就是会自动部署 prometheus 和 alertmanager，以及它们的配置)
* prometheus-adapter: 让 prometheus 采集的监控数据来适配 k8s 的 [resource metrics API](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/instrumentation/resource-metrics-api.md) 和 [custom metrics API](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/instrumentation/custom-metrics-api.md)，`kubectl top` 和 HPA 功能都依赖它们。
* node-exporter: 已 DaemonSet 方式部署在每个节点，将节点的各项系统指标暴露成 prometheus 能识别的格式，以便让 prometheus 采集。
* kube-state-metrics: 将 k8s 的资源对象转换成 prometheus 的 metrics 格式以便让 prometheus 采集，比如 Node/Pod 的各种状态。
* grafana: 可视化展示监控数据的界面。

项目地址: https://github.com/coreos/kube-prometheus

## 快速安装

如果只是想学习如何使用，可以参考 [官方文档](https://github.com/coreos/kube-prometheus#quickstart) 一键部署到集群:

``` bash
git clone https://github.com/coreos/kube-prometheus.git
cd kube-prometheus
# Create the namespace and CRDs, and then wait for them to be availble before creating the remaining resources
kubectl create -f manifests/setup
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
kubectl create -f manifests/
```

## 进入 grafana 界面

你可以通过将 grafana 的 service 类型改为 NodePort 或 LoadBalancer，也可以用 Ingress 来暴露 grafana 的界面, 如果你本机能通过 kubectl 访问集群，那可以直接通过 `kubectl port-forward` 端口转发来暴露访问:

``` bash
kubectl port-forward service/grafana 3000:3000 -n monitoring
```

然后打开 http://localhost:3000 即可进入 grafana 的界面，初始用户名密码都是 admin，输入后会强制让改一下初始密码才允许进入。

因为 kube-prometheus 为我们预配置了指标采集规则和 grafana 的 dashboard 展示配置，所以进入 grafana 界面后，点击左上角即可选择预配置好的监控面板:

![](/images/grafana-select-dashboard.png?classes=no-margin)

选择一些看下效果探索下吧:

![](/images/grafana-dashboard-pod.png?classes=no-margin)
