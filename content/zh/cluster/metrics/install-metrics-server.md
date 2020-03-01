---
title: "安装 metrics server"
---

## 官方 yaml 安装

下载:

``` bash
git clone --depth 1 https://github.com/kubernetes-sigs/metrics-server.git
cd metrics-server
```

修改 `deploy/1.8+/metrics-server-deployment.yaml`，在 `args` 里增加 `--kubelet-insecure-tls` (防止 metrics server 访问 kubelet 采集指标时报证书问题 `x509: certificate signed by unknown authority`):

``` yaml
      containers:
      - name: metrics-server
        image: k8s.gcr.io/metrics-server-amd64:v0.3.6
        args:
          - --cert-dir=/tmp
          - --secure-port=4443
          - --kubelet-insecure-tls # 这里是新增的一行
```

安装:

``` bash
kubectl apply -f deploy/1.8+/
```

## 参考资料

* Github 主页: https://github.com/kubernetes-sigs/metrics-server
