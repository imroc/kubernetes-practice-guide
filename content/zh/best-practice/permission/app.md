---
title: "控制应用权限"
---

不仅用户 (人) 可以操作集群，应用 (程序) 也可以操作集群，通过给 Pod 设置 Serivce Account 来对应用进行授权，如果不设置会默认配置一个 "default" 的 Service Account，几乎没有权限。

## 原理

创建 Pod 时，在 apiserver 中的 service account admission controller 检测 Pod 是否指定了 ServiceAccount，如果没有就自动设置一个 "default"，如果指定了会检测指定的 ServiceAccount 是否存在，不存在的话会拒绝该 Pod，存在话就将此 ServiceAccount 对应的 Secret 挂载到 Pod 中每个容器的 `/var/run/secrets/kubernetes.io/serviceaccount` 这个路径，这个 Secret 是 controller manager 中 token controller 去 watch ServiceAccount，为每个 ServiceAccount 生成对应的 token 类型的 Secret 得来的。

Pod 内的程序如果要调用 apiserver 接口操作集群，会使用 SDK，通常是 [client-go](https://github.com/kubernetes/client-go) ， SDK 使用 in-cluster 的方式调用 apiserver，从固定路径 `/var/run/secrets/kubernetes.io/serviceaccount` 读取认证配置信息去连 apiserver，从而实现认证，再结合 RBAC 配置可以实现权限控制。

## 使用 RBAC 细化应用权限

ServiceAccount 仅针对某个命名空间，所以 Pod 指定的 ServiceAccount 只能引用当前命名空间的 ServiceAccount 的，即便是 "default" 每个命名空间也都是相互独立的，下面给出几个 RBAC 定义示例。

`build-robot` 这个 ServiceAccount 可以读取 build 命名空间中 Pod 的信息和 log:

``` yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: build-robot
  namespace: build

---

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: build
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: build
subjects:
- kind: ServiceAccount
  name: build-robot
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

## 为 Pod 指定 ServiceAccount

示例:

``` yaml
apiVersion: v1
kind: Pod
metadata:
  name: build
  namespace: build
spec:
  containers:
  - image: imroc/build-robot:v1
    name: builder
  serviceAccountName: build-robot
```

## 为应用默认指定 imagePullSecrets <a id="set-default-image-pull-secrets"></a>

ServiceAccount 中也可以指定 imagePullSecrets，也就是只要给 Pod 指定了这个 ServiceAccount，就有对应的 imagePullSecrets，而如果不指定 ServiceAccount 会默认指定 "default"，我们可以给 "default" 这个 ServiceAccount 指定 imagePullSecrets 来实现给某个命名空间指定默认的 imagePullSecrets

创建 imagePullSecrets:

``` bash
kubectl create secret docker-registry <secret-name> --docker-server=<your-registry-server> --docker-username=<your-name> --docker-password=<your-password> --docker-email=<your-email> -n <namespace>
```

* `<secret-name>`: 是要创建的 imagePullSecrets 的名称
* `<namespace>`: 是要创建的 imagePullSecrets 所在命名空间
* `<your-registry-server>`: 是你的私有仓库的地址
* `<your-name>`: 是你的 Docker 用户名
* `<your-password>` 是你的 Docker 密码
* `<your-email>` 是你的 Docker 邮箱

指定默认 imagePullSecrets:

``` bash
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "<secret-name>"}]}' -n <namespace>
```

* `<secret-name>`: 是 ServiceAccount 要关联的 imagePullSecrets 的名称
* `<namespace>`: 是 ServiceAccount 所在的命名空间，跟 imagePullSecrets 在同一个命名空间

## 参考资料

* Configure Service Accounts for Pods: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
