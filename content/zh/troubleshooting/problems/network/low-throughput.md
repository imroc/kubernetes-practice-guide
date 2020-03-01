---
title: "网络性能差"
---

## IPVS 模式吞吐性能低

内核参数关闭 `conn_reuse_mode`:

``` bash
sysctl net.ipv4.vs.conn_reuse_mode=0
```

参考 issue: https://github.com/kubernetes/kubernetes/issues/70747
