---
title: "Helm 常见问题"
weight: 4
---

##### helm 3 没有内置 stable repo

默认没有，可以手动添加:

``` bash
helm repo add stable https://kubernetes-charts.storage.googleapis.com
```

国内环境的可以用国内的 mirror:

``` bash
helm repo add stable https://apphub.aliyuncs.com/stable
```
