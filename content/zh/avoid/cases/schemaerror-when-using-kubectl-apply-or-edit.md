---
title: "kubectl edit 或者 apply 报 SchemaError"
---

## 问题现象

kubectl edit 或 apply 资源报如下错误:

```
error: SchemaError(io.k8s.apimachinery.pkg.apis.meta.v1.APIGroup): invalid object doesn't have additional properties
```

集群版本：v1.10

## 排查过程

1. 使用 `kubectl apply -f tmp.yaml --dry-run -v8` 发现请求 `/openapi/v2` 这个 api 之后，kubectl在 validate 过程报错。
2. 换成 kubectl 1.12 之后没有再报错。
3. `kubectl get --raw '/openapi/v2'` 发现返回的 json 内容与正常集群有差异，刚开始返回的 json title 为 `Kubernetes metrics-server`，正常的是 Kubernetes。
4. 怀疑是 `metrics-server` 的问题，发现集群内确实安装了 k8s 官方的 `metrics-server`，询问得知之前是 0.3.1，后面升级为了 0.3.5。
5. 将 metrics-server 回滚之后恢复正常。

## 原因分析

初步怀疑，新版本的 metrics-server 使用了新的 openapi-generator，生成的 openapi 格式和之前 k8s 版本生成的有差异。导致旧版本的 kubectl 在解析 openapi 的 schema 时发生异常，查看代码发现1.10 和 1.12 版本在解析 openapi 的 schema 时，实现确实有差异。
