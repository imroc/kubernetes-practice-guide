---
title: "手工部署"
chapter: true
weight: 20
---

## 部署详情

各组件版本:

* kubernetes 1.16.1
* containerd 1.3.0
* coredns v1.6.2
* cni v0.8.2
* flannel v0.11.0
* etcd v3.4.1

特点:

* kubelet 证书自动签发并轮转
* kube-proxy 以 daemonset 方式部署，无需为其手动签发管理证书
* 运行时没有 docker 直接使用 containerd，绕过 dockerd 的许多 bug

## 部署步骤

* [部署前的准备工作](/deploy/manual/prepare.md)
* [部署 ETCD](/deploy/manual/bootstrapping-etcd.md)
* [部署 Master](/deploy/manual/bootstrapping-master.md)
* [部署 Worker 节点](/deploy/manual/bootstrapping-worker-nodes.md)
* [部署关键附加组件](/deploy/manual/deploy-critical-addons.md)
