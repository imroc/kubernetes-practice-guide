# Pod 一直处于 Error 状态

TODO: 展开优化

通常处于 Error 状态说明 Pod 启动过程中发生了错误。常见的原因包括：

* 依赖的 ConfigMap、Secret 或者 PV 等不存在
* 请求的资源超过了管理员设置的限制，比如超过了 LimitRange 等
* 违反集群的安全策略，比如违反了 PodSecurityPolicy 等
* 容器无权操作集群内的资源，比如开启 RBAC 后，需要为 ServiceAccount 配置角色绑定
