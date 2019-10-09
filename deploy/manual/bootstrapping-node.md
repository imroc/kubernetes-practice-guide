# 部署 Node

## 安装

``` bash
wget -q --show-progress --https-only --timestamping \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64 \
  https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz \
  https://github.com/containerd/containerd/releases/download/v1.3.0/containerd-1.3.0.linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kubelet \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.16.0/crictl-v1.16.0-linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kubectl

chmod +x kube-proxy
cp kube-proxy /usr/local/bin/
```
