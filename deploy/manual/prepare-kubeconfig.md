# 准备 kubeconfig

`kubeconfig` 主要是用于各组件访问 apiserver 的必要配置，包含 apiserver 地址、client 证书与 CA 证书等信息。本文介绍为各个组件生成 `kubeconfig` 的方法。

所有组件都会去连 apiserver，所以首先需要确定你的 apiserver 访问入口的地址:

* 如果所有 master 组件都部署在一个节点，它们可以通过 127.0.0.1 这个 IP访问 apiserver。
* 如果 master 有多个节点，但 apiserver 只有一个实例，可以直接写 apiserver 所在机器的内网 IP 访问地址。
* 如果做了高可用，有多个 apiserver 实例，前面挂了负载均衡器，就可以写负载均衡器的访问地址。

这里我们用 `apiserver` 这个变量表示 apiserver 的访问地址，其它组件都需要配置这个地址，根据自身情况改下这个变量的值:

``` bash
apiserver="https://10.200.16.79:6443"
```

我们使用 `kubectl` 来辅助生成 kubeconfig，确保 kubectl 已安装

## kube-proxy

``` bash
apiserver="https://10.200.16.79:6443"

kubectl config set-cluster roc \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=${apiserver} \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=kube-proxy.pem \
  --client-key=kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=roc \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

```

生成文件:

``` txt
kube-proxy.kubeconfig
```

## kube-controller-manager

``` bash
apiserver="https://10.200.16.79:6443"

kubectl config set-cluster roc \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=${apiserver} \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=kube-controller-manager.pem \
  --client-key=kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=roc \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

```

生成文件:

``` txt
kube-controller-manager.kubeconfig
```

## kube-scheduler

``` bash
apiserver="https://10.200.16.79:6443"

kubectl config set-cluster roc \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=${apiserver} \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=kube-scheduler.pem \
  --client-key=kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context default \
  --cluster=roc \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig

```

生成文件:

``` txt
kube-scheduler.kubeconfig
```

## kubelet

``` bash
node="10.200.16.79"
apiserver="https://10.200.16.79:6443"

kubectl config set-cluster roc \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=${apiserver} \
  --kubeconfig=${node}.kubeconfig

kubectl config set-credentials system:node:${node} \
  --client-certificate=${node}.pem \
  --client-key=${node}-key.pem \
  --embed-certs=true \
  --kubeconfig=${node}.kubeconfig

kubectl config set-context default \
  --cluster=roc \
  --user=system:node:${node} \
  --kubeconfig=${node}.kubeconfig

kubectl config use-context default --kubeconfig=${node}.kubeconfig

```

* `node` 为节点的名称，在上一步 [准备证书](prepare-cluster-certs.md#for-kubelet) 中已确定，也保证 kubelet 证书公钥私钥文件在当前目录

生成文件:

``` txt
node1.kubeconfig
```

## 管理员

这里为管理员生成 kubeconfig，方便使用 kubectl 来管理集群:

``` bash
kubectl config set-cluster roc \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=${apiserver} \
  --kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig

kubectl config set-context default \
  --cluster=roc \
  --user=admin \
  --kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig

```

生成文件:

``` txt
admin.kubeconfig
```

> 可以将 `admin.kubeconfig` 放到 `~/.kube/config`，这是 kubectl 读取 kubeconfig 的默认路径，执行 kubectl 时就不需要指定 kubeconfig 路径了
