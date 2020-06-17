---
title: "PromQL 技巧"
weight: 2000
---

## 复制标签名

pod_name --> pod:

``` promql
label_replace(
    container_cpu_system_seconds_total,
    "pod", "$1", "pod_name", "(.*)"
)
```

新标签名跟其它指标:

``` promql
sum by (pod)(
    irate(
        (
            label_replace(
                container_cpu_system_seconds_total{container_name!=""},
                "pod", "$1", "pod_name", "(.*)"
            ) * on (namespace,pod) group_left(workload,workload_type) mixin_pod_workload{namespace="$namespace", workload=~"$workload", workload_type=~"$workload_type"}
        )[1m:15s]
    )
)
```
