# 服务更新不中断

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

## 解决长连接服务扩容失效

在现网运营中，有很多场景为了提高效率，一般都采用建立长连接的方式来请求。我们发现在客户端以长连接请求服务端的场景下，K8S的自动扩容会失效。原因是客户端长连接一直保留在老的Pod容器中，新扩容的Pod没有新的连接过来，导致K8S按照步长扩容第一批Pod之后就停止了扩容操作，而且新扩容的Pod没能承载请求，进而出现服务过载的情况，自动扩容失去了意义。

对长连接扩容失效的问题，我们的解决方法是将长连接转换为短连接。我们参考了 nginx keepalive 的设计，nginx 中 keepalive_requests 这个配置项设定了一个TCP连接能处理的最大请求数，达到设定值(比如1000)之后服务端会在 http 的 Header 头标记 “`Connection:close`”，通知客户端处理完当前的请求后关闭连接，新的请求需要重新建立TCP连接，所以这个过程中不会出现请求失败，同时又达到了将长连接按需转换为短连接的目的。通过这个办法客户端和云K8S服务端处理完一批请求后不断的更新TCP连接，自动扩容的新Pod能接收到新的连接请求，从而解决了自动扩容失效的问题。

由于Golang并没有提供方法可以获取到每个连接处理过的请求数，我们重写了 `net.Listener` 和 `net.Conn`，注入请求计数器，对每个连接处理的请求做计数，并通过 `net.Conn.LocalAddr()` 获得计数值，判断达到阈值 1000 后在返回的 Header 中插入 “`Connection:close`” 通知客户端关闭连接，重新建立连接来发起请求。以上处理逻辑用 Golang 实现示例代码如下：

``` go
package main

import (
 "net"
 "github.com/gin-gonic/gin"
 "net/http"
)

//重新定义net.Listener
type counterListener struct {
 net.Listener
}
//重写net.Listener.Accept(),对接收到的连接注入请求计数器
func (c *counterListener) Accept() (net.Conn, error) {
 conn, err := c.Listener.Accept()
 if err != nil {
  return nil, err
 }
 return &counterConn{Conn: conn}, nil
}
//定义计数器counter和计数方法Increment()
type counter int
func (c *counter) Increment() int {
 *c++
 return int(*c)
}

//重新定义net.Conn,注入计数器ct
type counterConn struct {
 net.Conn
 ct counter
}

//重写net.Conn.LocalAddr()，返回本地网络地址的同时返回该连接累计处理过的请求数
func (c *counterConn) LocalAddr() net.Addr {
 return &counterAddr{c.Conn.LocalAddr(), &c.ct}
}

//定义TCP连接计数器,指向连接累计请求的计数器
type counterAddr struct {
 net.Addr
 *counter
}

func main() {
 r := gin.New()
 r.Use(func(c *gin.Context) {
  localAddr := c.Request.Context().Value(http.LocalAddrContextKey)
  if ct, ok := localAddr.(interface{ Increment() int }); ok {
   if ct.Increment() >= 1000 {
    c.Header("Connection", "close")
   }
  }
  c.Next()
 })
 r.GET("/", func(c *gin.Context) {
  c.String(200, "plain/text", "hello")
 })
 l, err := net.Listen("tcp", ":8080")
 if err != nil {
  panic(err)
 }
 err = http.Serve(&counterListener{l}, r)
 if err != nil {
  panic(err)
 }
}
```

## 参考资料

- Container probes: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes
- Container Lifecycle Hooks: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/
