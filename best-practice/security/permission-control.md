# 集群权限控制

## 账户类型

K8S 主要有以下两种账户类型概念:

* 用户账户 \(`User`\): 控制人的权限。
* 服务账户 \(`ServiceAccount`\): 控制应用程序的权限

如果开启集群审计，就可以区分某个操作是哪个用户或哪个应程序执行的。

## 控制用户权限

### 简单粗暴的最高权限

为了简单方便，小集群或测试环境集群我们通常使用 token 认证，在 `kubeconfig` 中配置拥有集群最高权限账号的 token，可以做任何操作。

开启 token 认证的方法: `kube-apiserver` 启动参数 `--token-auth-file` 传一个 token 认证文件，比如: `--token-auth-file=/etc/kubernetes/known_tokens.csv` \(token 认证文件包含最高权限 token，比如: `wJmq****PPWj,admin,admin,system:masters`\)

在 `kubeconfig` \(`~/.kube/config`\) 中配置 token:

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0t****Cg==
    server: https://169.254.128.15:60002
  name: local
contexts:
- context:
    cluster: local
    user: admin
  name: master
current-context: master
kind: Config
preferences: {}
users:
- name: admin
  user:
    token: wJmk****PPWj
```

### 使用 RBAC 细化用户权限

使用最高权限 token 虽然简单方便，但是如果是重要的生产环境集群，可以操作集群的人比较多可能会比较危险，一旦有人误操作或故意搞事就可能酿成大错，即使 apiserver 开启审计也无法知道是谁做的操作，所以最好控制下权限，根据人的级别或角色创建拥有对应权限的账号，这个可以通过 RBAC 来实现\(确保 `kube-apiserver` 启动参数 `--authorization-mode=RBAC`\)，基本思想是创建 User 或 ServiceAccount 绑定 Role 或 fClusterRole 来控制权限，拿到给 User 自动创建的 secret 中的 token 后 base64 解码再配置到 `kubeconfig` 中。

通常用户的权限管理对象使用 User 而不是 ServiceAccount，但 K8S 不自带 User 管理，不能像 ServiceAccount 一样直接通过 API 动态创建， User 的动态管理依赖平台自身的支持，比如通过证书签发或认证服务器等机制来实现 User 的管理，如果嫌自己管理太麻烦，实际也可以直接用 ServiceAccount 来控制用户权限，只是如果开启审计看到的操作记录是服务账户而不是用户账户，并且注意如果 ServiceAccount 自身有了 Secret 读权限，那使用这个 ServiceAccount 的用户就可能能拿到其它更高权限的 ServiceAccount 的 token，通过替换自身 token 可以实现提权。

TODO: 优化

下面是 RBAC 示例:

#### 给 roc 授权 test 命名空间所有权限，istio-system 命名空间的只读权限:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: roc
  namespace: default

---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: admin
  namespace: test
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]

---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: admin-to-roc
  namespace: test
subjects:
  - kind: ServiceAccount
    name: roc
    namespace: default
roleRef:
  kind: Role
  name: admin
  apiGroup: rbac.authorization.k8s.io

---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: readonly
  namespace: istio-system
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list"]

---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: readonly-to-roc
subjects:
  - kind: ServiceAccount
    name: roc
    namespace: default
roleRef:
  kind: Role
  name: istio-system
  apiGroup: rbac.authorization.k8s.io
```

给 roc 授权整个集群的只读权限:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: roc
  namespace: kube-system

---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: readonly
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list"]

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: readonly-to-roc
subjects:
  - kind: ServiceAccount
    name: roc
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: readonly
  apiGroup: rbac.authorization.k8s.io
```

有几点说明下:

* ServiceAccount 本身在哪个命名空间并不重要
* 权限控制细节在于 Role 和 ClusterRole 的 rules

### 获取 Token

创建好了 ServiceAccount，我们来获取下它的 token:

```bash
$ kubectl get serviceaccount roc -n kube-system -o jsonpath='{.secrets[0].name}' | xargs kubectl get secret -n kube-system -o jsonpath='{.data.token}' | base64 -d
eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJyb2MtdG9rZW4teGR0ZzkiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoicm9jIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiZTAyMDM1M2YtOGQ4MC0xMWU5LTkyNDUtZDJhN2YzOWY0ODhkIiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50Omt1YmUtc3lzdGVtOnJvYyJ9.CQorLS_DZVsMuMNRCU39bob5l2PpgFk9ribeRxpqJTmEMbdDlmax66RXOVbBzFhPiPIrZ2xLySOkkFzTXiijHVTpF4v80FlmvNQoCTDKN8-FQ8132QKieATwAeQu01e2uPYo8f9Gb1ymoJbLVTqMNtzX-dij0bpVwxsk1SvdeyqEuSIjKsTwaUBxNml9X4Ba-fdaDf6jKmXONAGy3K89GqFkl3Aabxyc1eG4aCuJRaGBVeMTgZnp2yzhVpwXZkBPcw8wGhjonWr3xZp-iReXra-Ko2mqTQaoEZb87HHq43gF1lZGFng6xyoXKoQ0j_wx6p_T5U85hA-ZnrpSnR5K2Q
```

* 替换 `kube-system` 为 ServiceAccount 所在的命名空间
* 替换 `roc` 为 ServiceAccount 的名称

### 配置 kubeconfig

将 token 配到 `kubeconfig` 中:

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURaRENDQWt5Z0F3SUJBZ0lJQVhqdnpFVDBMcFF3RFFZSktvWklodmNOQVFFTEJRQXdVREVMTUFrR0ExVUUKQmhNQ1EwNHhLakFSQmdOVkJBb1RDblJsYm1ObGJuUjVkVzR3RlFZRFZRUUtFdzV6ZVhOMFpXMDZiV0Z6ZEdWeQpjekVWTUJNR0ExVUVBeE1NWTJ4ekxXRjJPVFZxZEdJeU1CNFhEVEU1TURReE9UQXpNRFl4TWxvWERUTTVNRFF4Ck9UQXpNRFl4TWxvd1VERUxNQWtHQTFVRUJoTUNRMDR4S2pBUkJnTlZCQW9UQ25SbGJtTmxiblI1ZFc0d0ZRWUQKVlFRS0V3NXplWE4wWlcwNmJXRnpkR1Z5Y3pFVk1CTUdBMVVFQXhNTVkyeHpMV0YyT1RWcWRHSXlNSUlCSWpBTgpCZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUF5bHRhNytQSVhTUk45ZUtrMUtCRG9hWjFRZ0YxCjBORG5tWFl5V3BTREZvb3JJN2V6eFVTQzNydVFiWk5MYXM0cDJTRE02U0ZyVEkzRHI4dUZETytUV2k0aFFQNTYKak1zUHBSTUdCZ29hNzV0bkRTanY4TkgwUitFak0vdmNxQ3hWc1hZeUFSZEZlVDZ0dEFNZU9IcGRpYk5yTEN3dgpPSzBBVnl4OFlpeHI2bFpSQ1BKMTEwcmlPVllGNlgzMVZhUmNMTmJ5d1lJWGdiWUdVTC9UZEZoUExGUDRpTU5BCnRtaWYzUG9tUnZUcDI3R3RFcUlicndVbUdNT3hGV25LTWo0dXlIcTlZS0phYjVlRGV3V1liZ2craW9HUVJwcG0KSVJXdUQ5RFVOaHVRL3RKWVBodVJ0VzY5c2FzVVRpSjNmaThDQmhSN1ZyVDZ1Z0ZKc2J3RlZYN3d2d0lEQVFBQgpvMEl3UURBT0JnTlZIUThCQWY4RUJBTUNBb1F3SFFZRFZSMGxCQll3RkFZSUt3WUJCUVVIQXdJR0NDc0dBUVVGCkJ3TUJNQThHQTFVZEV3RUIvd1FGTUFNQkFmOHdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBSXZxT1V0SGU1Zy8KdDJsMWM2UEFkdlgrWkRPdE04S0JyZEdZd2RQQVplSTU3WklOT2p6ZFprWG9hTmY0aXZCekxab1pYSmZ4b1NWLwoyVEQrSUM4TFN1S1JvMlh0Z1Z1WnRVb3htUitMYXdmUjZvSmFDT0xKRmdVemdlaTcwTHJiTWI1cUkrMUV1TnBaCkt0TTdRQmtDSG5UdFZzbGM0czJpeTZvMFJFSGpady9NV04xanE3V1QxYVpKUGMydlYxWmlReUpFM0xNT21QYksKSzhtdFBnZUxBcTN0KzRUanRkWGY4TEJBb3dxZDNLakpiMGF2QXNaSFpGNEg0azI1d0VneFFIaDNmUnU5eEdudgpPemt4eUd0NWh3RWg0QXVhcVMyRUlMRUxWTmlydmFKSzEzY2EwNldQSmdYNUlqWnlnNUtqbGxPU2RZWlpsYnR1CloydFRheXA3b3djPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    server: https://169.254.128.15:60002
  name: local
contexts:
- context:
    cluster: local
    user: admin
  name: master
current-context: master
kind: Config
preferences: {}
users:
- name: roc
  user:
    token: 'eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJyb2MtdG9rZW4teGR0ZzkiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoicm9jIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiZTAyMDM1M2YtOGQ4MC0xMWU5LTkyNDUtZDJhN2YzOWY0ODhkIiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50Omt1YmUtc3lzdGVtOnJvYyJ9.CQorLS_DZVsMuMNRCU39bob5l2PpgFk9ribeRxpqJTmEMbdDlmax66RXOVbBzFhPiPIrZ2xLySOkkFzTXiijHVTpF4v80FlmvNQoCTDKN8-FQ8132QKieATwAeQu01e2uPYo8f9Gb1ymoJbLVTqMNtzX-dij0bpVwxsk1SvdeyqEuSIjKsTwaUBxNml9X4Ba-fdaDf6jKmXONAGy3K89GqFkl3Aabxyc1eG4aCuJRaGBVeMTgZnp2yzhVpwXZkBPcw8wGhjonWr3xZp-iReXra-Ko2mqTQaoEZb87HHq43gF1lZGFng6xyoXKoQ0j_wx6p_T5U85hA-ZnrpSnR5K2Q'
```

或者用 kubectl 生成 kubeconfig:

```bash
# 配置user entry
kubectl config set-credentials <user> --token='<token>'
# 配置cluster entry
kubectl config set-cluster <cluster> --server=<apiserver-url> --certificate-authority=<ca-cert>
# 配置context entry
kubectl config set-context <context> --cluster=<cluster> --user=<user>
# 查看
kubectl config view
# 配置当前使用的context
kubectl config use-context <context>
```

## 控制应用权限

对于用户有用户账户 service acount

## 参考资料

* [https://kubernetes.io/zh/docs/reference/access-authn-authz/service-accounts-admin/](https://kubernetes.io/zh/docs/reference/access-authn-authz/service-accounts-admin/)
* [https://kubernetes.io/docs/reference/access-authn-authz/rbac/](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)

