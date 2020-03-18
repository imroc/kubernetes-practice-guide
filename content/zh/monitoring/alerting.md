---
title: "告警"
hidden: true
---

先将 alertmanager 配置文件 dump 下来:

``` bash
kubectl -n monitoring get secret alertmanager-main -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d > alertmanager-main.yaml
```

