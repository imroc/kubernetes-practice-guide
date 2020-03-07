---
title: "Pod Terminating 慢"
state: Alpha
---

## 可能原因

* 进程通过 bash -c 启动导致 kill 信号无法透传给业务进程
