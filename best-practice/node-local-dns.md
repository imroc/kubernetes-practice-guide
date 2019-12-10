# 本地 DNS 缓存

## 为什么需要本地 DNS 缓存

* 减轻集群 DNS 解析压力，提高 DNS 性能
* 避免 netfilter 做 DNAT 导致 conntrack 冲突引发 [DNS 5 秒延时](/troubleshooting/cases/dns-lookup-5s-delay.md)

  > 镜像底层库 DNS 解析行为默认使用 UDP 在同一个 socket 并发 A 和 AAAA 记录请求，由于 UDP 无状态，两个请求可能会并发创建 conntrack 表项，如果最终 DNAT 成同一个集群 DNS 的 Pod IP 就会导致 conntrack 冲突，由于 conntrack 的创建和插入是不加锁的，最终后面插入的 conntrack 表项就会被丢弃，从而请求超时，默认 5s 后重试，造成现象就是 DNS 5 秒延时; 底层库是 glibc 的容器镜像可以通过配 resolv.conf 参数来控制 DNS 解析行为，不用 TCP 或者避免相同五元组并发(使用串行解析 A 和 AAAA 避免并发或者使用不同 socket 发请求避免相同源端口)，但像基于 alpine 镜像的容器由于底层库是 musl libc，不支持这些 resolv.conf 参数，也就无法规避，所以最佳方案还是使用本地 DNS 缓存。

## 原理

本地 DNS 缓存以 DaemonSet 方式在每个节点部署一个使用 hostNetwork 的 Pod，创建一个网卡绑上本地 DNS 的 IP，本机的 Pod 的 DNS 请求路由到本地 DNS，然后取缓存或者继续使用 TCP 请求上游集群 DNS 解析 (由于使用 TCP，同一个 socket 只会做一遍三次握手，不存在并发创建 conntrack 表项，也就不会有 conntrack 冲突)

## IPVS 模式下需要修改 kubelet 参数

有两点需要注意下:

1. ipvs 模式下需要改 kubelet `--cluster-dns` 参数，指向一个非 kube-dns service 的 IP，通常用 `169.254.20.10`，Daemonset 会在每个节点创建一个网卡绑这个 IP，Pod 向本节点这个 IP 发 DNS 请求，本机 DNS 再代理到上游集群 DNS
2. iptables 模式下不需要改 kubelet `--cluster-dns` 参数，Pod 还是向原来的集群 DNS 请求，节点上有这个 IP 监听，被本机拦截，再请求集群上游 DNS (使用集群 DNS 的另一个 CLUSTER IP，来自事先创建好的 Service，跟原集群 DNS 的 Service 有相同的 selector 和 endpoint)

ipvs 模式下必须修改 kubelet 参数的原因是：如果不修改，DaemonSet Pod 在本机创建了网卡，会绑跟集群 DNS 的 CLUSTER IP， 但 kube-ipvs0 这个 dummy interface 上也会绑这个 IP (这是 ipvs 的机制，为了能让报文到达 INPUT 链被 ipvs 处理)，所以 Pod 请求集群 DNS 的报文最终还是会被 ipvs 处理, DNAT 成集群 DNS 的 Pod IP，最终路由到集群 DNS，相当于本机 DNS 就没有作用了。

## IPVS 模式下部署方法

这里我们假设是 ipvs 模式，下面给出本地 DNS 缓存部署方法。

创建 ServiceAccount 与集群上游 DNS 的 Service:

``` bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: node-local-dns
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
---
apiVersion: v1
kind: Service
metadata:
  name: kube-dns-upstream
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    kubernetes.io/name: "KubeDNSUpstream"
spec:
  ports:
  - name: dns
    port: 53
    protocol: UDP
    targetPort: 53
  - name: dns-tcp
    port: 53
    protocol: TCP
    targetPort: 53
  selector:
    k8s-app: kube-dns
EOF
```

获取 `kube-dns-upstream` 的 CLUSTER IP:

``` bash
UPSTREAM_CLUSTER_IP=$(kubectl -n kube-system get services kube-dns-upstream -o jsonpath="{.spec.clusterIP}")
```

部署 DaemonSet:

``` bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: node-local-dns
  namespace: kube-system
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
data:
  Corefile: |
    cluster.local:53 {
        errors
        cache {
                success 9984 30
                denial 9984 5
        }
        reload
        loop
        bind 169.254.20.10
        forward . ${UPSTREAM_CLUSTER_IP} {
                force_tcp
        }
        prometheus :9253
        health 169.254.20.10:8080
        }
    in-addr.arpa:53 {
        errors
        cache 30
        reload
        loop
        bind 169.254.20.10
        forward . ${UPSTREAM_CLUSTER_IP} {
                force_tcp
        }
        prometheus :9253
        }
    ip6.arpa:53 {
        errors
        cache 30
        reload
        loop
        bind 169.254.20.10
        forward . ${UPSTREAM_CLUSTER_IP} {
                force_tcp
        }
        prometheus :9253
        }
    .:53 {
        errors
        cache 30
        reload
        loop
        bind 169.254.20.10
        forward . /etc/resolv.conf {
                force_tcp
        }
        prometheus :9253
        }
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-local-dns
  namespace: kube-system
  labels:
    k8s-app: node-local-dns
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  updateStrategy:
    rollingUpdate:
      maxUnavailable: 10%
  selector:
    matchLabels:
      k8s-app: node-local-dns
  template:
    metadata:
       labels:
          k8s-app: node-local-dns
    spec:
      priorityClassName: system-node-critical
      serviceAccountName: node-local-dns
      hostNetwork: true
      dnsPolicy: Default  # Don't use cluster DNS.
      tolerations:
      - key: "CriticalAddonsOnly"
        operator: "Exists"
      containers:
      - name: node-cache
        image: k8s.gcr.io/k8s-dns-node-cache:1.15.7
        resources:
          requests:
            cpu: 25m
            memory: 5Mi
        args: [ "-localip", "169.254.20.10", "-conf", "/etc/Corefile", "-upstreamsvc", "kube-dns-upstream" ]
        securityContext:
          privileged: true
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
        - containerPort: 9253
          name: metrics
          protocol: TCP
        livenessProbe:
          httpGet:
            host: 169.254.20.10
            path: /health
            port: 8080
          initialDelaySeconds: 60
          timeoutSeconds: 5
        volumeMounts:
        - mountPath: /run/xtables.lock
          name: xtables-lock
          readOnly: false
        - name: config-volume
          mountPath: /etc/coredns
        - name: kube-dns-config
          mountPath: /etc/kube-dns
      volumes:
      - name: xtables-lock
        hostPath:
          path: /run/xtables.lock
          type: FileOrCreate
      - name: kube-dns-config
        configMap:
          name: kube-dns
          optional: true
      - name: config-volume
        configMap:
          name: node-local-dns
          items:
            - key: Corefile
              path: Corefile.base
EOF
```

验证是否启动:

``` bash
$ kubectl -n kube-system get pod -o wide | grep node-local-dns
node-local-dns-2m9b6               1/1       Running   0          15m       10.0.0.28    10.0.0.28
node-local-dns-qgrwl               1/1       Running   0          15m       10.0.0.186   10.0.0.186
node-local-dns-s5mhw               1/1       Running   0          51s       10.0.0.76    10.0.0.76
```

我们需要替换 kubelet 的 `--cluster-dns` 参数，指向 `169.254.20.10` 这个 IP。

在TKE上，对于存量节点，登录节点执行以下命令:

``` bash
sed -i '/CLUSTER_DNS/c\CLUSTER_DNS="--cluster-dns=169.254.20.10"' /etc/kubernetes/kubelet
systemctl restart kubelet
```

对于增量节点，可以将上述命令放入新增节点的 user-data，以便加入节点后自动执行。

后续新增才会用到本地 DNS 缓存，对于存量 Pod 可以销毁重建，比如改下 Deployment 中 template 里的 annotation，触发 Deployment 所有 Pod 滚动更新，如果怕滚动更新造成部分流量异常，可以参考 [服务更新最佳实践](/best-practice/service-ha.md#smooth-update)

## 参考资料

* https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns
* https://github.com/kubernetes/enhancements/blob/master/keps/sig-network/20190424-NodeLocalDNS-beta-proposal.md
