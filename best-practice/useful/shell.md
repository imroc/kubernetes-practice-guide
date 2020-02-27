# 实用命令与脚本

## 获取集群所有节点占用的 podCIDR

``` bash
kubectl get nodes --output=jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address} {.spec.podCIDR} {"\n"}{end}'
```

示例输出:

```
10.13.132.13 10.13.140.32/27
10.13.132.14 10.13.140.64/27
10.13.133.11 10.13.140.0/27
10.13.133.12 10.13.140.96/27
10.13.133.2 10.13.140.160/27
10.13.133.4 10.13.140.128/27
```

## 将节点信息输出成表格形式

``` bash
kubectl get no -o=custom-columns=INTERNAL-IP:.metadata.name,EXTERNAL-IP:.status.addresses[1].address,CIDR:.spec.podCIDR
```

示例输出:

```
INTERNAL-IP     EXTERNAL-IP       CIDR
10.100.12.194   152.136.146.157   10.101.64.64/27
10.100.16.11    10.100.16.11      10.101.66.224/27
10.100.16.24    10.100.16.24      10.101.64.32/27
10.100.16.26    10.100.16.26      10.101.65.0/27
10.100.16.37    10.100.16.37      10.101.64.0/27
```

## 不断尝试建立TCP连接测试网络连通性

``` bash
while true; do echo "" | telnet 10.0.0.3 443; sleep 0.1; done
```

* `ctrl+c` 终止测试
* 替换 `10.0.0.3` 与 `443` 为需要测试的 IP/域名 和端口

## 清理 Evicted 的 pod

``` bash
kubectl get pod -o wide --all-namespaces | awk '{if($4=="Evicted"){cmd="kubectl -n "$1" delete pod "$2; system(cmd)}}'
```

## 清理非 Running 的 pod

``` bash
kubectl get pod -o wide --all-namespaces | awk '{if($4!="Running"){cmd="kubectl -n "$1" delete pod "$2; system(cmd)}}'
```

## 进入容器 netns

粘贴脚本到命令行:

``` bash
function e() {
    set -eu
    ns=${2-"default"}
    pod=`kubectl -n $ns describe pod $1 | grep -A10 "^Containers:" | grep -Eo 'docker://.*$' | head -n 1 | sed 's/docker:\/\/\(.*\)$/\1/'`
    pid=`docker inspect -f {{.State.Pid}} $pod`
    echo "entering pod netns for $ns/$1"
    cmd="nsenter -n --target $pid"
    echo $cmd
    $cmd
}
```

进入在当前节点上运行的某个 pod 的 netns:

``` bash
# 进入 kube-system 命名空间下名为 metrics-server-6cf9685556-rclw5 的 pod 所在的 netns
e metrics-server-6cf9685556-rclw5 kube-system
```

进入 pod 的 netns 后就使用节点上的工具在该 netns 中做操作，比如用 `ip a` 查询网卡和ip、用 `ip route` 查询路由、用 tcpdump 抓容器内的包等。

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