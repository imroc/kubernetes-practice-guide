# 本地 DNS 缓存

## 注意

有两点需要注意下:

1. ipvs 模式下需要改 kubelet --cluster-dns 参数，指向一个非 kube-dns service 的 IP，通常用 169.254.20.10，ds会在每个节点创建一个网卡绑这个IP，pod 向本节点这个IP发dns请求，local dns 再代理到上游集群dns
2. iptables 模式下不需要改 kubelet --cluster-dns 参数，pod还是向原来的 kube-dns CLUSTER IP 请求 dns，节点上有这个IP监听，被 node local dns 拦截，再请求集群上游dns(使用另一个 dns service 的 CLUSTER IP，但跟 kube-dns 的 service 一样的 selector 和 endpoint)

ipvs 模式下必须修改 kubelet 参数的原因是：ds pod 创建了 kube-dns service 的本机 CLUSTER IP 网卡监听， kube-ipvs0 这个 dummy interface 上也会绑这个 IP (为了能让报文到达 INPUT 链进入 ipvs)，所以 pod 请求 kube-dns CLUSTER IP 的请求最终还是会到 ipvs, 做一次 dnat，相当于 node local dns 没有作用。

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

对于存量节点，登录节点执行以下命令:

``` bash
sed -i '/CLUSTER_DNS/c\CLUSTER_DNS="--cluster-dns=169.254.20.10"' /etc/kubernetes/kubelet
systemctl restart kubelet
```

对于增量节点，在TKE上可以将上述命令放入新增节点的 user-data，以便加入节点后自动执行。

后续新增才会用到本地 DNS 缓存，对于存量 Pod 可以销毁重建，比如改下 Deployment 中 template 里的 annotation，触发 Deployment 所有 Pod 滚动更新，如果怕滚动更新造成部分流量异常，可以参考 [服务更新最佳实践](/solution/service-ha#smooth-update)

## 参考资料

* https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns
* https://github.com/kubernetes/enhancements/blob/master/keps/sig-network/20190424-NodeLocalDNS-beta-proposal.md
