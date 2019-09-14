# 内存碎片化

## 内存碎片化造成的危害

节点的内存碎片化严重，导致docker运行容器时，无法分到大的内存块，导致start docker失败。最终导致服务更新时，状态一直都是启动中。

## 判断是否内存碎片化严重

内存页分配失败，内核日志报类似下面的错：

``` bash
mysqld: page allocation failure. order:4, mode:0x10c0d0
```

- `mysqld` 是被分配的内存的程序
- `order` 表示需要分配连续页的数量(2^order)，这里 4 表示 2^4=16 个连续的页
- `mode` 是内存分配模式的标识，定义在内核源码文件 `include/linux/gfp.h` 中，通常是多个标识相与运算的结果，不同版本内核可能不一样，比如在新版内核中 `GFP_KERNEL` 是 `__GFP_RECLAIM | __GFP_IO | __GFP_FS` 的运算结果，而 `__GFP_RECLAIM` 又是 `___GFP_DIRECT_RECLAIM|___GFP_KSWAPD_RECLAIM` 的运算结果

当 order 为 0 时，说明系统以及完全没有可用内存了，order 值比较大时，才说明内存碎片化了，无法分配连续的大页内存。

## 内存碎片化造成的问题

### 容器启动失败

Pod 状态一直在 ContainerCreating，dockerd 启动容器失败，日志报错:

``` log
Jan 23 14:15:31 dc05 dockerd: time="2019-01-23T14:15:31.288446233+08:00" level=error msg="containerd: start container" error="oci runtime error: container_linux.go:247: starting container process caused \"process_linux.go:245: running exec setns process for init caused \\\"exit status 6\\\"\"\n" id=5b9be8c5bb121264899fac8d9d36b02150269d41ce96ba6ad36d70b8640cb01c
Jan 23 14:15:31 dc05 dockerd: time="2019-01-23T14:15:31.317965799+08:00" level=error msg="Create container failed with error: invalid header field value \"oci runtime error: container_linux.go:247: starting container process caused \\\"process_linux.go:245: running exec setns process for init caused \\\\\\\"exit status 6\\\\\\\"\\\"\\n\""
```

kubelet 日志报错:

``` log
Jan 23 14:15:31 dc05 kubelet: E0123 14:15:31.352386   26037 remote_runtime.go:91] RunPodSandbox from runtime service failed: rpc error: code = 2 desc = failed to start sandbox container for pod "matchdataserver-1255064836-t4b2w": Error response from daemon: {"message":"invalid header field value \"oci runtime error: container_linux.go:247: starting container process caused \\\"process_linux.go:245: running exec setns process for init caused \\\\\\\"exit status 6\\\\\\\"\\\"\\n\""}
Jan 23 14:15:31 dc05 kubelet: E0123 14:15:31.352496   26037 kuberuntime_sandbox.go:54] CreatePodSandbox for pod "matchdataserver-1255064836-t4b2w_basic(485fd485-1ed6-11e9-8661-0a587f8021ea)" failed: rpc error: code = 2 desc = failed to start sandbox container for pod "matchdataserver-1255064836-t4b2w": Error response from daemon: {"message":"invalid header field value \"oci runtime error: container_linux.go:247: starting container process caused \\\"process_linux.go:245: running exec setns process for init caused \\\\\\\"exit status 6\\\\\\\"\\\"\\n\""}
Jan 23 14:15:31 dc05 kubelet: E0123 14:15:31.352518   26037 kuberuntime_manager.go:618] createPodSandbox for pod "matchdataserver-1255064836-t4b2w_basic(485fd485-1ed6-11e9-8661-0a587f8021ea)" failed: rpc error: code = 2 desc = failed to start sandbox container for pod "matchdataserver-1255064836-t4b2w": Error response from daemon: {"message":"invalid header field value \"oci runtime error: container_linux.go:247: starting container process caused \\\"process_linux.go:245: running exec setns process for init caused \\\\\\\"exit status 6\\\\\\\"\\\"\\n\""}
Jan 23 14:15:31 dc05 kubelet: E0123 14:15:31.352580   26037 pod_workers.go:182] Error syncing pod 485fd485-1ed6-11e9-8661-0a587f8021ea ("matchdataserver-1255064836-t4b2w_basic(485fd485-1ed6-11e9-8661-0a587f8021ea)"), skipping: failed to "CreatePodSandbox" for "matchdataserver-1255064836-t4b2w_basic(485fd485-1ed6-11e9-8661-0a587f8021ea)" with CreatePodSandboxError: "CreatePodSandbox for pod \"matchdataserver-1255064836-t4b2w_basic(485fd485-1ed6-11e9-8661-0a587f8021ea)\" failed: rpc error: code = 2 desc = failed to start sandbox container for pod \"matchdataserver-1255064836-t4b2w\": Error response from daemon: {\"message\":\"invalid header field value \\\"oci runtime error: container_linux.go:247: starting container process caused \\\\\\\"process_linux.go:245: running exec setns process for init caused \\\\\\\\\\\\\\\"exit status 6\\\\\\\\\\\\\\\"\\\\\\\"\\\\n\\\"\"}"
Jan 23 14:15:31 dc05 kubelet: I0123 14:15:31.372181   26037 kubelet.go:1916] SyncLoop (PLEG): "matchdataserver-1255064836-t4b2w_basic(485fd485-1ed6-11e9-8661-0a587f8021ea)", event: &pleg.PodLifecycleEvent{ID:"485fd485-1ed6-11e9-8661-0a587f8021ea", Type:"ContainerDied", Data:"5b9be8c5bb121264899fac8d9d36b02150269d41ce96ba6ad36d70b8640cb01c"}
Jan 23 14:15:31 dc05 kubelet: W0123 14:15:31.372225   26037 pod_container_deletor.go:77] Container "5b9be8c5bb121264899fac8d9d36b02150269d41ce96ba6ad36d70b8640cb01c" not found in pod's containers
Jan 23 14:15:31 dc05 kubelet: I0123 14:15:31.678211   26037 kuberuntime_manager.go:383] No ready sandbox for pod "matchdataserver-1255064836-t4b2w_basic(485fd485-1ed6-11e9-8661-0a587f8021ea)" can be found. Need to start a new one
Jan 23 14:15:31 dc05 kubelet: I0123 14:15:31.678379   26037 kuberuntime_manager.go:457] Container {Name:matchdataserver Image:ccr.ccs.tencentyun.com/master/matchdataserver:latest Command:[] Args:[] WorkingDir:/data/go Ports:[] EnvFrom:[] Env:[{Name:PATH Value:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/data/go ValueFrom:nil} {Name:TXAPI_SECRETID Value:AKIDCKH2byR8wXw9Azr5LRN9mEWcWEm8uI4k ValueFrom:nil} {Name:TXAPI_SECRETKEY Value:c2JQjtrdGhvzqVyELI3e6MQIzUntnYBb ValueFrom:nil} {Name:DOCKER_CLUSTERID Value:cls-dig67c2j ValueFrom:nil}] Resources:{Limits:map[memory:{i:{value:536870912 scale:0} d:{Dec:<nil>} s: Format:BinarySI} cpu:{i:{value:200 scale:-3} d:{Dec:<nil>} s:200m Format:DecimalSI}] Requests:map[cpu:{i:{value:100 scale:-3} d:{Dec:<nil>} s:100m Format:DecimalSI} memory:{i:{value:268435456 scale:0} d:{Dec:<nil>} s: Format:BinarySI}]} VolumeMounts:[{Name:default-token-8svbr ReadOnly:true MountPath:/var/run/secrets/kubernetes.io/serviceaccount SubPath:}] LivenessProbe:nil ReadinessProbe:nil Lifecycle:nil TerminationMessagePath:/dev/termination-log TerminationMessagePolicy:File ImagePullPolicy:Always SecurityContext:&SecurityContext{Capabilities:nil,Privileged:*false,SELinuxOptions:nil,RunAsUser:nil,RunAsNonRoot:nil,ReadOnlyRootFilesystem:nil,} Stdin:false StdinOnce:false TTY:false} is dead, but RestartPolicy says that we should restart it.
Jan 23 14:15:32 dc05 dockerd: time="2019-01-23T14:15:32.773566669+08:00" level=error msg="Handler for POST /v1.24/containers/5b9be8c5bb121264899fac8d9d36b02150269d41ce96ba6ad36d70b8640cb01c/stop returned error: Container 5b9be8c5bb121264899fac8d9d36b02150269d41ce96ba6ad36d70b8640cb01c is already stopped"
```

内核日志还能看到无法分配 slab cache:

``` bash
Unable to to create nf_conn slab cache
```

进一步查看的系统内存(cache多可能是io导致的，为了提高io效率留下的缓存，这部分内存实际是可以释放的)：

``` bash
$ free
              total        used        free      shared  buff/cache   available
Mem:        8043944     1671472      417340        5468     5955132     5676872
```

查看slab (后面的0多表示伙伴系统没有大块内存了)：

``` bash
$ cat /proc/buddyinfo
Node 0, zone      DMA      1      0      1      0      2      1      1      0      1      1      3
Node 0, zone    DMA32   2725    624    489    178      0      0      0      0      0      0      0
Node 0, zone   Normal   1163   1101    932    222      0      0      0      0      0      0      0
```

### 系统 OOM

``` bash
SLUB: Unable to allocate memory on node -1 (gfp=0x2000000)
```

## 解决方法

- 周期性地或者在发现大块内存不足时，先进行drop_cache操作:

``` bash
echo 3 > /proc/sys/vm/drop_caches
```

- 必要时候进行内存整理，开销会比较大，会造成业务卡住一段时间(慎用):

``` bash
echo 1 > /proc/sys/vm/compact_memory
```

## 如何防止内存碎片化

TODO

## 附录

相关链接：

- https://www.lijiaocn.com/%E9%97%AE%E9%A2%98/2017/11/13/problem-unable-create-nf-conn.html
- https://blog.csdn.net/wqhlmark64/article/details/79143975
- https://huataihuang.gitbooks.io/cloud-atlas/content/os/linux/kernel/memory/drop_caches_and_compact_memory.html
