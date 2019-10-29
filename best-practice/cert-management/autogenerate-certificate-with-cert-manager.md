# 使用 cert\-manager 自动生成证书

确保 `cert-manager` 已安装，参考 [安装 cert-manager](install-cert-manger.md)

## 利用 Let’s Encrypt 生成免费证书

### 免费证书颁发原理

Let’s Encrypt 利用 [ACME](https://tools.ietf.org/html/rfc8555) 协议来校验域名是否真的属于你，校验成功后就可以自动颁发免费证书，证书有效期只有 90 天，在到期前需要再校验一次来实现续期，幸运的是 cert-manager 可以自动续期，这样就可以使用永久免费的证书了。主流的两种校验方式是 HTTP-01 和 DNS-01，下面简单介绍下校验原理:

#### HTTP-01 校验原理

HTTP-01 的校验原理是给你域名指向的 HTTP 服务增加一个临时 location ，`Let’s Encrypt` 会发送 http 请求到 `http://<YOUR_DOMAIN>/.well-known/acme-challenge/<TOKEN>`，`YOUR_DOMAIN` 就是被校验的域名，`TOKEN` 是 ACME 协议的客户端负责放置的文件，在这里 ACME 客户端就是 cert-manager，它通过修改 Ingress 规则来增加这个临时校验路径并指向提供 `TOKEN` 的服务。`Let’s Encrypt` 会对比 `TOKEN` 是否符合预期，校验成功后就会颁发证书。此方法仅适用于给使用 Ingress 暴露流量的服务颁发证书，并且不支持泛域名证书。

#### DNS-01 校验原理

DNS-01 的校验原理是利用 DNS 提供商的 API Key 拿到你的 DNS 控制权限， 在 Let’s Encrypt 为 ACME 客户端提供令牌后，ACME 客户端 \(cert-manager\) 将创建从该令牌和您的帐户密钥派生的 TXT 记录，并将该记录放在 `_acme-challenge.<YOUR_DOMAIN>`。 然后 Let’s Encrypt 将向 DNS 系统查询该记录，如果找到匹配项，就可以颁发证书。此方法不需要你的服务使用 Ingress，并且支持泛域名证书。

### 创建颁发机构 \(ClusterIssuer/Issuer\)

我们需要先创建一个签发机构，cert-manager 给我们提供了 Issuer 和 ClusterIssuer 这两种用于创建签发机构的自定义资源对象，他们唯一区别就是 Issuer 只能用来签发自己所在 namespace 下的证书，ClusterIssuer 可以签发任意 namespace 下的证书，这里以 ClusterIssuer 为例，HTTP-01 和 DNS-01 校验都支持，假设域名是用 `cloudflare` 管理的，先登录 `cloudflare` 拿到 API Key，然后创建一个 Secret:

```bash
kubectl -n cert-manager create secret generic cloudflare-apikey --from-literal=apikey=213807bd0fb1ca59bba24a58eac90492e6287
```

* 由于 `ClusterIssuer` 是 NonNamespaced 类型的资源，不在任何命名空间，它需要引用 Secret，而 Secret 必须存在某个命名空间下，所以就规定 `ClusterIssuer` 引用的 Secret 要与 cert-manager 在同一个命名空间下。

下面来创建 `ClusterIssuer`:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
name: letsencrypt-prod
spec:
acme:
# The ACME server URL
server: https://acme-v02.api.letsencrypt.org/directory
# Email address used for ACME registration
email: roc@imroc.io
# Name of a secret used to store the ACME account private key
privateKeySecretRef:
name: letsencrypt-prod
# ACME DNS-01 provider configurations
dns01:
# Here we define a list of DNS-01 providers that can solve DNS challenges
providers:
  - name: cf-dns
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
* `acme.http01`: 这里指示签发机构支持使用 HTTP-01 的方式进行 acme 协议
* `acme.dns01`: 配置 DNS-01 校验方式所需的参数，最重要的是 API Key \(引用提前创建好的 Secret\)，不同 DNS 提供商配置不一样，具体参考官方API文档
* 更多字段参考 API 文档: [https://docs.cert-manager.io/en/latest/reference/api-docs/index.html\#clusterissuer-v1alpha1](https://docs.cert-manager.io/en/latest/reference/api-docs/index.html#clusterissuer-v1alpha1)

### 创建证书 \(Certificate\)

有了签发机构，接下来我们就可以生成免费证书了，cert-manager 给我们提供了 Certificate 这个用于生成证书的自定义资源对象，它必须局限在某一个 namespace 下，证书最终会在这个 namespace 下以 Secret 的资源对象存储，假如我想在 dashboard 这个 namespace 下生成免费证书（这个 namespace 已存在\)，创建一个 Certificate 资源来为我们自动生成证书，以 kubernetes dashboard 为例，分别示范下 HTTP-01 和 DNS-01 两种校验方式生成证书。

#### HTTP-01 方式

提前为服务创建好 Ingress:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: dashboard
  namespace: kubernetes-dashboard
spec:
  rules:
  - host: dashboard.imroc.io
    http:
      paths:
      - backend:
          serviceName: dashboard
          servicePort: 80
        path: /
EOF
```

检查 Ingress:

```bash
$ kubectl -n kube-system get ingress
NAME        HOSTS                ADDRESS          PORTS   AGE
dashboard   dashboard.imroc.io   150.109.28.133   80      19s
```

配置 DNS，将域名指向 Ingress 的 IP，然后创建 Certificate:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: dashboard-imroc-io
  namespace: kubernetes-dashboard
spec:
  secretName: dashboard-imroc-io-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - dashboard.imroc.io
  acme:
    config:
    - http01:
        ingress: dashboard
      domains:
      - dashboard.imroc.io
EOF
```

* `secretName`: 指示证书最终存到哪个 Secret 中
* `issuerRef.kind`: 值为 ClusterIssuer 说明签发机构不在本 namespace 下，而是在全局
* `issuerRef.name`: 我们创建的签发机构的名称 \(ClusterIssuer.metadata.name\)
* `dnsNames`: 指示该证书的可以用于哪些域名
* `acme.config.http01.ingress`: 使用 HTTP-01 方式校验该域名和机器时，指定后端服务所在 ingress 名称，cert-manager 会尝试修改该 ingress 规则，增加临时路径进行 ACME 协议的 HTTP-01 方式校验。如果你使用的 ingress controller 是所有 ingress 都用同一个入口 IP，比如 nginx ingress，这时你可以不用提前创建 ingress，只需要指定 `ingressClass` 就可以，cert-manager 会自动创建 ingress 包含 HTTP-01 临时校验路径，并指定 `kubernetes.io/ingress.class` 这个 annotation，然后你的 ingress controller 会自动根据该 ingress 更新转发规则，从而实现 ACME 协议的 HTTP-01 方式校验。
* `acme.config.http01.domains`: 指示该证书的可以用于哪些域名
* 更多字段参考 API 文档: [https://docs.cert-manager.io/en/latest/reference/api-docs/index.html\#certificate-v1alpha1](https://docs.cert-manager.io/en/latest/reference/api-docs/index.html#certificate-v1alpha1)

#### DNS-01 方式

```bash
cat <<EOF | kubectl apply -f -
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: dashboard-imroc-io
  namespace: kubernetes-dashboard
spec:
  secretName: kubernetes-dashboard-certs
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - dashboard.imroc.io
  acme:
    config:
    - dns01:
        provider: cf-dns
      domains:
      - dashboard.imroc.io
EOF
```

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

