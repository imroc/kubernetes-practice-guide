---
title: "安装 traefik ingress controller"
---

## 最佳安装方案

如何暴露 ingress 访问入口? 最佳方案是使用 LoadBalancer 类型的 Service 来暴露，即创建外部负载均衡器来暴露流量，后续访问 ingress 的流量都走这个负载均衡器的地址，ingress 规则里面配的域名也要配置解析到这个负载均衡器的 IP 地址。

这种方式需要集群支持 LoadBalancer 类型的 Service，如果是云厂商提供的 k8s 服务，或者在云上自建集群并使用了云厂商提供的 cloud provider，也都是支持的，创建 LoadBalancer 类型的 Service 的时候会自动调云厂商的接口创建云厂商提供的负载均衡器产品(通常公网类型的负载均衡器是付费的)；如果你的集群不是前面说的情况，是自建集群并且有自己的负载均衡器方案，并部署了相关插件来适配，比如 MetalLB 和 Porter，这样也是可以支持 LoadBalancer 类型的 Service 的。

## 使用 helm 安装

``` bash
helm install stable/traefik \
  --name traefik \
  --namespace kube-system \
  --set kubernetes.ingressClass=traefik \
  --set kubernetes.ingressEndpoint.useDefaultPublishedService=true \
  --set rbac.enabled=true
```

* `kubernetes.ingressClass=traefik`: 创建的 ingress 中包含 `kubernetes.io/ingress.class` 这个 annotation 并且值与这里配置的一致，这个 traefik ingress controller 才会处理 (生成转发规则)
* `kubernetes.ingressEndpoint.useDefaultPublishedService=true`: 这个置为 true 主要是为了让 ingress 的外部地址正确显示 (显示为负载均衡器的地址)，因为如果不配置这个，默认情况下会将 ingress controller 所有实例的节点 ip 写到 ingress 的 address 里
* `rbac.enabled` 默认为 false，如果没有事先给 default 的 service account 绑足够权限就会报错，通常置为 true，自动创建 rbac 规则

## 参考资料

* Github 主页: https://github.com/containous/traefik
* helm hub 主页: https://hub.helm.sh/charts/stable/traefik
* 官方文档: https://docs.traefik.io
