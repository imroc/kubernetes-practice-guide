---
title: "Pod 一直处于 Unknown 状态"
---

TODO: 完善

通常是节点失联，没有上报状态给 apiserver，到达阀值后 controller-manager 认为节点失联并将其状态置为 `Unknown`。

可能原因:

* 节点高负载导致无法上报
* 节点宕机
* 节点被关机
* 网络不通
