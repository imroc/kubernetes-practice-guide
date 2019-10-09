# 准备二进制

## ETCD <a id="etcd"></a>

下载 release 包:

``` bash
wget -q --show-progress --https-only --timestamping \
  "https://github.com/etcd-io/etcd/releases/download/v3.4.1/etcd-v3.4.1-linux-amd64.tar.gz"
```


## Kubernetes <a id="kubernetes"></a>

下载 k8s 各个组件的二进制文件:

``` bash
wget -q --show-progress --https-only --timestamping \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kube-apiserver \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kube-controller-manager \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kube-scheduler \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kubelet \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kubectl
```

## 运行时

``` bash
wget -q --show-progress --https-only --timestamping \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64 \
  https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz \
  https://github.com/containerd/containerd/releases/download/v1.3.0/containerd-1.3.0.linux-amd64.tar.gz \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.16.0/crictl-v1.16.0-linux-amd64.tar.gz
```
