---
title: "Flink on Kubernetes 方案"
weight: 20
state: Alpha
---


将 Flink 部署到 Kubernetes 有 Session Cluster、Job Cluster 和 Native Kubernetes 三种集群部署方案。

## Session Cluster

相当于将静态部署的 [Standalone Cluster](https://ci.apache.org/projects/flink/flink-docs-release-1.10/ops/deployment/cluster_setup.html) 容器化，TaskManager 与 JobManager 都以 Deployment 方式部署，可动态提交 Job，Job 处理能力主要取决于 TaskManager 的配置 (slot/cpu/memory) 与副本数 (replicas)，调整副本数可以动态扩容。这种方式也是比较常见和成熟的方式。

## Job Cluster

相当于给每一个独立的 Job 部署一整套 Flink 集群，这套集群就只能运行一个 Job，配备专门制作的 Job 镜像，不能动态提交其它 Job。这种模式可以让每种 Job 拥有专用的资源，独立扩容。

## Native Kubernetes

这种方式是与 Kubernetes 原生集成，相比前面两种，这种模式能做到动态向 Kubernetes 申请资源，不需要提前指定 TaskManager 数量，就像 flink 与 yarn 和 mesos 集成一样。此模式能够提高资源利用率，但还处于试验阶段，不够成熟，不建议部署到生产环境。

## 总结

TODO
