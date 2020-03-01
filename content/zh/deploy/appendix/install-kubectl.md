---
title: "安装 kubectl"
---

## 二进制安装

指定K8S版本与节点cpu架构:

``` bash
VERSION="v1.16.1"
ARCH="amd64"
```

下载安装:

``` bash
wget -q --show-progress --https-only --timestamping \
  https://storage.googleapis.com/kubernetes-release/release/${VERSION}/bin/linux/${ARCH}/kubectl

chmod +x kubectl
mv kubectl /usr/local/bin/
```
