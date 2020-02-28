# Flink on Kubernetes

## Flink 简介

Flink 是一款近年来流行的流式大数据处理框架。Storm 是流式处理框架的先锋，实时处理能做到低延迟，但很难实现高吞吐，也不能保证精确一致性(exactly-once)，即保证执行一次并且只能执行一次；后基于批处理框架 Spark 推出 Spark Streaming，将批处理数据分割的足够小，也实现了流失处理，并且可以做到高吞吐，能实现 exactly-once，但难以做到低时延，因为分割的任务之间需要有间隔时间，无法做到真实时；最后 Flink 诞生了，同时做到了低延迟、高吞吐、exactly-once，并且还支持丰富的时间类型和窗口计算。

Flink 主要由两个部分组件构成：JobManager 和 TaskManager。如何理解这两个组件的作用？JobManager 负责资源申请和任务分发，TaskManager 负责任务的执行。跟 k8s 本身类比，JobManager 相当于 Master，TaskManager 相当于 Worker；跟 Spark 类比，JobManager 相当于 Driver，TaskManager 相当于 Executor。

## 与 Kubernetes 集成

在 flink 1.10 之前，在 k8s 上运行 flink 任务都是需要事先指定 TaskManager 的个数以及CPU和内存的，存在一个问题：大多数情况下，你在任务启动前根本无法精确的预估这个任务需要多少个TaskManager，如果指定多了，会导致资源浪费，指定少了，会导致任务调度不起来。本质原因是在 Kubernetes 上运行的 Flink 任务并没有直接向 Kubernetes 集群去申请资源。

在 2020-02-11 发布了 flink 1.10，该版本完成了与 k8s 集成的第一阶段，实现了向 k8s 动态申请资源，就像跟 yarn 或 mesos 集成那样。

确定部署的 namespace:

``` bash
NAMESPACE=flink
```

确保 namespace 已创建:

``` bash
kubectl create ns ${NAMESPACE}
```

创建 RBAC:

``` bash
kubectl create serviceaccount flink -n ${NAMESPACE}
kubectl create clusterrolebinding flink-role-binding-flink --clusterrole=edit --serviceaccount=${NAMESPACE}:flink
```

利用 job 运行启动 flink (自动请求 apiserver 创建 flink master 相关的资源):

``` yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: start-flink
  namespace: flink
spec:
  template:
    spec:
      serviceAccount: flink
      restartPolicy: OnFailure
      containers:
      - name: start
        image: flink:1.10
        workingDir: /opt/flink
        command: ["bash", "-c", "$FLINK_HOME/bin/kubernetes-session.sh \
          -Dkubernetes.cluster-id=roc \
          -Dtaskmanager.memory.process.size=1024m \
          -Dkubernetes.taskmanager.cpu=1 \
          -Dtaskmanager.numberOfTaskSlots=1 \
          -Dkubernetes.container.image=flink:1.10 \
          -Dkubernetes.namespace=flink"]
```

TODO

## 参考资料

* Active Kubernetes integration phase 2 - Advanced Features: https://issues.apache.org/jira/browse/FLINK-14460
* Apache Flink 1.10.0 Release Announcement: https://flink.apache.org/news/2020/02/11/release-1.10.0.html
* Native Kubernetes Setup Beta (flink与kubernetes集成的官方教程): https://ci.apache.org/projects/flink/flink-docs-release-1.10/ops/deployment/native_kubernetes.html