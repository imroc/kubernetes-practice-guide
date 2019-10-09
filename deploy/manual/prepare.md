# 部署前的准备工作

## 准备节点

### 操作系统

使用 Linux 发行版，本教程主要以 Ubuntu 18.04 为例

### Master 节点

部署 K8S 控制面组件，推荐三台以上数量的机器

### ETCD 节点

部署 ETCD，可以跟 Master 节点用相同的机器，也可以用单独的机器，推荐三台以上数量的机器

### Worker 节点

实际运行工作负载的节点，Master 节点也可以作为 Worker 节点，可以通过 kubelet 参数 `--kube-reserved` 多预留一些资源给系统组件。

通常会给 Master 节点打标签，让关键的 Pod 跑在 Master 节点上，比如集群 DNS 服务。

## 准备客户端工具

我们需要用 `cfssl` 和 `kubectl` 来为各个组件生成证书和 kubeconfig，所以先将这两个工具在某个机器下载安装好。

### 安装 cfssl

``` bash
curl -L https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o cfssl
curl -L https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o cfssljson
curl -L https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -o cfssl-certinfo

chmod +x cfssl cfssljson cfssl-certinfo
sudo mv cfssl cfssljson cfssl-certinfo /usr/local/bin/
```

### 安装 kubectl

``` bash
wget -q --show-progress --https-only --timestamping \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kubectl

chmod +x kubectl
mv kubectl /usr/local/bin/
```

## 生成 CA 证书 <a id="generate-ca-cert"></a>

由于各个组件都需要配置证书，并且依赖 CA 证书来签发证书，所以我们首先要生成好 CA 证书以及后续的签发配置文件:

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