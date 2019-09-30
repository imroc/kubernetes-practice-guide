# 准备集群证书

## 安装 cfssl

``` bash
curl -L https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o cfssl
chmod +x cfssl
curl -L https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o cfssljson
chmod +x cfssljson
curl -L https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -o cfssl-certinfo
chmod +x cfssl-certinfo

mv cfssl cfssljson cfssl-certinfo /usr/local/bin/

```

## 生成 CA 证书

``` bash
cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "SiChuan",
      "L": "ChengDu",
      "O": "Kubernetes",
      "OU": "CA"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

将会生成以下两个重要文件:

* `ca-key.pem`: CA 证书密钥
* `ca.pem`: CA 证书

csr 文件字段解释:

* `CN`: `Common Name`，apiserver 从证书中提取该字段作为请求的用户名 (User Name)
* `Organization`，apiserver 从证书中提取该字段作为请求用户所属的组 (Group)

> 由于这里是 CA 证书，是签发其它证书的根证书，这个证书密钥不会分发出去作为 client 证书，所有组件使用的 client 证书都是由 CA 证书签发而来，所以 CA 证书的 CN 和 O 的名称并不重要，后续其它签发出来的证书的 CN 和 O 的名称才是有用的

有了 CA 证书，后面我们就需要使用 CA 证书来为其它组件和用户签发证书，签发时 cfssl 需要一份证书签发配置，我们准备一个配置文件 `ca-config.json` :

``` bash
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF
```

## 为 kube-apiserver 签发证书

kube-apiserver 是 k8s 的访问核心，所有 K8S 组件和用户 kubectl 操作都会请求 kube-apiserver，通常启用 tls 证书认证，证书里面需要包含 kube-apiserver 可能被访问的地址，这样 client 校验 kube-apiserver 证书时才会通过，集群内的 Pod 一般通过 kube-apiserver 的 Service 名称访问，可能的 Service 名称有:

* `kubernetes`
* `kubernetes.default`
* `kubernetes.default.svc`
* `kubernetes.default.svc.cluster`
* `kubernetes.default.svc.cluster.local`

通过集群外也可能访问 kube-apiserver，比如使用 kubectl，或者部署在集群外的服务会连 kube-apiserver (比如部署在集群外的 Promethues 采集集群指标做监控)，这里列一下通过集群外连 kube-apiserver 有哪些可能地址:

* `127.0.0.1`: 在 Master 所在机器通过 127.0.0.1 访问本机 kube-apiserver
* 域名: 配了 DNS，通过域名访问 kube-apiserver，也要将域名写入证书
* LB IP: 如果 Master 节点前面挂了一个负载均衡器，外界可以通过 LB IP 来访问 kube-apiserver
* Master 节点 IP: 如果没有 Master 负载均衡器，管理员在节点上执行 kubectl 通常使用 Master 节点 IP 访问 kube-apiserver

``` bash
cat > kubernetes-csr.json <<EOF
{
    "CN": "kubernetes",
    "hosts": [
      "127.0.0.1",
      "172.27.17.155",
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
```

> hosts 这里只准备了必要的，根据需求可增加，通常 Master 节点 IP 也都要加进去，你可以执行了上面的命令后再编辑一下 `kubernetes-csr.json`，将需要 hosts 都加进去。

生成证书:

``` bash
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes
```

会生成下面两个重要的文件:

* `kubernetes-key.pem`: kube-apiserver 证书密钥
* `kubernetes.pem`: kube-apiserver 证书

## 为管理员签发证书 <a id="for-admin"></a>

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

## 为 kubelet 签发证书 <a id="for-kubelet"></a>

``` bash
node="node1"
ip="172.27.17.155"
cat > ${node}-csr.json <<EOF
{
  "CN": "system:node:${node}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "SiChuan",
      "L": "Chengdu",
      "O": "system:nodes",
      "OU": "Kubelet"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  ${node}-csr.json | cfssljson -bare ${node}
```

* `node` 改为节点的名称，自己自己定，也可以直接写节点的 hostname
* `ip` 改为节点的内网 IP

假如 `host` 为 node1，将生成以下两个文件:

* `node1-key.pem`: kubelet 证书密钥
* `node1.pem`: kublet 证书

## 为 kube-controller-manager 签发证书

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

## 为 kube-proxy 签发证书

``` bash
cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "SiChuan",
      "L": "Chengdu",
      "O": "system:node-proxier",
      "OU": "Kube Proxy"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy

```

生成以下两个文件:

* `kube-proxy-key.pem`: kube-proxy 证书密钥
* `kube-proxy.pem`: kube-proxy 证书

## 为 kube-scheduler 签发证书

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

## 签发 Service Account 密钥对

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

## 参考资料

* https://kubernetes.io/docs/concepts/cluster-administration/certificates/#cfssl

