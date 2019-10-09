# 以 Daemonset 方式部署 kube-proxy


kube-proxy 可以用二进制部署，也可以用 kubelet 的静态 Pod 部署，但最简单使用 DaemonSet 部署。直接使用 ServiceAccount 的 token 认证，不需要签发证书，也就不用担心证书过期问题。

为 kube-proxy 创建 RBAC 权限和配置文件:

``` bash
APISERVER="https://10.200.16.79:6443"
CLUSTER_CIDR="10.10.0.0/16"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-proxy
  namespace: kube-system

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kube-proxy
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:node-proxier
subjects:
- kind: ServiceAccount
  name: kube-proxy
  namespace: kube-system

---

kind: ConfigMap
apiVersion: v1
metadata:
  name: kube-proxy
  namespace: kube-system
  labels:
    app: kube-proxy
data:
  kubeconfig.conf: |-
    apiVersion: v1
    kind: Config
    clusters:
    - cluster:
        certificate-authority: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        server: ${APISERVER}
      name: default
    contexts:
    - context:
        cluster: default
        namespace: default
        user: default
      name: default
    current-context: default
    users:
    - name: default
      user:
        tokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
  config.conf: |-
    apiVersion: kubeproxy.config.k8s.io/v1alpha1
    kind: KubeProxyConfiguration
    bindAddress: 0.0.0.0
    clientConnection:
      acceptContentTypes: ""
      burst: 10
      contentType: application/vnd.kubernetes.protobuf
      kubeconfig: /var/lib/kube-proxy/kubeconfig.conf
      qps: 5
    # 集群中 Pod IP 的 CIDR 范围
    clusterCIDR: ${CLUSTER_CIDR}
    configSyncPeriod: 15m0s
    conntrack:
      # 每个核心最大能跟踪的NAT连接数，默认32768
      maxPerCore: 32768
      min: 131072
      tcpCloseWaitTimeout: 1h0m0s
      tcpEstablishedTimeout: 24h0m0s
    enableProfiling: false
    healthzBindAddress: 0.0.0.0:10256
    iptables:
      # SNAT 所有 Service 的 CLUSTER IP
      masqueradeAll: false
      masqueradeBit: 14
      minSyncPeriod: 0s
      syncPeriod: 30s
    ipvs:
      minSyncPeriod: 0s
      # ipvs 调度类型，默认是 rr，支持的所有类型:
      # rr: round-robin
      # lc: least connection
      # dh: destination hashing
      # sh: source hashing
      # sed: shortest expected delay
      # nq: never queue
      scheduler: rr
      syncPeriod: 30s
    metricsBindAddress: 0.0.0.0:10249
    # 使用 ipvs 模式转发 service
    mode: ipvs
    # 设置 kube-proxy 进程的 oom-score-adj 值，范围 [-1000,1000]
    # 值越低越不容易被杀死，这里设置为 —999 防止发生系统OOM时将 kube-proxy 杀死
    oomScoreAdj: -999
EOF
```

* `APISERVER` 替换为 apiserver 对外暴露的访问地址。有同学想问为什么不直接用集群内的访问地址(`kubernetes.default` 或对应的 CLUSTER IP)，这是一个鸡生蛋还是蛋生鸡的问题，CLSUTER IP 本身就是由 kube-proxy 来生成 iptables 或 ipvs 规则转发 Service 对应 Endpoint 的 Pod IP，kube-proxy 刚启动还没有生成这些转发规则，生成规则的前提是 kube-proxy 需要访问 apiserver 获取 Service 与 Endpoint，而由于还没有转发规则，kube-proxy 访问 apiserver 的 CLUSTER IP 的请求无法被转发到 apiserver。
* `CLUSTER_CIDR` 替换为集群 Pod IP 的 CIDR 范围，这个在部署 kube-controller-manager 时也设置过

以 Daemonset 方式部署 kube-proxy 到每个节点:

``` bash
ARCH="amd64"
VERSION="v1.16.1"
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    k8s-app: kube-proxy-ds-${ARCH}
  name: kube-proxy-ds-${ARCH}
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: kube-proxy-ds-${ARCH}
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        k8s-app: kube-proxy-ds-${ARCH}
    spec:
      priorityClassName: system-node-critical
      containers:
      - name: kube-proxy
        image: k8s.gcr.io/kube-proxy-${ARCH}:${VERSION}
        imagePullPolicy: IfNotPresent
        command:
        - /usr/local/bin/kube-proxy
        - --config=/var/lib/kube-proxy/config.conf
        - --hostname-override=\$(NODE_NAME)
        securityContext:
          privileged: true
        volumeMounts:
        - mountPath: /var/lib/kube-proxy
          name: kube-proxy
        - mountPath: /run/xtables.lock
          name: xtables-lock
          readOnly: false
        - mountPath: /lib/modules
          name: lib-modules
          readOnly: true
        env:
          - name: NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
      hostNetwork: true
      serviceAccountName: kube-proxy
      volumes:
      - name: kube-proxy
        configMap:
          name: kube-proxy
      - name: xtables-lock
        hostPath:
          path: /run/xtables.lock
          type: FileOrCreate
      - name: lib-modules
        hostPath:
          path: /lib/modules
      tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - operator: Exists
      nodeSelector:
        beta.kubernetes.io/arch: ${ARCH}
EOF
```

* `VERSION` 是 K8S 版本
* `ARCH` 是节点的 cpu 架构，大多数用的 `amd64`，即 x86_64。其它常见的还有: `arm64`, `arm`, `ppc64le`, `s390x`，如果你的集群有不同 cpu 架构的节点，可以分别指定 `ARCH` 部署多个 daemonset (每个节点不会有多个 kube-proxy，nodeSelector 会根据 cpu 架构来选中节点)
