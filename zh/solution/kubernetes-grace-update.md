# 优雅热更新

当kubernetes对服务滚动更新的期间，默认配置的情况下可能会让部分连接异常（比如连接被拒绝），我们来分析下原因并给出最佳实践

## 滚动更新场景

使用 deployment 部署服务并关联 service

- 修改 deployment 的 replica 调整副本数量来滚动更新
- 升级程序版本(修改镜像tag)触发 deployment 新建 replicaset 启动新版本的 pod
- 使用 HPA (HorizontalPodAutoscaler) 来对 deployment 自动扩缩容

## 更新过程连接异常的原因

滚动更新时，service 对应的 pod 会被创建或销毁，也就是 service 对应的 endpoint 列表会新增或移除endpoint，更新期间可能让部分连接异常，主要原因是：

1. pod 被创建，还没完全启动就被 endpoint controller 加入到 service 的 endpoint 列表，然后 kube-proxy 配置对应的路由规则(iptables/ipvs)，如果请求被路由到还没完全启动完成的 pod，这时 pod 还不能正常处理请求，就会导致连接异常
2. pod 被销毁，但是从 endpoint controller watch 到变化并更新 service 的 endpoint 列表到 kube-proxy 更新路由规则这期间有个时间差，pod可能已经完全被销毁了，但是路由规则还没来得及更新，造成请求依旧还能被转发到已经销毁的 pod ip，导致连接异常

## 最佳实践

- 针对第一种情况，可以给 pod 里的 container 加 readinessProbe (就绪检查)，这样可以让容器完全启动了才被endpoint controller加进 service 的 endpoint 列表，然后 kube-proxy 再更新路由规则，这时请求被转发到的所有后端 pod 都是正常运行，避免了连接异常
- 针对第二种情况，可以给 pod 里的 container 加 preStop hook，让 pod 真正销毁前先 sleep 等待一段时间，留点时间给 endpoint controller 和 kube-proxy 清理 endpoint 和路由规则，这段时间 pod 处于 Terminating 状态，在路由规则更新完全之前如果有请求转发到这个被销毁的 pod，请求依然可以被正常处理，因为它还没有被真正销毁

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

- Container probes: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes
- Container Lifecycle Hooks: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/
