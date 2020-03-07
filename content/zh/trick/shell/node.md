---
title: "节点相关脚本"
---

## 表格输出各节点占用的 podCIDR

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

## 表格输出各节点总可用资源 (Allocatable)

``` bash
kubectl get no -o=custom-columns="NODE:.metadata.name,ALLOCATABLE CPU:.status.allocatable.cpu,ALLOCATABLE MEMORY:.status.allocatable.memory"
```

示例输出：

```
NODE       ALLOCATABLE CPU   ALLOCATABLE MEMORY
10.0.0.2   3920m             7051692Ki
10.0.0.3   3920m             7051816Ki
```

## 输出各节点已分配资源的情况

所有种类的资源已分配情况概览：

``` bash
kubectl get nodes --no-headers | awk '{print $1}' | xargs -I {} sh -c "echo {} ; kubectl describe node {} | grep Allocated -A 5 | grep -ve Event -ve Allocated -ve percent -ve --;"
```

示例输出:
```
10.0.0.2
  Resource           Requests          Limits
  cpu                3040m (77%)       19800m (505%)
  memory             4843402752 (67%)  15054901888 (208%)
10.0.0.3
  Resource           Requests   Limits
  cpu                300m (7%)  1 (25%)
  memory             250M (3%)  2G (27%)
```

表格输出 cpu 已分配情况:

``` bash
kubectl get nodes --no-headers | awk '{print $1}' | xargs -I {} sh -c 'echo -n "{}\t" ; kubectl describe node {} | grep Allocated -A 5 | grep -ve Event -ve Allocated -ve percent -ve -- | grep cpu | awk '\''{print $2$3}'\'';'
```

示例输出：

``` bash
10.0.0.2	3040m(77%)
10.0.0.3	300m(7%)
```

表格输出 memory 已分配情况:

``` bash
kubectl get nodes --no-headers | awk '{print $1}' | xargs -I {} sh -c 'echo -n "{}\t" ; kubectl describe node {} | grep Allocated -A 5 | grep -ve Event -ve Allocated -ve percent -ve -- | grep memory | awk '\''{print $2$3}'\'';'
```

示例输出：

``` bash
10.0.0.2	4843402752(67%)
10.0.0.3	250M(3%)
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
