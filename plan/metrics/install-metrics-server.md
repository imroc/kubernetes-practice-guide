# 安装 metrics server

## 官方 yaml 安装

``` bash
git clone --depth 1 https://github.com/kubernetes-sigs/metrics-server.git
cd metrics-server
kubectl apply -f deploy/1.8+/
```

## 参考资料

* Github 主页: https://github.com/kubernetes-sigs/metrics-server
