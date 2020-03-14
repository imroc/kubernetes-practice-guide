---
title: "安装 cert-manager"
weight: 10
---

参考官方文档: [https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html](https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html)

介绍几种安装方式，不管是用哪种我们都先规划一下使用哪个命名空间，推荐使用 `cert-manger` 命名空间，如果使用其它的命名空间需要做些更改，会稍微有点麻烦，先创建好命名空间:

```bash
kubectl create namespace cert-manager
```

## 使用原生 yaml 资源安装

直接执行 `kubectl apply` 来安装:

```bash
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.13.1/cert-manager.yaml
```

> 使用 `kubectl v1.15.4` 及其以下的版本需要加上 `--validate=false`，否则会报错。

## 校验是否安装成功

检查 cert-manager 相关的 pod 是否启动成功:

``` bash
$ kubectl get pods --namespace cert-manager

NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-5c6866597-zw7kh               1/1     Running   0          2m
cert-manager-cainjector-577f6d9fd7-tr77l   1/1     Running   0          2m
cert-manager-webhook-787858fcdb-nlzsq      1/1     Running   0          2m
```
