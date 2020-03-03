---
title: "Pod 相关脚本"
---


## 清理 Evicted 的 pod

``` bash
kubectl get pod -o wide --all-namespaces | awk '{if($4=="Evicted"){cmd="kubectl -n "$1" delete pod "$2; system(cmd)}}'
```

## 清理非 Running 的 pod

``` bash
kubectl get pod -o wide --all-namespaces | awk '{if($4!="Running"){cmd="kubectl -n "$1" delete pod "$2; system(cmd)}}'
```

## 升级镜像

``` bash
NAMESPACE="kube-system"
WORKLOAD_TYPE="daemonset"
WORKLOAD_NAME="ip-masq-agent"
CONTAINER_NAME="ip-masq-agent"
IMAGE="ccr.ccs.tencentyun.com/library/ip-masq-agent:v2.5.0"
```

``` bash
kubectl -n $NAMESPACE patch $WORKLOAD_TYPE $WORKLOAD_NAME --patch '{"spec": {"template": {"spec": {"containers": [{"name": "$CONTAINER_NAME","image": "$IMAGE" }]}}}}'
```