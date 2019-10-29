# 利用 CertificateSigningRequest 创建用户

k8s 支持 CSR API，通过创建 `CertificateSigningRequest` 资源就可以发起 CSR 请求，管理员审批通过之后 `kube-controller-manager` 就会为我们签发证书，确保 `kube-controller-manager` 配了根证书密钥对:

``` bash
--cluster-signing-cert-file=/var/lib/kubernetes/ca.pem
--cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem
```

## 创建步骤

下面讲解如何利用 CSR API 为集群创建用户，首先指定要创建的用户名:

``` bash
USERNAME="roc"
```

再创建 key 和 csr 文件:

``` bash
cat <<EOF | cfssl genkey - | cfssljson -bare ${USERNAME}
{
  "CN": "${USERNAME}",
  "key": {
    "algo": "rsa",
    "size": 2048
  }
}
EOF
```

生成以下文件:

```
roc.csr
roc-key.pem
```

创建 `CertificateSigningRequest`(发起 CSR 请求):

``` bash
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${USERNAME}
spec:
  request: $(cat ${USERNAME}.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - client auth
EOF
```

管理员审批 CSR 请求:

``` bash
kubectl certificate approve ${USERNAME}
```

获取证书:

``` bash
kubectl get csr ${USERNAME} -o jsonpath={.status.certificate} | base64 --decode > ${USERNAME}.pem
```

得到证书文件:

```
roc.pem
```

至此，我们已经创建好了用户，用户的证书密钥对文件:

```
roc.pem
roc-key.pem
```

## 配置 kubeconfig

``` bash
# 增加 user
kubectl config set-credentials ${USERNAME} --embed-certs=true --client-certificate=${USERNAME}.pem --client-key=${USERNAME}-key.pem

# 如果还没配 cluster，可以通过下面命令配一下
kubectl config set-cluster <cluster> --server=<apiserver-url> --certificate-authority=<ca-cert-file>

# 增加 context，绑定 cluster 和 user
kubectl config set-context <context> --cluster=<cluster> --user=${USERNAME}

# 使用刚增加的 context
kubectl config use-context <context>
```

## 配置用户权限

我们可以用 RBAC 控制用户权限，参考 [使用 RBAC 控制用户权限](user.md#rbac)

## 参考资料

* Manage TLS Certificates in a Cluster: https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/
