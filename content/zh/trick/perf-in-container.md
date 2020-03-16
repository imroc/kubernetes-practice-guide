---
title: "在容器内使用 perf"
state: TODO
---

## 条件

运行 perf 主要会用到 `perf_event_open` 系统调用，要在容器内使用，需要满足以下条件:
1. 设置内核参数：`kernel.perf_event_paranoid = -1`
2. 把系统调用perf_event_open放到白名单中（获取dockerd 默认的seccomp profile，然后把系统调用perf_event_open从CAP_SYS_ADMIN移出放到白名单）或者设置seccomp=unconfined
而在k8s场景下，由于kubelet默认会给pod配置seccomp=unconfined的SecurityOpt选项，所以只需要满足第一个条件即可
