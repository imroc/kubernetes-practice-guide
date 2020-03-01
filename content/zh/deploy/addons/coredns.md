---
title: "部署 CoreDNS"
---

## 下载部署脚本

``` bash
$ git clone https://github.com/coredns/deployment.git
$ cd deployment/kubernetes
$ ls
CoreDNS-k8s_version.md  FAQs.md  README.md  Scaling_CoreDNS.md  Upgrading_CoreDNS.md  coredns.yaml.sed  corefile-tool  deploy.sh  migration  rollback.sh
```

## 部署脚本用法

查看 help:

``` bash
$ ./deploy.sh -h
usage: ./deploy.sh [ -r REVERSE-CIDR ] [ -i DNS-IP ] [ -d CLUSTER-DOMAIN ] [ -t YAML-TEMPLATE ]

    -r : Define a reverse zone for the given CIDR. You may specifcy this option more
         than once to add multiple reverse zones. If no reverse CIDRs are defined,
         then the default is to handle all reverse zones (i.e. in-addr.arpa and ip6.arpa)
    -i : Specify the cluster DNS IP address. If not specificed, the IP address of
         the existing "kube-dns" service is used, if present.
    -s : Skips the translation of kube-dns configmap to the corresponding CoreDNS Corefile configuration.
```

## 部署

总体流程是我们使用 `deploy.sh` 生成 yaml 并保存成 `coredns.yaml` 文件并执行 `kubectl apply -f coredns.yaml` 进行部署 ，如果要卸载，执行 `kubectl delete -f coredns.yaml`。

`deploy.sh` 脚本依赖 `jq` 命令，所以先确保 `jq` 已安装:

``` bash
apt install -y jq
```

### 全新部署

如果集群中没有 kube-dns 或低版本 coredns，我们直接用 `-i` 参数指定集群 DNS 的 CLUSTER IP，这个 IP 是安装集群时就确定好的，示例:

``` bash
./deploy.sh -i 10.32.0.255 > coredns.yaml
kubectl apply -f coredns.yaml
```
