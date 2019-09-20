# 安装 Helm

Helm 是 Kubernetes 的包管理器，可以帮我们简化 kubernetes 的操作，一键部署应用。假如你的机器上已经安装了 kubectl 并且能够操作集群，那么你就可以安装 Helm 了。当前最新稳定版是 V2，Helm V3 还未正式发布，下面分别说下安装方法。

## 安装 Helm V2

执行脚本安装 helm 客户端:

``` bash
$ curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  6737  100  6737    0     0  12491      0 --:--:-- --:--:-- --:--:-- 12475
Downloading https://kubernetes-helm.storage.googleapis.com/helm-v2.9.1-linux-amd64.tar.gz
Preparing to install into /usr/local/bin
helm installed into /usr/local/bin/helm
Run 'helm init' to configure helm.
```

查看客户端版本：

``` bash
$ helm version
Client: &version.Version{SemVer:"v2.9.1", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
```

安装 tiller 服务端到 kubernetes 集群：

``` bash
$ helm init
Creating /root/.helm
Creating /root/.helm/repository
Creating /root/.helm/repository/cache
Creating /root/.helm/repository/local
Creating /root/.helm/plugins
Creating /root/.helm/starters
Creating /root/.helm/cache/archive
Creating /root/.helm/repository/repositories.yaml
Adding stable repo with URL: https://kubernetes-charts.storage.googleapis.com
Adding local repo with URL: http://127.0.0.1:8879/charts
$HELM_HOME has been configured at /root/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
Happy Helming!
```

查看 tiller 是否启动成功:

``` bash
$ kubectl get pods --namespace=kube-system | grep tiller
tiller-deploy-dccdb6fd9-2df4r          0/1       ImagePullBackOff   0          14h
```

如果状态是 ImagePullBackOff ，说明是镜像问题，一般是未拉取到镜像（国内机器拉取不到 gcr.io 下的镜像) 可以查看下是什么镜像:

``` bash
$ kubectl describe pod tiller-deploy-dccdb6fd9-2df4r --namespace=kube-system
Events:
  Type     Reason   Age                   From                Message
  ----     ------   ----                  ----                -------
  Warning  Failed   36m (x5 over 12h)     kubelet, k8s-node1  Failed to pull image "gcr.io/kubernetes-helm/tiller:v2.9.1": rpc error: code = Unknown desc = Get https://gcr.io/v1/_ping: dial tcp 64.233.189.82:443: i/o timeout
  Normal   BackOff  11m (x3221 over 14h)  kubelet, k8s-node1  Back-off pulling image "gcr.io/kubernetes-helm/tiller:v2.9.1"
  Warning  Failed   6m (x3237 over 14h)   kubelet, k8s-node1  Error: ImagePullBackOff
  Warning  Failed   1m (x15 over 14h)     kubelet, k8s-node1  Failed to pull image "gcr.io/kubernetes-helm/tiller:v2.9.1": rpc error: code = Unknown desc = Get https://gcr.io/v1/_ping: dial tcp 64.233.188.82:443: i/o timeout
```

把这个没拉取到镜像想办法下载到这台机器上。当我们看到状态为 `Running` 说明 tiller 已经成功运行了:

``` bash
$ kubectl get pods -n kube-system | grep tiller
tiller-deploy-dccdb6fd9-2df4r                   1/1       Running   1          41d
```

默认安装的 tiller 权限很小，我们执行下面的脚本给它加最大权限，这样方便我们可以用 helm 部署应用到任意 namespace 下:

``` bash
kubectl create serviceaccount --namespace=kube-system tiller

kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

kubectl patch deploy --namespace=kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
```

更多参考官方文档: https://helm.sh/docs/using_helm/#quickstart-guide

## 安装 Helm V3

在 https://github.com/helm/helm/releases 找到对应系统的二进制包下载，比如下载 `v3.0.0-beta.3` 的 `linux amd64` 版:

``` bash
$ wget https://get.helm.sh/helm-v3.0.0-beta.3-linux-amd64.tar.gz
```

解压并移动到 `PATH` 下面:

``` bash
$ tar -zxvf helm-v3.0.0-beta.3-linux-amd64.tar.gz
linux-amd64/
linux-amd64/LICENSE
linux-amd64/helm
linux-amd64/README.md
$ cd linux-amd64/
$ ls
LICENSE  README.md  helm
$ mv helm /usr/local/bin/helm3
```
