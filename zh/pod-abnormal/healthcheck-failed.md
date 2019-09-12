# 健康检查失败

- Kubernetes 健康检查包含就绪检查(readinessProbe)和存活检查(livenessProbe)
- pod 如果就绪检查失败会将此 pod ip 从 service 中摘除，通过 service 访问，流量将不会被转发给就绪检查失败的 pod
- pod 如果存活检查失败，kubelet 将会杀死容器并尝试重启

健康检查失败的可能原因有多种，下面我们来逐个排查。

## 健康检查配置不合理

`initialDelaySeconds` 太短，容器启动慢，导致容器还没完全启动就开始探测，如果 successThreshold 是默认值 1，检查失败一次就会被 kill，然后 pod 一直这样被 kill 重启。

TODO

## 节点负载过高

cpu 占用高（比如跑满）会导致进程无法正常发包收包，通常会 timeout，导致 kubelet 认为 pod 不健康

TODO

## 容器进程被木马进程杀死

TODO