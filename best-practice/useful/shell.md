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

## 线程数排名统计

``` bash
printf "    NUM  PID\t\tCOMMAND\n" && ps -eLf | awk '{$1=null;$3=null;$4=null;$5=null;$6=null;$7=null;$8=null;$9=null;print}' | sort |uniq -c |sort -rn | head -10
```

示例输出:

``` bash
    NUM  PID		COMMAND
    594  14418        java -server -Dspring.profiles.active=production -Xms2048M -Xmx2048M -Xss256k -Dinfo.app.version=33 -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+PrintGCDateStamps -verbosegc -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=10011 -Xloggc:/home/log/gather-server/gather-server-gac.log -Ddefault.client.encoding=UTF-8 -Dfile.encoding=UTF-8 -Dlogging.path=/home/log/gather-server -Dserver.tomcat.accesslog.directory=/home/log/gather-server -jar /home/app/gather-server.jar --server.port=8080 --management.port=10086
    449  7088        java -server -Dspring.profiles.active=production -Dspring.cloud.config.token=nLfe-bQ0CcGnNZ_Q4Pt9KTizgRghZrGUVVqaDZYHU3R-Y_-U6k7jkm8RrBn7LPJD -Xms4256M -Xmx4256M -Xss256k -XX:+PrintFlagsFinal -XX:+UseG1GC -XX:+UseStringDeduplication -XX:MaxGCPauseMillis=200 -XX:MetaspaceSize=128M -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=10011 -verbosegc -XX:+PrintGCDateStamps -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=15 -XX:GCLogFileSize=50M -XX:AutoBoxCacheMax=520 -Xloggc:/home/log/oauth-server/oauth-server-gac.log -Dinfo.app.version=12 -Ddefault.client.encoding=UTF-8 -Dfile.encoding=UTF-8 -Dlogging.config=classpath:log4j2-spring-prod.xml -Dlogging.path=/home/log/oauth-server -Dserver.tomcat.accesslog.directory=/home/log/oauth-server -jar /home/app/oauth-server.jar --server.port=8080 --management.port=10086 --zuul.server.netty.threads.worker=14 --zuul.server.netty.socket.epoll=true
    394  516        java -server -Dspring.profiles.active=production -Xms2048M -Xmx2048M -Xss1024k -Dinfo.app.version=43 -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+PrintGCDateStamps -verbosegc -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=10011 -Xloggc:/home/log/asset-server/asset-server-gac.log -Ddefault.client.encoding=UTF-8 -Dfile.encoding=UTF-8 -Dlogging.path=/home/log/asset-server -Dserver.tomcat.accesslog.directory=/home/log/asset-server -jar /home/app/asset-server.jar --server.port=8080 --management.port=10086
    305  14668        java -server -Dspring.profiles.active=production -Xms1024M -Xmx1024M -Xss256k -Dinfo.app.version=3 -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+PrintGCDateStamps -verbosegc -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=10011 -Xloggc:/home/log/talent-adapter-distribute/talent-adapter-distribute-gac.log -Ddefault.client.encoding=UTF-8 -Dfile.encoding=UTF-8 -Dlogging.path=/home/log/talent-adapter-distribute -Dserver.tomcat.accesslog.directory=/home/log/talent-adapter-distribute -jar /home/app/talent-adapter-distribute.jar --server.port=8080 --management.port=10086
    250  3979        java -server -Dspring.profiles.active=production -Xms2048M -Xmx2048M -Xss256k -Dinfo.app.version=20 -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+PrintGCDateStamps -verbosegc -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=10011 -Xloggc:/home/log/uc-facade-server/uc-facade-server-gac.log -Ddefault.client.encoding=UTF-8 -Dfile.encoding=UTF-8 -Dlogging.path=/home/log/uc-facade-server -Dserver.tomcat.accesslog.directory=/home/log/uc-facade-server -jar /home/app/uc-facade-server.jar --server.port=8080 --management.port=10086
    246  12468        java -server -Dspring.profiles.active=production -Xms2048M -Xmx2048M -Xss256k -Dinfo.app.version=7 -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+PrintGCDateStamps -verbosegc -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=10011 -Xloggc:/home/log/talent-user-server/talent-user-server-gac.log -Ddefault.client.encoding=UTF-8 -Dfile.encoding=UTF-8 -Dlogging.path=/home/log/talent-user-server -Dserver.tomcat.accesslog.directory=/home/log/talent-user-server -jar /home/app/talent-user-server.jar --server.port=8080 --management.port=10086
    242  19401        java -server -Dspring.profiles.active=production -Xms1024M -Xmx1024M -Xss256k -Dinfo.app.version=25 -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+PrintGCDateStamps -verbosegc -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=10011 -Xloggc:/home/log/job-admin-server/job-admin-server-gac.log -Ddefault.client.encoding=UTF-8 -Dfile.encoding=UTF-8 -Dlogging.path=/home/log/job-admin-server -Dserver.tomcat.accesslog.directory=/home/log/job-admin-server -jar /home/app/job-admin-server.jar --server.port=8080 --management.port=10086
    213  539        java -server -Dspring.profiles.active=production -Xms512M -Xmx3072M -Xss256k -Dinfo.app.version=1 -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+PrintGCDateStamps -verbosegc -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=10011 -Xloggc:/home/log/family-aplus-web/family-aplus-web-gac.log -Ddefault.client.encoding=UTF-8 -Dfile.encoding=UTF-8 -Dlogging.path=/home/log/family-aplus-web -Dserver.tomcat.accesslog.directory=/home/log/family-aplus-web -jar /home/app/family-aplus-web.jar --server.port=8080 --management.port=10086
    187  9357        java -server -Dspring.profiles.active=production -Xms2048M -Xmx2048M -Xss256k -Dinfo.app.version=2 -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+PrintGCDateStamps -verbosegc -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=10011 -Xloggc:/home/log/orion-panel-server/orion-panel-server-gac.log -Ddefault.client.encoding=UTF-8 -Dfile.encoding=UTF-8 -Dlogging.path=/home/log/orion-panel-server -Dserver.tomcat.accesslog.directory=/home/log/orion-panel-server -jar /home/app/orion-panel-server.jar --server.port=8080 --management.port=10086
    181  14267        java -server -Dspring.profiles.active=production -Xms1024M -Xmx1024M -Xss256k -Dinfo.app.version=6 -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+PrintGCDateStamps -verbosegc -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=10011 -Xloggc:/home/log/talent-mission-server/talent-mission-server-gac.log -Ddefault.client.encoding=UTF-8 -Dfile.encoding=UTF-8 -Dlogging.path=/home/log/talent-mission-server -Dserver.tomcat.accesslog.directory=/home/log/talent-mission-server -jar /home/app/talent-mission-server.jar --server.port=8080 --management.port=10086
```

* 第一列表示线程数
* 第二列表示进程 PID
* 第三列是进程启动命令
