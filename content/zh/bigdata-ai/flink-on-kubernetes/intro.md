---
title: "Flink 介绍"
weight: 10
---

## Flink 概述

Apache Flink 是一个面向数据流处理和批量数据处理的可分布式的开源计算框架，它基于同一个Flink流式执行模型（streaming execution model），能够同时支持流处理和批处理两种应用类型。

由于流处理和批处理所提供的SLA(服务等级协议)是完全不相同，流处理一般需要支持低延迟、Exactly-once保证，而批处理需要支持高吞吐、高效处理。所以在实现的时候通常是分别给出两套实现方法，或者通过一个独立的开源框架来实现其中每一种处理方案； 比如：实现批处理的开源方案有MapReduce、Spark，实现流处理的开源方案有Storm，Spark的Streaming 其实本质上也是微批处理。

Flink在实现流处理和批处理时，与传统的一些方案完全不同，它从另一个视角看待流处理和批处理，将二者统一起来：Flink是完全支持流处理，也就是说作为流处理看待时输入数据流是无界的；批处理被作为一种特殊的流处理，只是它的输入数据流被定义为有界的。

## 流式框架的演进

Storm 是流式处理框架的先锋，实时处理能做到低延迟，但很难实现高吞吐，也不能保证精确一致性(exactly-once)，即保证执行一次并且只能执行一次。

后基于批处理框架 Spark 推出 Spark Streaming，将批处理数据分割的足够小，也实现了流失处理，并且可以做到高吞吐，能实现 exactly-once，但难以做到低时延，因为分割的任务之间需要有间隔时间，无法做到真实时。

最后 Flink 诞生了，同时做到了低延迟、高吞吐、exactly-once，并且还支持丰富的时间类型和窗口计算。

## Flink 基本架构

### JobManager 与 TaskManager

Flink 主要由两个部分组件构成：JobManager 和 TaskManager。如何理解这两个组件的作用？JobManager 负责资源申请和任务分发，TaskManager 负责任务的执行。跟 k8s 本身类比，JobManager 相当于 Master，TaskManager 相当于 Worker；跟 Spark 类比，JobManager 相当于 Driver，TaskManager 相当于 Executor。

JobManager 负责整个 Flink 集群任务的调度以及资源的管理，从客户端获取提交的任务，然后根据集群中 TaskManager 上 TaskSlot 的使用情况，为提交的应用分配相应的 TaskSlot 资源并命令 TaskManager 启动从客户端中获取的应用。JobManager 是集群中的Master节点，整个集群有且仅有一个active的JobManager，负责整个集群的任务管理和资源管理。JobManager和TaskManager之间通过Actor System 进行通信，获取任务的执行情况并通过Actor System 将应用的任务的执行情况发送到客户端。同时在任务的执行过程中，Flink JobManager 会触发Checkpoints 操作，每个TaskManager 节点接受的到checkpoints触发命令后，完成checkpoints操作，所有的checkpoint协调过程都是在Flink JobManager中完成。当任务完成后，JobManager会将任务执行信息返回到客户端，并释放掉TaskManager中的资源以供下一次任务使用。

TaskManager 相当于整个集群的slave 节点，负责具体的任务执行和对应任务在每个节点上的资源申请与管理。客户端通过将编写好的flink应用编译打包，提交到JobManager，然后JobManager会根据已经注册在jobmanger中TaskManager的资源情况，将任务分配到有资源的TaskManager节点，然后启动并运行任务。TaskManager从JobManager那接受需要部署的任务，然后使用slot资源启动task，建立数据接入网络连接，接受数据并处理。同时TaskManager之间的数据交互都是通过数据流的方式进行的。

![](/images/flink-on-k8s.jpg)

### 有界数据流和无界数据流

Flink用于处理有界和无界数据：

* 无界数据流：无界数据流有一个开始但是没有结束，它们不会在生成时终止并提供数据，必须连续处理无界流，也就是说必须在获取后立即处理event。对于无界数据流我们无法等待所有数据都到达，因为输入是无界的，并且在任何时间点都不会完成。处理无界数据通常要求以特定顺序（例如事件发生的顺序）获取event，以便能够推断结果完整性。
* 有界数据流：有界数据流有明确定义的开始和结束，可以在执行任何计算之前通过获取所有数据来处理有界流，处理有界流不需要有序获取，因为可以始终对有界数据集进行排序，有界流的处理也称为批处理。

![](/images/flink-stream.png)

### 编程模型

https://ci.apache.org/projects/flink/flink-docs-release-1.10/concepts/programming-model.html