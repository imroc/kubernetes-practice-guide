---
title: "控制用户权限"
---

为了简单方便，小集群或测试环境集群我们通常使用最高权限的 admin 账号，可以做任何操作，但是如果是重要的生产环境集群，可以操作集群的人比较多，如果这时还用这个账号可能就会比较危险，一旦有人误操作或故意搞事就可能酿成大错，即使 apiserver 开启审计也无法知道是谁做的操作，所以最好控制下权限，根据人的级别或角色创建拥有对应权限的账号，这个可以通过 RBAC 来实现\(确保 `kube-apiserver` 启动参数 `--authorization-mode=RBAC`\)，基本思想是创建 User 或 ServiceAccount 绑定 Role 或 ClusterRole 来控制权限。

## User 来源

User 的来源有多种:

* token 文件: 给 `kube-apiserver` 启动参数 `--token-auth-file` 传一个 token 认证文件，比如: `--token-auth-file=/etc/kubernetes/known_tokens.csv`
  * token 文件每一行表示一个用户，示例: `wJmq****PPWj,admin,admin,system:masters`
  * 第一个字段是 token 的值，最后一个字段是用户组，token 认证用户名不重要，不会识别
* 证书: 通过使用 CA 证书给用户签发证书，签发的证书中 `CN` 字段是用户名，`O` 是用户组

## 使用 RBAC 控制用户权限 <a id="rbac"></a>

下面给出几个 RBAC 定义示例。

给 roc 授权 test 命名空间所有权限，istio-system 命名空间的只读权限:

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: admin
  namespace: test
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]

---

kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: admin-to-roc
  namespace: test
subjects:
  - kind: User
    name: roc
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: admin
  apiGroup: rbac.authorization.k8s.io

---

kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: readonly
  namespace: istio-system
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "watch", "list"]

---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: readonly-to-roc
  namespace: istio-system
subjects:
  - kind: User
    name: roc
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: readonly
  apiGroup: rbac.authorization.k8s.io
```

给 roc 授权整个集群的只读权限:

```yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: readonly
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "watch", "list"]

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: readonly-to-roc
subjects:
  - kind: User
    name: roc
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: readonly
  apiGroup: rbac.authorization.k8s.io
```

给 manager 用户组里所有用户授权 secret 读权限:

``` yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secret-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-secrets-global
subjects:
- kind: Group
  name: manager
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

## 配置 kubeconfig

```bash
# 如果使用证书认证，使用下面命令配置用户认证信息
kubectl config set-credentials <user> --embed-certs=true --client-certificate=<client-cert-file> --client-key=<client-key-file>

# 如果使用 token 认证，使用下面命令配置用户认证信息
# kubectl config set-credentials <user> --token='<token>'

# 配置cluster entry
kubectl config set-cluster <cluster> --server=<apiserver-url> --certificate-authority=<ca-cert-file>
# 配置context entry
kubectl config set-context <context> --cluster=<cluster> --user=<user>
# 配置当前使用的context
kubectl config use-context <context>
# 查看
kubectl config view
```

## 参考资料

* [https://kubernetes.io/zh/docs/reference/access-authn-authz/service-accounts-admin/](https://kubernetes.io/zh/docs/reference/access-authn-authz/service-accounts-admin/)
* [https://kubernetes.io/docs/reference/access-authn-authz/rbac/](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
