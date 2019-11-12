# 安装 nginx ingress controller

## 最佳安装方案

如何暴露 ingress 访问入口? 最佳方案是使用 LoadBalancer 类型的 Service 来暴露，即创建外部负载均衡器来暴露流量，后续访问 ingress 的流量都走这个负载均衡器的地址，ingress 规则里面配的域名也要配置解析到这个负载均衡器的 IP 地址。

这种方式需要集群支持 LoadBalancer 类型的 Service，如果是云厂商提供的 k8s 服务，或者在云上自建集群并使用了云厂商提供的 cloud provider，也都是支持的，创建 LoadBalancer 类型的 Service 的时候会自动调云厂商的接口创建云厂商提供的负载均衡器产品(通常公网类型的负载均衡器是付费的)；如果你的集群不是前面说的情况，是自建集群并且有自己的负载均衡器方案，并部署了相关插件来适配，比如 MetalLB 和 Porter，这样也是可以支持 LoadBalancer 类型的 Service 的。

## 使用 helm 安装

``` bash

helm install stable/nginx-ingress \
  --name nginx \
  --namespace kube-system \
  --set controller.ingressClass=nginx \
  --set controller.publishService.enabled=true \
```

* `controller.ingressClass`: 创建的 ingress 中包含 `kubernetes.io/ingress.class` 这个 annotation 并且值与这里配置的一致，这个 nginx ingress controller 才会处理 (生成转发规则)
* `controller.publishService.enabled`: 这个置为 true 主要是为了让 ingress 的外部地址正确显示 (显示为负载均衡器的地址)，因为如果不配置这个，默认情况下会将 ingress controller 所有实例的节点 ip 写到 ingress 的 address 里

安装完成后如何获取负载均衡器的 IP 地址？查看 nginx ingress controller 的 service 的 `EXTERNAL-IP` 就可以:

``` bash
$ kubectl -n kube-system get service nginx-nginx-ingress-controller
NAME                             TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
nginx-nginx-ingress-controller   LoadBalancer   172.16.255.194   119.28.123.174   80:32348/TCP,443:32704/TCP   10m
```

如果需要新的流量入口，可以按照同样的方法用 helm 安装新的 release，注意要设置不同的 `controller.ingressClass`，将希望用新流量入口暴露的 ingress 的 `kubernetes.io/ingress.class` annotation 设置成这里的值就可以。

如果转发性能跟不上，可以增加 controller 的副本，设置 `controller.replicaCount` 的值，或者启用 HPA 自动伸缩，将 `controller.autoscaling.enabled` 置为 true，更多细节控制请参考官方文档。

## 配置优化

配置更改如果比较多推荐使用覆盖 `values.yaml` 的方式来安装 nginx ingress:

1. 导出默认的 `values.yaml`:
  ``` bash
  helm inspect values stable/nginx-ingress > values.yaml
  ```
2. 修改 `values.yaml` 中的配置
3. 执行 helm install 的时候去掉 `--set` 的方式设置的变量，替换为使用 `-f values.yaml`

有时可能更新 nginx ingress 的部署，滚动更新时可能造成部分连接异常，可以参考服务平滑更新最佳实践 [使用 preStopHook 和 readinessProbe 保证服务平滑更新不中断](/best-practice/service-ha.md#smooth-update-using-prestophook-and-readinessprobe)，nginx ingress 默认加了 readinessProbe，但 preStop 没有加，我们可以修改 `values.yaml` 中 `controller.lifecycle`，加上 preStop，示例:

``` yaml
  lifecycle:
    preStop:
      exec:
        command: ["/bin/bash", "-c", "sleep 30"]
```

还可以 [使用反亲和性避免单点故障](/best-practice/service-ha.md#use-antiaffinity-to-avoid-single-points-of-failure)，修改 `controller.affinity` 字段示例:

``` yaml
  affinity:
   podAntiAffinity:
     requiredDuringSchedulingIgnoredDuringExecution:
     - weight: 100
       labelSelector:
         matchExpressions:
         - key: app
           operator: In
           values:
           - nginx-ingress
         - key: component
           operator: In
           values:
           - controller
         - key: release
           operator: In
           values:
           - nginx
       topologyKey: kubernetes.io/hostname
```

## 参考资料

* Github 主页: https://github.com/kubernetes/ingress-nginx
* helm hub 主页: https://hub.helm.sh/charts/nginx/nginx-ingress
* 官方文档: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/
