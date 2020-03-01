---
title: "使用 preStopHook 和 readinessProbe 保证服务平滑更新不中断"
---

如果服务不做配置优化，默认情况下更新服务期间可能会导致部分流量异常，下面我们来分析并给出最佳实践。

## 服务更新场景

我们先看下服务更新有哪些场景:

* 手动调整服务的副本数量
* 手动删除 Pod 触发重新调度
* 驱逐节点 (主动或被动驱逐，Pod会先删除再在其它节点重建)
* 触发滚动更新 (比如修改镜像 tag 升级程序版本)
* HPA (HorizontalPodAutoscaler) 自动对服务进行水平伸缩
* VPA (VerticalPodAutoscaler) 自动对服务进行垂直伸缩

## 更新过程连接异常的原因

滚动更新时，Service 对应的 Pod 会被创建或销毁，Service 对应的 Endpoint 也会新增或移除相应的 Pod IP:Port，然后 kube-proxy 会根据 Service 的 Endpoint 里的 Pod IP:Port 列表更新节点上的转发规则，而这里 kube-proxy 更新节点转发规则的动作并不是那么及时，主要是由于 K8S 的设计理念，各个组件的逻辑是解耦的，各自使用 Controller 模式 listAndWatch 感兴趣的资源并做出相应的行为，所以从 Pod 创建或销毁到 Endpoint 更新再到节点上的转发规则更新，这个过程是异步的，所以会造成转发规则更新不及时，从而导致服务更新期间部分连接异常。

我们分别分析下 Pod 创建和销毁到规则更新期间的过程:

1. Pod 被创建，但启动速度没那么快，还没等到 Pod 完全启动就被 Endpoint Controller 加入到 Service 对应 Endpoint 的 Pod IP:Port 列表，然后 kube-proxy watch 到更新也同步更新了节点上的 Service 转发规则 (iptables/ipvs)，如果这个时候有请求过来就可能被转发到还没完全启动完全的 Pod，这时 Pod 还不能正常处理请求，就会导致连接被拒绝。
2. Pod 被销毁，但是从 Endpoint Controller watch 到变化并更新 Service 对应 Endpoint 再到 kube-proxy 更新节点转发规则这期间是异步的，有个时间差，Pod 可能已经完全被销毁了，但是转发规则还没来得及更新，就会造成新来的请求依旧还能被转发到已经被销毁的 Pod，导致连接被拒绝。

## 平滑更新最佳实践 <a id="smooth-update-best-practice"></a>

* 针对第一种情况，可以给 Pod 里的 container 加 readinessProbe (就绪检查)，通常是容器完全启动后监听一个 HTTP 端口，kubelet 发就绪检查探测包，正常响应说明容器已经就绪，然后修改容器状态为 Ready，当 Pod 中所有容器都 Ready 了这个 Pod 才会被 Endpoint Controller 加进 Service 对应 Endpoint IP:Port 列表，然后 kube-proxy 再更新节点转发规则，更新完了即便立即有请求被转发到的新的 Pod 也能保证能够正常处理连接，避免了连接异常。
* 针对第二种情况，可以给 Pod 里的 container 加 preStop hook，让 Pod 真正销毁前先 sleep 等待一段时间，留点时间给 Endpoint controller 和 kube-proxy 更新 Endpoint 和转发规则，这段时间 Pod 处于 Terminating 状态，即便在转发规则更新完全之前有请求被转发到这个 Terminating 的 Pod，依然可以被正常处理，因为它还在 sleep，没有被真正销毁。

最佳实践 yaml 示例:

``` yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      component: nginx
  template:
    metadata:
      labels:
        component: nginx
    spec:
      containers:
      - name: nginx
        image: "nginx"
        ports:
        - name: http
          hostPort: 80
          containerPort: 80
          protocol: TCP
        readinessProbe:
          httpGet:
            path: /healthz
            port: 80
            httpHeaders:
            - name: X-Custom-Header
              value: Awesome
          initialDelaySeconds: 15
          timeoutSeconds: 1
        lifecycle:
          preStop:
            exec:
              command: ["/bin/bash", "-c", "sleep 30"]
```

## 参考资料

* Container probes: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes
* Container Lifecycle Hooks: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/