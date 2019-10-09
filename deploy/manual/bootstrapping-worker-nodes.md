# 部署 Worker 节点

Worker 节点会安装 kubelet 来管理容器，运行工作负载，安装 kube-proxy 来实现 service 转发。

> Master 节点也可以部署为 Worker 节点

## 下载安装二进制

下载二进制:

``` bash
wget -q --show-progress --https-only --timestamping \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64 \
  https://github.com/containerd/containerd/releases/download/v1.3.0/containerd-1.3.0.linux-amd64.tar.gz \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.16.0/crictl-v1.16.0-linux-amd64.tar.gz \
  https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kubelet \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kubectl

sudo mv runc.amd64 runc
```

安装二进制:

``` bash
chmod +x crictl kubectl kube-proxy kubelet runc
tar -xvf crictl-v1.16.0-linux-amd64.tar.gz
mkdir containerd
tar -xvf containerd-1.3.0.linux-amd64.tar.gz -C containerd
sudo cp crictl kubectl kube-proxy kubelet runc /usr/local/bin/
sudo cp containerd/bin/* /bin/
```

## 安装依赖

``` bash
sudo apt-get update
sudo apt-get -y install socat conntrack ipset
```

## 禁用 Swap

默认情况下，如果开启了 swap，kubelet 会启动失败，k8s 节点推荐禁用 swap。

验证一下是否开启:

``` bash
sudo swapon --show
```

如果输出不是空的说明开启了 swap，使用下面的命令禁用 swap:

``` bash
sudo swapoff -a
```

为了防止开机自动挂载 swap 分区，可以注释  /etc/fstab  中相应的条目:

``` bash
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

## 关闭 SELinux

关闭 SELinux，否则后续 K8S 挂载目录时可能报错  Permission denied：

``` bash
sudo setenforce 0
```

修改配置文件，永久生效:

``` bash
sudo sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
```

## 配置

准备目录:

``` bash
sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes
```

### 配置 CNI

将 kubelet 会调用的 CNI 二进制放入 `/opt/cni/bin`:

``` bash
sudo tar -xvf cni-plugins-linux-amd64-v0.8.2.tgz -C /opt/cni/bin/
```

### 配置 containerd

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

### 配置 kubelet

用 `node` 变量表示节点名称:

``` bash
node="10.200.16.79"
```

放入 [这里](prepare.md#generate-ca-cert) 创建好的 CA 证书与 [这里](bootstrapping-master.md#create-bootstrap-kubeconfig) 创建好的 bootstrap-kubeconfig:

``` bash
sudo cp ca.pem /var/lib/kubernetes/
sudo cp bootstrap-kubeconfig /var/lib/kubelet/
```

事先确定好集群 DNS 的 CLUSTER IP 地址，通常可以用 service 网段的最后一个可用 IP 地址:

``` bash
dns=10.32.0.255
```

创建 kubelet 启动配置 `config.yaml`:

``` bash
dns=10.32.0.255

cat <<EOF | sudo tee /var/lib/kubelet/config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "${dns}"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
rotateCertificates: true
serverTLSBootstrap: true
EOF
```

创建 systemd 配置 `kubelet.service`:

``` bash
node="10.200.16.79"

cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --hostname-override=${node} \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

## 启动

``` bash
sudo systemctl daemon-reload
sudo systemctl enable containerd kubelet kube-proxy
sudo systemctl start containerd kubelet kube-proxy
```

## 验证

配置好 kubectl，执行下 kubectl:

``` bash
$ kubectl get node
NAME           STATUS     ROLES    AGE   VERSION
10.200.16.79   NotReady   <none>   11m   v1.16.1
```

没有装网络插件，节点状态会是 `NotReady`，带 `node.kubernetes.io/not-ready:NoSchedule` 这个污点，默认是无法调度 Pod，网络插件通常以 Daemonset 部署，使用 hostNetwork，并且容忍这个污点。
