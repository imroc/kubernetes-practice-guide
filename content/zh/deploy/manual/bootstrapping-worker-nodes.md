---
title: "部署 Worker 节点"
weight: 4
---

Worker 节点主要安装 kubelet 来管理、运行工作负载 (Master 节点也可以部署为特殊 Worker 节点来部署关键服务)

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

## 准备目录

``` bash
sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kubernetes \
  /var/run/kubernetes
```

## 下载安装二进制

下载二进制:

``` bash
wget -q --show-progress --https-only --timestamping \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64 \
  https://github.com/containerd/containerd/releases/download/v1.3.0/containerd-1.3.0.linux-amd64.tar.gz \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.16.1/crictl-v1.16.1-linux-amd64.tar.gz \
  https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz \
  https://storage.googleapis.com/kubernetes-release/release/v1.16.1/bin/linux/amd64/kubelet

sudo mv runc.amd64 runc
```

安装二进制:

``` bash
chmod +x crictl kubelet runc
tar -xvf crictl-v1.16.1-linux-amd64.tar.gz
mkdir containerd
tar -xvf containerd-1.3.0.linux-amd64.tar.gz -C containerd
sudo cp crictl kubelet runc /usr/local/bin/
sudo cp containerd/bin/* /bin/
sudo tar -xvf cni-plugins-linux-amd64-v0.8.2.tgz -C /opt/cni/bin/
```

## 配置

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

放入 [这里](prepare.md#generate-ca-cert) 创建好的 CA 证书与 [这里](bootstrapping-master.md#create-bootstrap-kubeconfig) 创建好的 bootstrap-kubeconfig:

``` bash
sudo cp ca.pem /var/lib/kubernetes/
sudo cp bootstrap-kubeconfig /var/lib/kubelet/
```

事先确定好集群 DNS 的 CLUSTER IP 地址，通常可以用 service 网段的最后一个可用 IP 地址:

``` bash
DNS=10.32.0.255
```

创建 kubelet 启动配置 `config.yaml`:

``` bash
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
  - "${DNS}"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
rotateCertificates: true
serverTLSBootstrap: true
EOF
```

用 `NODE` 变量表示节点名称，kube-apiserver 所在节点需要能够通过这个名称访问到节点，这里推荐直接使用节点内网 IP，不需要配 hosts 就能访问:

``` bash
NODE="10.200.16.79"
```

创建 systemd 配置 `kubelet.service`:

``` bash
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
  --bootstrap-kubeconfig=/var/lib/kubelet/bootstrap-kubeconfig \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --hostname-override=${NODE} \\
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
sudo systemctl enable containerd kubelet
sudo systemctl start containerd kubelet
```

## 验证

配置好 kubectl，执行下 kubectl:

``` bash
$ kubectl get node
NAME           STATUS     ROLES    AGE   VERSION
10.200.16.79   NotReady   <none>   11m   v1.16.1
```

没有装网络插件，节点状态会是 `NotReady`，带 `node.kubernetes.io/not-ready:NoSchedule` 这个污点，默认是无法调度普通 Pod，这个是正常的。后面会装网络插件，通常以 Daemonset 部署，使用 hostNetwork，并且容忍这个污点。

## 签发 kubelet server 证书

由于之前做过 [RBAC 授权 kubelet 创建 CSR 与自动签发和更新证书](bootstrapping-master.md#authorize-kubelet-create-csr-and-auto-approval)，kubelet 启动时可以发起 client 与 server 证书的 CSR 请求，并自动审批通过 client 证书的 CSR 请求，kube-controller-manager 在自动执行证书签发，最后 kubelet 可以获取到 client 证书并加入集群，我们可以在 `/var/lib/kubelet/pki` 下面看到签发出来的 client 证书:

``` bash
ls -l /var/lib/kubelet/pki
total 4
-rw------- 1 root root 1277 Oct 10 20:46 kubelet-client-2019-10-10-20-46-23.pem
lrwxrwxrwx 1 root root   59 Oct 10 20:46 kubelet-client-current.pem -> /var/lib/kubelet/pki/kubelet-client-2019-10-10-20-46-23.pem
```

> kubeconfig 中引用这里的 `kubelet-client-current.pem` 这个证书，是一个指向证书 bundle 的软连接，包含证书公钥与私钥

但 server 证书默认无法自动审批，需要管理员人工审批，下面是审批方法，首先看下未审批的 CSR:

``` bash
$ kubectl get csr
NAME        AGE     REQUESTOR                  CONDITION
csr-6gkn6   2m4s    system:bootstrap:360483    Approved,Issued
csr-vf285   103s    system:node:10.200.17.6    Pending
```

> 可以看到 `system:bootstrap` 开头的用户的 CSR 请求已经自动 approve 并签发证书了，这就是因为 kubelet 使用 bootstrap token 认证后在 `system:bootstrappers` 用户组，而我们创建了对应 RBAC 为此用户组授权自动 approve CSR 的权限。下面 `system:node` 开头的用户的 CSR 请求状态是 Pending，需要管理员来 approve。

``` bash
$ kubectl certificate approve csr-vf285
certificatesigningrequest.certificates.k8s.io/csr-vf285 approved

$ ls -l /var/lib/kubelet/pki
total 8
-rw------- 1 root root 1277 Oct 10 20:46 kubelet-client-2019-10-10-20-46-23.pem
lrwxrwxrwx 1 root root   59 Oct 10 20:46 kubelet-client-current.pem -> /var/lib/kubelet/pki/kubelet-client-2019-10-10-20-46-23.pem
-rw------- 1 root root 1301 Oct 10 21:09 kubelet-server-2019-10-10-21-09-15.pem
lrwxrwxrwx 1 root root   59 Oct 10 21:09 kubelet-server-current.pem -> /var/lib/kubelet/pki/kubelet-server-2019-10-10-21-09-15.pem
```

> 和 client 证书一样，`kubelet-server-current.pem` 也是一个指向证书 bundle 的软连接，包含证书公钥与私钥，用与 kubelet 监听 10250 端口
