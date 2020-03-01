---
title: "安装 containerd"
---

## 二进制部署 <a id="binary"></a>

下载二进制:

``` bash
wget -q --show-progress --https-only --timestamping \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64 \
  https://github.com/containerd/containerd/releases/download/v1.3.0/containerd-1.3.0.linux-amd64.tar.gz \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.16.1/crictl-v1.16.1-linux-amd64.tar.gz

sudo mv runc.amd64 runc
```

安装二进制:

``` bash
tar -xvf crictl-v1.16.1-linux-amd64.tar.gz
chmod +x crictl runc
sudo cp crictl runc /usr/local/bin/

mkdir containerd
tar -xvf containerd-1.3.0.linux-amd64.tar.gz -C containerd
sudo cp containerd/bin/* /bin/
```

创建 containerd 启动配置 `config.toml`:

``` bash
sudo mkdir -p /etc/containerd/
cat << EOF | sudo tee /etc/containerd/config.toml
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
EOF
```

创建 systemd 配置 `containerd.service`:

``` bash
cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF
```

启动:

``` bash
sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl start containerd
```

配置 crictl (方便后面使用 crictl 管理与调试 containerd 的容器与镜像):

``` bash
crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
```
