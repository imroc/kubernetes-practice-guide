---
title: "使用 Traefik V2 让你的后台管理页面支持登录"
weight: 30
---

我们安装的应用，它们的后台管理页面很多不支持用户登录(认证)，所以没有将其暴露出来对外提供访问，我们经常用 kubectl proxy 的方式来访问，这样比较不方便。

这里以 Traefik 本身的后台管理页面为例，将其加上 basic auth 登录才允许访问。

创建用户名密码：

``` bash
USERNAME=roc
PASSWORD=mypassword
```

创建 Secret:

``` bash
USERS=$(htpasswd -nb USERNAME PASSWORD)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: authsecret
  namespace: kube-system
type: Opaque
stringData:
  users: ${USERS}
EOF
```

创建 Middleware:

``` bash
cat <<EOF | kubectl apply -f -
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: roc-auth
  namespace: kube-system
spec:
  basicAuth:
    secret: authsecret
EOF
```

创建 IngressRoute，引用 Middleware:

``` bash
cat <<EOF | kubectl apply -f -
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
  name: traefik-dashboard
  namespace: kube-system
spec:
  entryPoints:
  - websecure
  routes:
  - kind: Rule
    match: Host(`traefik.imroc.io`) && (PathPrefix(`/dashboard`) || PathPrefix(`/api`))
    services:
    - kind: TraefikService
      name: api@internal
    middlewares:
    - name: roc-auth
  tls:
    secretName: traefik-imroc-io-tls
EOF
```

打开浏览器，进入 traefik 后台管理页面： https://traefik.imroc.io/dashboard/，通常浏览器检测到401会自动弹出简单的登录框，我们输入用户名密码即可进入管理页面。
