# 部署 Master

## 准备证书 <a id="prepare-certs"></a>

Master 节点的准备证书操作只需要做一次，将生成的证书拷到每个 Master 节点上以复用。

### 为 kube-apiserver 签发证书 <a id="sign-certs-for-kube-apiserver"></a>

kube-apiserver 是 k8s 的访问核心，所有 K8S 组件和用户 kubectl 操作都会请求 kube-apiserver，通常启用 tls 证书认证，证书里面需要包含 kube-apiserver 可能被访问的地址，这样 client 校验 kube-apiserver 证书时才会通过，集群内的 Pod 一般通过 kube-apiserver 的 Service 名称访问，可能的 Service 名称有:

* `kubernetes`
* `kubernetes.default`
* `kubernetes.default.svc`
* `kubernetes.default.svc.cluster`
* `kubernetes.default.svc.cluster.local`

通过集群外也可能访问 kube-apiserver，比如使用 kubectl，或者部署在集群外的服务会连 kube-apiserver (比如部署在集群外的 Promethues 采集集群指标做监控)，这里列一下通过集群外连 kube-apiserver 有哪些可能地址:

* `127.0.0.1`: 在 Master 所在机器通过 127.0.0.1 访问本机 kube-apiserver
* Service CIDR 的第一个 IP，比如 flanneld 以 daemonset 部署在每个节点，使用 hostNetwork 而不是集群网络，这时无法通过 service 名称访问 apiserver，因为使用 hostNetwork 无法解析 service 名称 (使用的 DNS 不是集群 DNS)，它会使用 apiserver 内部的 CLUSTER IP 去请求 apiserver。 kube-controller-manager 的 `--service-cluster-ip-range` 启动参数是 `10.32.0.0/16`，那么第一个 IP 就是 `10.32.0.1`
* 自定义域名: 配了 DNS，通过域名访问 kube-apiserver，也要将域名写入证书
* LB IP: 如果 Master 节点前面挂了一个负载均衡器，外界可以通过 LB IP 来访问 kube-apiserver
* Master 节点 IP: 如果没有 Master 负载均衡器，管理员在节点上执行 kubectl 通常使用 Master 节点 IP 访问 kube-apiserver

``` bash
cat > kubernetes-csr.json <<EOF
{
    "CN": "kubernetes",
    "hosts": [
      "127.0.0.1",
      "10.32.0.1",
      "10.200.16.79",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "SiChuan",
            "L": "Chengdu",
            "O": "Kubernetes",
            "OU": "Kube API Server"
        }
    ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

```

> hosts 这里只准备了必要的，根据需求可增加，通常 Master 节点 IP 也都要加进去，你可以执行了上面的命令后再编辑一下 `kubernetes-csr.json`，将需要 hosts 都加进去。

会生成下面两个重要的文件:

* `kubernetes-key.pem`: kube-apiserver 证书密钥
* `kubernetes.pem`: kube-apiserver 证书

### 为 kube-controller-manager 签发证书 <id="sign-for-kube-controller-manager"></a>

``` bash
cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "SiChuan",
      "L": "Chengdu",
      "O": "system:kube-controller-manager",
      "OU": "Kube Controller Manager"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
```

生成以下两个文件:

* `kube-controller-manager-key.pem`: kube-controller-manager 证书密钥
* `kube-controller-manager.pem`: kube-controller-manager 证书

### 为 kube-scheduler 签发证书 <a id="sign-for-kube-scheduler"></a>

``` bash
cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "SiChuan",
      "L": "Chengdu",
      "O": "system:kube-scheduler",
      "OU": "Kube Scheduler"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

```

生成以下两个文件:

* `kube-scheduler-key.pem`: kube-scheduler 证书密钥
* `kube-scheduler.pem`: kube-scheduler 证书公钥

### 签发 Service Account 密钥对 <a id="sign-for-serviceaccount"></a>

`kube-controller-manager` 会使用此密钥对来给 service account 签发 token，更多详情参考官方文档: https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/

``` bash
cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "SiChuan",
      "L": "Chengdu",
      "O": "Kubernetes",
      "OU": "Service Account"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account

```

生成以下两个文件:

* `service-account-key.pem`: service account 证书公钥
* `service-account.pem`: service account 证书私钥

### 为管理员签发证书 <a id="sign-for-admin"></a>

为最高权限管理员证书:

``` bash
cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "SiChuan",
      "L": "Chengdu",
      "O": "system:masters",
      "OU": "System"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin
```

生成一下两个文件:

* `admin-key.pem`: 管理员证书密钥
* `admin.pem`: 管理员证书

给用户签发证书后，用户访问 kube-apiserver 的请求就带上此证书，kube-apiserver 校验成功后表示认证成功，但还需要授权才允许访问，kube-apiserver 会提取证书中字段 `CN` 作为用户名，这里用户名叫 `admin`，但这只是个名称标识，它有什么权限呢？`admin` 是预置最高权限的用户名吗？不是的！不过 kube-apiserver 确实预置了一个最高权限的 `ClusterRole`，叫做 `cluster-admin`，还有个预置的 `ClusterRoleBinding` 将 `cluster-admin` 这个 `ClusterRole` 与 `system:masters` 这个用户组关联起来了，所以说我们给用户签发证书只要在 `system:masters` 这个用户组就拥有了最高权限。

以此类推，我们签发证书时也可以将用户设置到其它用户组，然后为其创建 RBAC 规则来细粒度的控制权限，减少安全隐患。

更多 K8S 预置的 Role 与 RoleBinding 请参考: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#default-roles-and-role-bindings

## 准备 kubeconfig <a id="prepare-kubeconfig"></a>

Master 节点的准备 kubeconfig 操作只需要做一次，将生成的 kubeconfig 拷到每个 Master 节点上以复用。

`kubeconfig` 主要是用于各组件访问 apiserver 的必要配置，包含 apiserver 地址、client 证书与 CA 证书等信息。下面介绍为各个组件生成 `kubeconfig` 的方法。

所有组件都会去连 apiserver，所以首先需要确定你的 apiserver 访问入口的地址:

* 如果所有 master 组件都部署在一个节点，它们可以通过 127.0.0.1 这个 IP访问 apiserver。
* 如果 master 有多个节点，但 apiserver 只有一个实例，可以直接写 apiserver 所在机器的内网 IP 访问地址。
* 如果做了高可用，有多个 apiserver 实例，前面挂了负载均衡器，就可以写负载均衡器的访问地址。

这里我们用 `apiserver` 这个变量表示 apiserver 的访问地址，其它组件都需要配置这个地址，根据自身情况改下这个变量的值:

``` bash
apiserver="https://10.200.16.79:6443"
```

我们使用 `kubectl` 来辅助生成 kubeconfig，确保 kubectl 已安装。

### 为 kube-proxy 创建 kubeconfig <a id="create-kubeconfig-for-kube-proxy"></a>

``` bash
apiserver="https://10.200.16.79:6443"

kubectl config set-cluster roc \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=${apiserver} \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=kube-proxy.pem \
  --client-key=kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=roc \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

```

生成文件:

``` txt
kube-proxy.kubeconfig
```

### kube-controller-manager <a id="create-kubeconfig-for-kube-controller-manager"></a>

``` bash
apiserver="https://10.200.16.79:6443"

kubectl config set-cluster roc \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=${apiserver} \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=kube-controller-manager.pem \
  --client-key=kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=roc \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

```

生成文件:

``` txt
kube-controller-manager.kubeconfig
```

### kube-scheduler <a id="create-kubeconfig-for-kube-scheduler"></a>

``` bash
apiserver="https://10.200.16.79:6443"

kubectl config set-cluster roc \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=${apiserver} \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=kube-scheduler.pem \
  --client-key=kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context default \
  --cluster=roc \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig

```

生成文件:

``` txt
kube-scheduler.kubeconfig
```

### 管理员 <a id="create-kubeconfig-for-admin"></a>

这里为管理员生成 kubeconfig，方便使用 kubectl 来管理集群:

``` bash
kubectl config set-cluster roc \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=${apiserver} \
  --kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig

kubectl config set-context default \
  --cluster=roc \
  --user=admin \
  --kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig

```

生成文件:

``` txt
admin.kubeconfig
```

> 可以将 `admin.kubeconfig` 放到 `~/.kube/config`，这是 kubectl 读取 kubeconfig 的默认路径，执行 kubectl 时就不需要指定 kubeconfig 路径了

## 下载安装控制面组件

``` bash
wget -q --show-progress --https-only --timestamping \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kube-apiserver \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kube-controller-manager \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kube-scheduler

chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
```

## 配置控制面组件 <a id="configure-control-plane"></a>

准备配置相关目录:

``` bash
sudo mkdir -p /etc/kubernetes/config
sudo mkdir -p /var/lib/kubernetes
```

确定集群的集群网段 (Pod IP 占用网段)和 serivce 网段 (service 的 cluster ip 占用网段)，它们可以没有交集。

记集群网段为 CLUSTER_CIDR:

``` bash
CLUSTER_CIDR=10.10.0.0/16
```

记 service 网段为 SERVICE_CIDR:

``` bash
SERVICE_CIDR=10.32.0.0/16
```

### 配置 kube-apiserver <a id="configure-kube-apiserver"></a>

放入证书文件:

``` bash
sudo cp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
  service-account-key.pem service-account.pem /var/lib/kubernetes/
```

记当前节点内网 IP 为 INTERNAL_IP:

``` bash
INTERNAL_IP=10.200.16.79
```

配置 systemd:

``` bash
cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --enable-bootstrap-token-auth=true \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://10.200.16.79:2379,https://10.200.17.6:2379,https://10.200.16.70:2379 \\
  --event-ttl=1h \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=api/all \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

* `--enable-bootstrap-token-auth=true` 启用 bootstrap token 方式为 kubelet 签发证书
* `--etcd-servers` 替换 IP 为所有 etcd 节点内网 IP

### 配置 kube-controller-manager <a id="configure-kube-controller-manager"></a>

放入 kubeconfig:

``` bash
sudo cp kube-controller-manager.kubeconfig /var/lib/kubernetes/
```

准备 systemd 配置 `kube-controller-manager.service`:

``` bash
CLUSTER_CIDR=10.10.0.0/16
SERVICE_CIDR=10.32.0.0/16

cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --cluster-cidr=${CLUSTER_CIDR} \\
  --allocate-node-cidrs \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --rotate-certificates \\
  --rotate-server-certificates \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

> 所有 kube-controller-manager 实例都使用相同的 systemd service 文件，可以直接将这里创建好的拷贝给其它 Master 节点

### 配置 kube-scheduler <a id="configure-kube-scheduler"></a>

放入 kubeconfig:

``` bash
sudo cp kube-scheduler.kubeconfig /var/lib/kubernetes/
```

准备启动配置文件 `kube-scheduler.yaml`:

``` bash
cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF
```

准备 systemd 配置 `kube-scheduler.service`:

``` bash
cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

## 启动

``` bash
sudo systemctl daemon-reload
sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
```

## RBAC 授权 kube-apiserver 访问 kubelet

使用 [这里](#create-kubeconfig-for-admin) 给管理员创建好的 kubeconfig 来执行 kubectl，为集群配置 RBAC 规则，授权 kube-apiserver 访问 kubelet，此步骤只需要做一次:

``` bash
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF

cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
```

## RBAC 授权 kubelet 创建 CSR 自动签发并轮转证书

节点 kubelet 通过 Bootstrap Token 调用 apiserver CSR API 请求签发证书，bootstrap token 在 `system:bootstrappers` 用户组，我们需要给它授权调用 CSR API，为这个用户组绑定预定义的 `system:node-bootstrapper` 这个 ClusterRole 就可以:

``` bash
cat <<EOF | kubectl apply -f -
# enable bootstrapping nodes to create CSR
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: create-csrs-for-bootstrapping
subjects:
- kind: Group
  name: system:bootstrappers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:node-bootstrapper
  apiGroup: rbac.authorization.k8s.io
EOF
```

给 kubelet 授权审批 CSR 权限以创建新证书 (之前没创建过证书，通过 bootstrap token 认证，在 `system:bootstrappers` 用户组):

``` bash
cat <<EOF | kubectl apply -f -
# Approve all CSRs for the group "system:bootstrappers"
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: auto-approve-csrs-for-group
subjects:
- kind: Group
  name: system:bootstrappers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:nodeclient
  apiGroup: rbac.authorization.k8s.io
EOF
```

给已启动过的 kubelet 授权审批 CSR 权限以更新证书 (之前创建过证书，通过证书认证，在 `system:nodes` 用户组):

``` bash
cat <<EOF | kubectl apply -f -
# Approve renewal CSRs for the group "system:nodes"
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: auto-approve-renewals-for-nodes
subjects:
- kind: Group
  name: system:nodes
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:selfnodeclient
  apiGroup: rbac.authorization.k8s.io
EOF
```

## 创建 Bootstrap Token

Bootstrap Token 以 Secret 形式存储，不需要给 apiserver 配置静态 token，这样也易于管理，下面是创建 Bootstrap Token 示例:

``` bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  # Name MUST be of form "bootstrap-token-<token id>", <token id> should match regex: [a-z0-9]{6}
  name: bootstrap-token-000000
  namespace: kube-system

# Type MUST be 'bootstrap.kubernetes.io/token'
type: bootstrap.kubernetes.io/token
stringData:
  # Human readable description. Optional.
  description: "The default bootstrap token used for signing certificates"

  # Token ID and secret. Required.
  token-id: "000000"
  token-secret: $(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')

  # Expiration. Optional.
  expiration: 2020-03-10T03:22:11Z

  # Allowed usages.
  usage-bootstrap-authentication: "true"
  usage-bootstrap-signing: "true"

  # Extra groups to authenticate the token as. Must start with "system:bootstrappers:"
  auth-extra-groups: system:bootstrappers:worker,system:bootstrappers:ingress
EOF
```

> bootstrap token 的 secret 格式参考: https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/#bootstrap-token-secret-format

查看 secret 是否创建成功:

``` bash
$ kubectl get secret -n kube-system bootstrap-token-000000
NAME                     TYPE                            DATA   AGE
bootstrap-token-000000   bootstrap.kubernetes.io/token   7      26s
```

## 创建 bootstrap-kubeconfig <a id="create-bootstrap-kubeconfig"></a>

上一步我们生成了 bootstrap token，这里我们使用它来创建 bootstrap-kubeconfig 以供后面部署 Worker 节点用 (kubelet 使用 bootstrap-kubeconfig 自动创建证书)

``` bash
APISERVER="https://10.200.16.79:6443"
TOKEN=$(kubectl -n kube-system get secret bootstrap-token-000000 -o=jsonpath='{.data.token-secret}' | base64 -d)

kubectl config --kubeconfig=bootstrap-kubeconfig set-cluster bootstrap --server="${APISERVER}" --certificate-authority=ca.pem --embed-certs=true
kubectl config --kubeconfig=bootstrap-kubeconfig set-credentials kubelet-bootstrap --token=000000.${TOKEN}
kubectl config --kubeconfig=bootstrap-kubeconfig set-context bootstrap --user=kubelet-bootstrap --cluster=bootstrap
kubectl config --kubeconfig=bootstrap-kubeconfig use-context bootstrap
```

生成文件:

``` txt
bootstrap-kubeconfig
```
