---
title: "使用 cert-manager 自动生成证书"
weight: 20
---

确保 `cert-manager` 已安装，参考 [安装 cert-manager](../install-cert-manger/)

## 利用 Let’s Encrypt 生成免费证书

### 免费证书颁发原理

Let’s Encrypt 利用 [ACME](https://tools.ietf.org/html/rfc8555) 协议来校验域名是否真的属于你，校验成功后就可以自动颁发免费证书，证书有效期只有 90 天，在到期前需要再校验一次来实现续期，幸运的是 cert-manager 可以自动续期，这样就可以使用永久免费的证书了。如何校验你对这个域名属于你呢？主流的两种校验方式是 HTTP-01 和 DNS-01，下面简单介绍下校验原理:

#### HTTP-01 校验原理

HTTP-01 的校验原理是给你域名指向的 HTTP 服务增加一个临时 location ，`Let’s Encrypt` 会发送 http 请求到 `http://<YOUR_DOMAIN>/.well-known/acme-challenge/<TOKEN>`，`YOUR_DOMAIN` 就是被校验的域名，`TOKEN` 是 ACME 协议的客户端负责放置的文件，在这里 ACME 客户端就是 cert-manager，它通过修改 Ingress 规则来增加这个临时校验路径并指向提供 `TOKEN` 的服务。`Let’s Encrypt` 会对比 `TOKEN` 是否符合预期，校验成功后就会颁发证书。此方法仅适用于给使用 Ingress 暴露流量的服务颁发证书，并且不支持泛域名证书。

#### DNS-01 校验原理

DNS-01 的校验原理是利用 DNS 提供商的 API Key 拿到你的 DNS 控制权限， 在 Let’s Encrypt 为 ACME 客户端提供令牌后，ACME 客户端 \(cert-manager\) 将创建从该令牌和您的帐户密钥派生的 TXT 记录，并将该记录放在 `_acme-challenge.<YOUR_DOMAIN>`。 然后 Let’s Encrypt 将向 DNS 系统查询该记录，如果找到匹配项，就可以颁发证书。此方法不需要你的服务使用 Ingress，并且支持泛域名证书。

### 创建 Issuer/ClusterIssuer

我们需要先创建一个用于签发证书的 Issuer 或 ClusterIssuer，它们唯一区别就是 Issuer 只能用来签发自己所在 namespace 下的证书，ClusterIssuer 可以签发任意 namespace 下的证书，除了名称不同之外，两者所有字段完全一致，下面给出一些示例，简单起见，我们仅以 ClusterIssuer 为例。

#### 创建使用 DNS-01 校验的 ClusterIssuer

假设域名是用 `cloudflare` 管理的，先登录 `cloudflare` 拿到 API Key，然后创建一个 Secret:

```bash
kubectl -n cert-manager create secret generic cloudflare-apikey --from-literal=apikey=213807bdxxxxxxxxxxxxxx58eac90492e6287
```

> 由于 `ClusterIssuer` 是 NonNamespaced 类型的资源，不在任何命名空间，它需要引用 Secret，而 Secret 必须存在某个命名空间下，所以就规定 `ClusterIssuer` 引用的 Secret 要与 cert-manager 在同一个命名空间下。

创建 DNS-01 方式校验的 `ClusterIssuer`:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns01
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: roc@imroc.io
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-dns01
    solvers:
    - selector: {} # An empty 'selector' means that this solver matches all domains
      dns01: # ACME DNS-01 solver configurations
        cloudflare:
          email: roc@imroc.io
          # A secretKeyRef to a cloudflare api key
          apiKeySecretRef:
            name: cloudflare-apikey
            key: apikey
EOF
```

* `metadata.name`: 是我们创建的签发机构的名称，后面我们创建证书的时候会引用它
* `acme.email`: 是你自己的邮箱，证书快过期的时候会有邮件提醒，不过 cert-manager 会利用 acme 协议自动给我们重新颁发证书来续期
* `acme.server`: 是 acme 协议的服务端，我们这里用 Let’s Encrypt，这个地址就写死成这样就行
* `acme.privateKeySecretRef` 指示此签发机构的私钥将要存储到哪个 Secret 中，在 cert-manager 所在命名空间
* `solvers.dns01`: 配置 DNS-01 校验方式所需的参数，最重要的是 API Key \(引用提前创建好的 Secret\)，不同 DNS 提供商配置不一样，具体参考官方API文档
* 更多字段参考 API 文档: https://docs.cert-manager.io/en/latest/reference/api-docs/index.html\#clusterissuer-v1alpha2

#### 创建使用 HTTP-01 校验的 `ClusterIssuer`

使用 HTTP-01 方式校验，ACME 服务端 (Let's Encrypt) 会向客户端 (cert-manager) 提供令牌，客户端会在 web server 上特定路径上放置一个文件，该文件包含令牌以及帐户密钥的指纹。ACME 服务端会请求该路径并校验文件内容，校验成功后就会签发免费证书，更多细节参考: https://letsencrypt.org/zh-cn/docs/challenge-types/

有个问题，ACME 服务端通过什么地址去访问 ACME 客户端的 web server 校验域名？答案是通过将被签发的证书中的域名来访问。这个机制带来的问题是:

1. 不能签发泛域名证书，因为如果是泛域名，没有具体域名，ACME 服务端就不能知道该用什么地址访问 web server 去校验文件。
2. 域名需要提前在 DNS 提供商配置好，这样 ACME 服务端通过域名请求时解析到正确 IP 才能访问成功，也就是需要提前知道你的 web server 的 IP 是什么。

cert-manager 作为 ACME 客户端，它将这个要被 ACME 服务端校验的文件通过 Ingress 来暴露，我们需要提前知道 Ingress 对外的 IP 地址是多少，这样才好配置域名。

一些云厂商自带的 ingress controller 会给每个 Ingress 都创建一个外部地址 (通常对应一个负载均衡器)，这个时候我们需要提前创建好一个 Ingress，拿到外部 IP 并配置域名到此 IP，ACME 客户端 (cert-manager) 修改此 Ingress 的 rules，临时增加一个路径指向 cert-manager 提供的文件，ACME 服务端请求这个域名+指定路径，根据 Ingress 规则转发会返回 cert-manger 提供的这个文件，最终 ACME 服务端 (Let's Encrypt) 校验该文件，通过后签发免费证书。

指定 Ingress 的创建 `ClusterIssuer` 的示例:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-http01
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: roc@imroc.io
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-http01
    solvers:
    - selector: {} # An empty 'selector' means that this solver matches all domains
      http01: # ACME HTTP-01 solver configurations
        ingress:
          name: challenge
EOF
```

* `solvers.http01`: 配置 HTTP-01 校验方式所需的参数，`ingress.name` 指定提前创建好的 ingress 名称

有些自己安装的 ingress controller，所有具有相同 ingress class 的 ingress 都共用一个流量入口，通常是用 LoadBalancer 类型的 Service 暴露 ingress controller，这些具有相同 ingress class 的 ingress 的外部 IP 都是这个 Service 的外部 IP。这种情况我们创建 `ClusterIssuer` 时可以指定 ingress class，校验证书时，cert-manager 会直接创建新的 Ingress 资源并指定 `kubernetes.io/ingress.class` 这个 annotation。

指定 ingress class 的创建 `ClusterIssuer` 的示例:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-http01
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: roc@imroc.io
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-http01
    solvers:
    - selector: {} # An empty 'selector' means that this solver matches all domains
      http01: # ACME HTTP-01 solver configurations
        ingress:
          class: nginx
EOF
```

* `solvers.http01`: 配置 HTTP-01 校验方式所需的参数，`ingress.class` 指定 ingress class 名称

### 创建证书 \(Certificate\)

有了 Issuer/ClusterIssuer，接下来我们就可以生成免费证书了，cert-manager 给我们提供了 Certificate 这个用于生成证书的自定义资源对象，它必须局限在某一个 namespace 下，证书最终会在这个 namespace 下以 Secret 的资源对象存储，假如我想在 dashboard 这个 namespace 下生成免费证书（这个 namespace 已存在\)，创建一个 Certificate 资源来为我们自动生成证书，示例:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: dashboard-imroc-io
  namespace: kubernetes-dashboard
spec:
  secretName: dashboard-imroc-io-tls
  issuerRef:
    name: letsencrypt-dns01
    kind: ClusterIssuer
  dnsNames:
  - dashboard.imroc.io
EOF
```

* `secretName`: 指示证书最终存到哪个 Secret 中
* `issuerRef.kind`: ClusterIssuer 或 Issuer，ClusterIssuer 可以被任意 namespace 的 Certificate 引用，Issuer 只能被当前 namespace 的 Certificate 引用。
* `issuerRef.name`: 引用我们创建的 Issuer/ClusterIssuer 的名称
* `commonName`: 对应证书的 common name 字段
* `dnsNames`: 对应证书的 Subject Alternative Names (SANs) 字段

#### 检查结果

创建完成等待一段时间，校验成功颁发证书后会将证书信息写入 Certificate 所在命名空间的 `secretName` 指定的 Secret 中，其它应用需要证书就可以直接挂载该 Secret 了。

```text
Events:
  Type    Reason              Age   From          Message
  ----    ------              ----  ----          -------
  Normal  Generated           15s   cert-manager  Generated new private key
  Normal  GenerateSelfSigned  15s   cert-manager  Generated temporary self signed certificate
  Normal  OrderCreated        15s   cert-manager  Created Order resource "dashboard-imroc-io-780134401"
  Normal  OrderComplete       9s    cert-manager  Order "dashboard-imroc-io-780134401" completed successfully
  Normal  CertIssued          9s    cert-manager  Certificate issued successfully
```

看下我们的证书是否成功生成:

```bash
kubectl -n dashboard get secret kubernetes-dashboard-certs -o yaml
apiVersion: v1
data:
  ca.crt: null
  tls.crt: LS0***0tLQo=
  tls.key: LS0***0tCg==
kind: Secret
metadata:
  annotations:
    certmanager.k8s.io/alt-names: dashboard.imroc.io
    certmanager.k8s.io/certificate-name: dashboard-imroc-io
    certmanager.k8s.io/common-name: dashboard.imroc.io
    certmanager.k8s.io/ip-sans: ""
    certmanager.k8s.io/issuer-kind: ClusterIssuer
    certmanager.k8s.io/issuer-name: letsencrypt-prod
  creationTimestamp: 2019-09-19T13:53:55Z
  labels:
    certmanager.k8s.io/certificate-name: dashboard-imroc-io
  name: kubernetes-dashboard-certs
  namespace: dashboard
  resourceVersion: "5689447213"
  selfLink: /api/v1/namespaces/dashboard/secrets/kubernetes-dashboard-certs
  uid: ebfc4aec-dae4-11e9-89f7-be8690a7fdcf
type: kubernetes.io/tls
```

* `tls.crt` 就是颁发的证书
* `tls.key` 是证书密钥

将 secret 挂载到需要证书的应用，通常应用也要配置下证书路径。
