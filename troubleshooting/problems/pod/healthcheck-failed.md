# Pod 健康检查失败

* Kubernetes 健康检查包含就绪检查\(readinessProbe\)和存活检查\(livenessProbe\)
* pod 如果就绪检查失败会将此 pod ip 从 service 中摘除，通过 service 访问，流量将不会被转发给就绪检查失败的 pod
* pod 如果存活检查失败，kubelet 将会杀死容器并尝试重启

健康检查失败的可能原因有多种，下面我们来逐个排查。

## 健康检查配置不合理

`initialDelaySeconds` 太短，容器启动慢，导致容器还没完全启动就开始探测，如果 successThreshold 是默认值 1，检查失败一次就会被 kill，然后 pod 一直这样被 kill 重启。

## 节点负载过高

cpu 占用高（比如跑满）会导致进程无法正常发包收包，通常会 timeout，导致 kubelet 认为 pod 不健康。参考本书 [处理实践: 高负载](../../handle/high-load.md) 一节。

## 容器进程被木马进程杀死

参考本书 [处理实践: 使用 systemtap 定位疑难杂症](../../trick/use-systemtap-to-locate-problems.md) 进一步定位。

## 容器内进程端口监听挂掉

使用 `netstat -tunlp` 检查端口监听是否还在，如果不在了会直接 reset 掉健康检查探测的连接:

```bash
20:15:17.890996 IP 172.16.2.1.38074 > 172.16.2.23.8888: Flags [S], seq 96880261, win 14600, options [mss 1424,nop,nop,sackOK,nop,wscale 7], length 0
20:15:17.891021 IP 172.16.2.23.8888 > 172.16.2.1.38074: Flags [R.], seq 0, ack 96880262, win 0, length 0
20:15:17.906744 IP 10.0.0.16.54132 > 172.16.2.23.8888: Flags [S], seq 1207014342, win 14600, options [mss 1424,nop,nop,sackOK,nop,wscale 7], length 0
20:15:17.906766 IP 172.16.2.23.8888 > 10.0.0.16.54132: Flags [R.], seq 0, ack 1207014343, win 0, length 0
```

连接异常，从而健康检查失败
