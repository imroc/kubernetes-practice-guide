# 集群权限控制

## 简单粗暴的最高权限

* 为了简单方便，通常我们使用 token 认证，在 `kubeconfig` 中配置的账号拥有集群最高权限的 token，可以做任何操作。
* 开启 token 认证的方法: `kube-apiserver` 启动参数 `--token-auth-file` 传一个 token 认证文件，比如: `--token-auth-file=/etc/kubernetes/known_tokens.csv`
* token 认证文件包含最高权限 token，比如: `wJmqmTMK7BMNOfC1YDmOVydboBdOPPWj,admin,admin,system:masters`

在 `kubeconfig` \(`~/.kube/config`\) 中配置 token:

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
- name: admin
  user:
    token: wJmqmTMK7BMNOfC1YDmOVydboBdOPPWj
```

## 使用 RBAC 细化用户权限

如果可以操作集群的人比较多，使用最高权限的 token 可能会比较危险，如果有人误操作或恶意操作，即使 apiserver 开启审计也无法知道是谁做的操作，所以最好控制下权限，分发不同的 `kubeconfig` 给不同的人，这个可以通过 RBAC 来实现\(确保 `kube-apiserver` 启动参数 `--authorization-mode` 包含 RBAC\)，基本思想是创建 ServiceAccount 绑定 Role 或 ClusterRole 来控制权限，拿到给 ServiceAccount 自动创建的 secret 中的 token 后 base64 解码再配置到 `kubeconfig` 中。

### RBAC 示例

给 roc 授权 test 命名空间所有权限，istio-system 命名空间的只读权限:

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

