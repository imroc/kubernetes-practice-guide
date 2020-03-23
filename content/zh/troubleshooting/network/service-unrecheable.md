---
title: "Service 不通"
state: "Alpha"
---

## 集群 dns 故障

TODO

## 节点防火墙没放开集群容器网络 \(iptables/安全组\)

TODO

## kube-proxy 没有工作，命中 netlink deadlock 的 bug

* issue: https://github.com/kubernetes/kubernetes/issues/71071
* 1.14 版本已修复，修复的 PR: https://github.com/kubernetes/kubernetes/pull/72361
