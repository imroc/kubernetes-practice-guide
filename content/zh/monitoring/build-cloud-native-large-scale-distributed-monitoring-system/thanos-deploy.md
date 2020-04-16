---
title: "Thanos 部署与实践"
weight: 30
date: 2020-04-09
draft: false
---

## 概述

上一篇 [Thanos 架构详解](../thanos-arch) 我们深入理解了 thanos 的架构设计与实现原理，现在我们来聊聊实战，分享一下如何部署和使用 Thanos。

## 部署方式

本文聚焦 Thanos 的云原生部署方式，充分利用 Kubernetes 的资源调度与动态扩容能力。从官方 [这里](https://thanos.io/getting-started.md/#community-thanos-kubernetes-applications) 可以看到，当前 thanos 在 Kubernetes 上部署有以下三种：

* [prometheus-operator](https://github.com/coreos/prometheus-operator): 集群中安装了 prometheus-operator 后，就可以通过创建 CRD 对象来部署 Thanos 了。
* [社区贡献的一些 helm charts](https://hub.helm.sh/charts?q=thanos): 很多个版本，目标都是能够使用 helm 来一键部署 thanos。
* [kube-thanos](https://github.com/thanos-io/kube-thanos): Thanos 官方的开源项目，包含部署 thanos 到 kubernetes 的 jsonnet 模板与 yaml 示例。

本文将使用基于 kube-thanos 提供的 yaml 示例 (`examples/all/manifests`) 来部署，原因是 prometheus-operator 与社区的 helm chart 方式部署多了一层封装，屏蔽了许多细节，并且它们的实现都还不太成熟；直接使用 kubernetes 的 yaml 资源文件部署更直观，也更容易做自定义，而且我相信使用 thanos 的用户通常都是高玩了，也有必要对 thanos 理解透彻，日后才好根据实际场景做架构和配置的调整，直接使用 yaml 部署能够让我们看清细节。

## 方案选型

### Sidecar or Receiver

看了上一篇文章的同学应该知道，目前官方的架构图用的 Sidecar 方案，Receiver 是一个暂时还没有完全发布的组件。通常来说，Sidecar 方案相对成熟一些，最新的数据存储和计算 (比如聚合函数) 比较 "分布式"，更加高效也更容易扩展。

![](https://imroc.io/assets/blog/thanos-sidecar.png)

Receiver 方案是让 Prometheus 通过 remote wirte API 将数据 push 到 Receiver 集中存储 (同样会清理过期数据):

![](https://imroc.io/assets/blog/thanos-receiver-without-objectstore.png)

那么该选哪种方案呢？我的建议是：

1. 如果你的 Query 跟 Sidecar 离的比较远，比如 Sidecar 分布在多个数据中心，Query 向所有 Sidecar 查数据，速度会很慢，这种情况可以考虑用 Receiver，将数据集中吐到 Receiver，然后 Receiver 与 Query 部署在一起，Query 直接向 Receiver 查最新数据，提升查询性能。
2. 如果你的使用场景只允许 Prometheus 将数据 push 到远程，可以考虑使用 Receiver。比如 IoT 设备没有持久化存储，只能将数据 push 到远程。

此外的场景应该都尽量使用 Sidecar 方案。

### 评估是否需要 Ruler

Ruler 是一个可选组件，原则上推荐尽量使用 Prometheus 自带的 rule 功能 (生成新指标+告警)，这个功能需要一些 Prometheus 最新数据，直接使用 Prometheus 本机 rule 功能和数据，性能开销相比 Thanos Ruler 这种分布式方案小得多，并且几乎不会出错，Thanos Ruler 由于是分布式，所以更容易出错一些。

如果某些有关联的数据分散在多个不同 Prometheus 上，比如对某个大规模服务采集做了分片，每个 Prometheus 仅采集一部分 endpoint 的数据，对于 `record` 类型的 rule (生成的新指标)，还是可以使用 Prometheus 自带的 rule 功能，在查询时再聚合一下就可以(如果可以接受的话)；对于 `alert` 类型的 rule，就需要用 Thanos Ruler 来做了，因为有关联的数据分散在多个 Prometheus 上，用单机数据去做 alert 计算是不准确的，就可能会造成误告警或不告警。

### 评估是否需要 Store Gateway 与 Compact

Store 也是一个可选组件，也是 Thanos 的一大亮点的关键：数据长期保存。

评估是否需要 Store 组件实际就是评估一下自己是否有数据长期存储的需求，比如查看一两个月前的监控数据。如果有，那么 Thanos 可以将数据上传到对象存储保存。Thanos 支持以下对象存储: 

* Google Cloud Storage
* AWS/S3
* Azure Storage Account
* OpenStack Swift
* Tencent COS
* AliYun OSS

在国内，最方便还是使用腾讯云 COS 或者阿里云 OSS 这样的公有云对象存储服务。如果你的服务没有跑在公有云上，也可以通过跟云服务厂商拉专线的方式来走内网使用对象存储，这样速度通常也是可以满足需求的；如果实在用不了公有云的对象存储服务，也可以自己安装 [minio](https://github.com/minio/minio) 来搭建兼容 AWS 的 S3 对象存储服务。

搞定了对象存储，还需要给 Thanos 多个组件配置对象存储相关的信息，以便能够上传与读取监控数据。除 Query 以外的所有 Thanos 组件 (Sidecar、Receiver、Ruler、Store Gateway、Compact) 都需要配置对象存储信息，使用 `--objstore.config` 直接配置内容或 `--objstore.config-file` 引用对象存储配置文件，不同对象存储配置方式不一样，参考官方文档: https://thanos.io/storage.md

通常使用了对象存储来长期保存数据不止要安装 Store Gateway，还需要安装 Compact 来对对象存储里的数据进行压缩与降采样，这样可以提升查询大时间范围监控数据的性能。注意：Compact 并不会减少对象存储的使用空间，而是会增加，增加更长采样间隔的监控数据，这样当查询大时间范围的数据时，就自动拉取更长时间间隔采样的数据以减少查询数据的总量，从而加快查询速度 (大时间范围的数据不需要那么精细)，当放大查看时 (选择其中一小段时间)，又自动选择拉取更短采样间隔的数据，从而也能显示出小时间范围的监控细节。

## 部署实践

这里以 Thanos 最新版本为例，选择 Sidecar 方案，介绍各个组件的 k8s yaml 定义方式并解释一些重要细节 (根据自身需求，参考上一节的方案选型，自行评估需要安装哪些组件)。

### 准备对象存储配置

如果我们要使用对象存储来长期保存数据，那么就要准备下对象存储的配置信息 (`thanos-objectstorage-secret.yaml`)，比如使用腾讯云 COS 来存储:

``` yaml
apiVersion: v1
kind: Secret
metadata:
  name: thanos-objectstorage
  namespace: thanos
type: Opaque
stringData:
  objectstorage.yaml: |
    type: COS
    config:
      bucket: "thanos"
      region: "ap-singapore"
      app_id: "12*******5"
      secret_key: "tsY***************************Edm"
      secret_id: "AKI******************************gEY"
```

或者使用阿里云 OSS 存储:

``` yaml
apiVersion: v1
kind: Secret
metadata:
  name: thanos-objectstorage
  namespace: thanos
type: Opaque
stringData:
  objectstorage.yaml: |
    type: ALIYUNOSS
    config:
      endpoint: "oss-cn-hangzhou-internal.aliyuncs.com"
      bucket: "thanos"
      access_key_id: "LTA******************KBu"
      access_key_secret: "oki************************2HQ"
```

> 注: 对敏感信息打码了

### 给 Prometheus 加上 Sidecar

如果选用 Sidecar 方案，就需要给 Prometheus 加上 Thanos Sidecar，准备 `prometheus.yaml`:

``` yaml
kind: Service
apiVersion: v1
metadata:
  name: prometheus-headless
  namespace: thanos
  labels:
    app.kubernetes.io/name: prometheus
spec:
  type: ClusterIP
  clusterIP: None
  selector:
    app: prometheus
  ports:
  - name: web
    protocol: TCP
    port: 9090
    targetPort: web
  - name: grpc
    port: 10901
    targetPort: grpc
---

apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: thanos

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: prometheus
  namespace: thanos
rules:
- apiGroups: [""]
  resources:
  - nodes
  - nodes/proxy
  - nodes/metrics
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get"]
- nonResourceURLs: ["/metrics"]
  verbs: ["get"]

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: prometheus
subjects:
  - kind: ServiceAccount
    name: prometheus
    namespace: thanos
roleRef:
  kind: ClusterRole
  name: prometheus
  apiGroup: rbac.authorization.k8s.io
---

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: prometheus
  namespace: thanos
  labels:
    app.kubernetes.io/name: thanos-query
spec:
  serviceName: prometheus-headless
  podManagementPolicy: Parallel
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: prometheus
  template:
    metadata:
      labels:
        app.kubernetes.io/name: prometheus
    spec:
      serviceAccountName: prometheus
      securityContext:
        fsGroup: 2000
        runAsNonRoot: true
        runAsUser: 1000
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app.kubernetes.io/name
                  operator: In
                  values:
                  - prometheus
              topologyKey: kubernetes.io/hostname
            weight: 100
      containers:
      - name: prometheus
        image: quay.io/prometheus/prometheus:v2.15.2
        args:
        - --config.file=/etc/prometheus/config_out/prometheus.yaml
        - --storage.tsdb.path=/prometheus
        - --storage.tsdb.retention.time=10d
        - --web.route-prefix=/
        - --web.enable-lifecycle
        - --storage.tsdb.no-lockfile
        - --storage.tsdb.min-block-duration=2h
        - --storage.tsdb.max-block-duration=2h
        - --log.level=debug
        ports:
        - containerPort: 9090
          name: web
          protocol: TCP
        livenessProbe:
          failureThreshold: 6
          httpGet:
            path: /-/healthy
            port: web
            scheme: HTTP
          periodSeconds: 5
          successThreshold: 1
          timeoutSeconds: 3
        readinessProbe:
          failureThreshold: 120
          httpGet:
            path: /-/ready
            port: web
            scheme: HTTP
          periodSeconds: 5
          successThreshold: 1
          timeoutSeconds: 3
        volumeMounts:
        - mountPath: /etc/prometheus/config_out
          name: prometheus-config-out
          readOnly: true
        - mountPath: /prometheus
          name: prometheus-storage
        - mountPath: /etc/prometheus/rules
          name: prometheus-rules
      - name: thanos
        image: quay.io/thanos/thanos:v0.11.0
        args:
        - sidecar
        - --log.level=debug
        - --tsdb.path=/prometheus
        - --prometheus.url=http://127.0.0.1:9090
        - --objstore.config-file=/etc/thanos/objectstorage.yaml
        - --reloader.config-file=/etc/prometheus/config/prometheus.yaml.tmpl
        - --reloader.config-envsubst-file=/etc/prometheus/config_out/prometheus.yaml
        - --reloader.rule-dir=/etc/prometheus/rules/
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        ports:
        - name: http-sidecar
          containerPort: 10902
        - name: grpc
          containerPort: 10901
        livenessProbe:
            httpGet:
              port: 10902
              path: /-/healthy
        readinessProbe:
          httpGet:
            port: 10902
            path: /-/ready
        volumeMounts:
        - name: prometheus-config-tmpl
          mountPath: /etc/prometheus/config
        - name: prometheus-config-out
          mountPath: /etc/prometheus/config_out
        - name: prometheus-rules
          mountPath: /etc/prometheus/rules
        - name: prometheus-storage
          mountPath: /prometheus
        - name: thanos-objectstorage
          subPath: objectstorage.yaml
          mountPath: /etc/thanos/objectstorage.yaml
      volumes:
      - name: prometheus-config-tmpl
        configMap:
          defaultMode: 420
          name: prometheus-config-tmpl
      - name: prometheus-config-out
        emptyDir: {}
      - name: prometheus-rules
        configMap:
          name: prometheus-rules
      - name: thanos-objectstorage
        secret:
          secretName: thanos-objectstorage
  volumeClaimTemplates:
  - metadata:
      name: prometheus-storage
      labels:
        app.kubernetes.io/name: prometheus
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 200Gi
      volumeMode: Filesystem
```

* Prometheus 使用 StatefulSet 方式部署，挂载数据盘以便存储最新监控数据。
* 由于 Prometheus 副本之间没有启动顺序的依赖，所以 podManagementPolicy 指定为 Parallel，加快启动速度。
* 为 Prometheus 绑定足够的 RBAC 权限，以便后续配置使用 k8s 的服务发现 (`kubernetes_sd_configs`) 时能够正常工作。
* 为 Prometheus 创建 headless 类型 service，一方面是 StatefulSet 本身需要指定 headless 的 `serviceName`，另一方面是为后续 Thanos Query 通过 DNS SRV 记录来动态发现 Sidecar 的 gRPC 端点做准备 (使用 headless service 才能让 DNS SRV 正确返回所有端点)。
* 使用两个 Prometheus 副本，用于实现高可用。
* 使用硬反亲和，避免 Prometheus 部署在同一节点，既可以分散压力也可以避免单点故障。
* Prometheus 使用 `--storage.tsdb.retention.time` 指定数据保留时长，默认15天，可以根据数据增长速度和数据盘大小做适当调整(数据增长取决于采集的指标和目标端点的数量和采集频率)。
* Sidecar 使用 `--objstore.config-file` 引用我们刚刚创建并挂载的对象存储配置文件，用于上传数据到对象存储。
* 通常会给 Prometheus 附带一个 quay.io/coreos/prometheus-config-reloader 来监听配置变更并动态加载，但 thanos sidecar 也为我们提供了这个功能，所以可以直接用 thanos sidecar 来实现此功能，也支持配置文件根据模板动态生成：`--reloader.config-file` 指定 Prometheus 配置文件模板，`--reloader.config-envsubst-file` 指定生成配置文件的存放路径，假设是 `/etc/prometheus/config_out/prometheus.yaml` ，那么 `/etc/prometheus/config_out` 这个路径使用 emptyDir 让 Prometheus 与 Sidecar 实现配置文件共享挂载，Prometheus 再通过 `--config.file` 指定生成出来的配置文件，当配置有更新时，挂载的配置文件也会同步更新，Sidecar 也会通知 Prometheus 重新加载配置。另外，Sidecar 与 Prometheus 也挂载同一份 rules 配置文件，配置更新后 Sidecar 仅通知 Prometheus 加载配置，不支持模板，因为 rules 配置不需要模板来动态生成。

然后再给 Prometheus 准备配置 (`prometheus-config.yaml`):

``` yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config-tmpl
  namespace: thanos
data:
  prometheus.yaml.tmpl: |-
    global:
      scrape_interval: 5s
      evaluation_interval: 5s
      external_labels:
        cluster: prometheus-ha
        prometheus_replica: $(POD_NAME)
    rule_files:
    - /etc/prometheus/rules/*rules.yaml
    scrape_configs:
    - job_name: cadvisor
      metrics_path: /metrics/cadvisor
      scrape_interval: 10s
      scrape_timeout: 10s
      scheme: https
      tls_config:
        insecure_skip_verify: true
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      kubernetes_sd_configs:
      - role: node
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
---

apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules
  labels:
    name: prometheus-rules
  namespace: thanos
data:
  alert-rules.yaml: |-
    groups:
    - name: k8s.rules
      rules:
      - expr: |
          sum(rate(container_cpu_usage_seconds_total{job="cadvisor", metrics_path="/metrics/cadvisor", image!="", container!="POD"}[5m])) by (namespace)
        record: namespace:container_cpu_usage_seconds_total:sum_rate
      - expr: |
          sum(container_memory_usage_bytes{job="cadvisor", image!="", container_name!=""}) by (namespace)
        record: namespace:container_memory_usage_bytes:sum
      - expr: |
          sum by (namespace, pod_name, container_name) (
            rate(container_cpu_usage_seconds_total{job="cadvisor", image!="", container_name!=""}[5m])
          )
        record: namespace_pod_name_container_name:container_cpu_usage_seconds_total:sum_rate
```

* 本文重点不在 prometheus 的配置文件，所以这里仅以采集 kubelet 所暴露的 cadvisor 容器指标的简单配置为例。
* Prometheus 实例采集的所有指标数据里都会额外加上 `external_labels` 里指定的 label，通常用 `cluster` 区分当前 Prometheus 所在集群的名称，我们再加了个 `prometheus_replica`，用于区分相同 Prometheus 副本（这些副本所采集的数据除了 `prometheus_replica` 的值不一样，其它几乎一致，这个值会被 Thanos Sidecar 替换成 Pod 副本的名称，用于 Thanos 实现 Prometheus 高可用）

### 安装 Query

准备 `thanos-query.yaml`:

``` yaml
apiVersion: v1
kind: Service
metadata:
  name: thanos-query
  namespace: thanos
  labels:
    app.kubernetes.io/name: thanos-query
spec:
  ports:
  - name: grpc
    port: 10901
    targetPort: grpc
  - name: http
    port: 9090
    targetPort: http
  selector:
    app.kubernetes.io/name: thanos-query
---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: thanos-query
  namespace: thanos
  labels:
    app.kubernetes.io/name: thanos-query
spec:
  replicas: 3
  selector:
    matchLabels:
      app.kubernetes.io/name: thanos-query
  template:
    metadata:
      labels:
        app.kubernetes.io/name: thanos-query
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app.kubernetes.io/name
                  operator: In
                  values:
                  - thanos-query
              topologyKey: kubernetes.io/hostname
            weight: 100
      containers:
      - args:
        - query
        - --log.level=debug
        - --query.auto-downsampling
        - --grpc-address=0.0.0.0:10901
        - --http-address=0.0.0.0:9090
        - --query.partial-response
        - --query.replica-label=prometheus_replica
        - --query.replica-label=rule_replica
        - --store=dnssrv+_grpc._tcp.prometheus-headless.thanos.svc.cluster.local
        - --store=dnssrv+_grpc._tcp.thanos-rule.thanos.svc.cluster.local
        - --store=dnssrv+_grpc._tcp.thanos-store.thanos.svc.cluster.local
        image: thanosio/thanos:v0.11.0
        livenessProbe:
          failureThreshold: 4
          httpGet:
            path: /-/healthy
            port: 9090
            scheme: HTTP
          periodSeconds: 30
        name: thanos-query
        ports:
        - containerPort: 10901
          name: grpc
        - containerPort: 9090
          name: http
        readinessProbe:
          failureThreshold: 20
          httpGet:
            path: /-/ready
            port: 9090
            scheme: HTTP
          periodSeconds: 5
        terminationMessagePolicy: FallbackToLogsOnError
      terminationGracePeriodSeconds: 120
```

* 因为 Query 是无状态的，使用 Deployment 部署，也不需要 headless service，直接创建普通的 service。
* 使用软反亲和，尽量不让 Query 调度到同一节点。
* 部署多个副本，实现 Query 的高可用。
* `--query.partial-response` 启用 [Partial Response](https://thanos.io/components/query.md/#partial-response)，这样可以在部分后端 Store API 返回错误或超时的情况下也能看到正确的监控数据(如果后端 Store API 做了高可用，挂掉一个副本，Query 访问挂掉的副本超时，但由于还有没挂掉的副本，还是能正确返回结果；如果挂掉的某个后端本身就不存在我们需要的数据，挂掉也不影响结果的正确性；总之如果各个组件都做了高可用，想获得错误的结果都难，所以我们有信心启用 Partial Response 这个功能)。
* `--query.auto-downsampling` 查询时自动降采样，提升查询效率。
* `--query.replica-label` 指定我们刚刚给 Prometheus 配置的 `prometheus_replica` 这个 external label，Query 向 Sidecar 拉取 Prometheus 数据时会识别这个 label 并自动去重，这样即使挂掉一个副本，只要至少有一个副本正常也不会影响查询结果，也就是可以实现 Prometheus 的高可用。同理，再指定一个 `rule_replica` 用于给 Ruler 做高可用。
* `--store` 指定实现了 Store API 的地址(Sidecar, Ruler, Store Gateway, Receiver)，通常不建议写静态地址，而是使用服务发现机制自动发现 Store API 地址，如果是部署在同一个集群，可以用 DNS SRV 记录来做服务发现，比如 `dnssrv+_grpc._tcp.prometheus-headless.thanos.svc.cluster.local`，也就是我们刚刚为包含 Sidecar 的 Prometheus 创建的 headless service (使用 headless service 才能正确实现服务发现)，并且指定了名为 grpc 的 tcp 端口，同理，其它组件也可以按照这样加到 `--store` 参数里；如果是其它有些组件部署在集群外，无法通过集群 dns 解析 DNS SRV 记录，可以使用配置文件来做服务发现，也就是指定 `--store.sd-files` 参数，将其它 Store API 地址写在配置文件里 (挂载 ConfigMap)，需要增加地址时直接更新 ConfigMap (不需要重启 Query)。

## 安装 Store Gateway

准备 `thanos-store.yaml`:

``` yaml
apiVersion: v1
kind: Service
metadata:
  name: thanos-store
  namespace: thanos
  labels:
    app.kubernetes.io/name: thanos-store
spec:
  clusterIP: None
  ports:
  - name: grpc
    port: 10901
    targetPort: 10901
  - name: http
    port: 10902
    targetPort: 10902
  selector:
    app.kubernetes.io/name: thanos-store
---

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: thanos-store
  namespace: thanos
  labels:
    app.kubernetes.io/name: thanos-store
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: thanos-store
  serviceName: thanos-store
  podManagementPolicy: Parallel
  template:
    metadata:
      labels:
        app.kubernetes.io/name: thanos-store
    spec:
      containers:
      - args:
        - store
        - --log.level=debug
        - --data-dir=/var/thanos/store
        - --grpc-address=0.0.0.0:10901
        - --http-address=0.0.0.0:10902
        - --objstore.config-file=/etc/thanos/objectstorage.yaml
        - --experimental.enable-index-header
        image: thanosio/thanos:v0.11.0
        livenessProbe:
          failureThreshold: 8
          httpGet:
            path: /-/healthy
            port: 10902
            scheme: HTTP
          periodSeconds: 30
        name: thanos-store
        ports:
        - containerPort: 10901
          name: grpc
        - containerPort: 10902
          name: http
        readinessProbe:
          failureThreshold: 20
          httpGet:
            path: /-/ready
            port: 10902
            scheme: HTTP
          periodSeconds: 5
        terminationMessagePolicy: FallbackToLogsOnError
        volumeMounts:
        - mountPath: /var/thanos/store
          name: data
          readOnly: false
        - name: thanos-objectstorage
          subPath: objectstorage.yaml
          mountPath: /etc/thanos/objectstorage.yaml
      terminationGracePeriodSeconds: 120
      volumes:
      - name: thanos-objectstorage
        secret:
          secretName: thanos-objectstorage
  volumeClaimTemplates:
  - metadata:
      labels:
        app.kubernetes.io/name: thanos-store
      name: data
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 10Gi
```

* Store Gateway 实际也可以做到一定程度的无状态，它会需要一点磁盘空间来对对象存储做索引以加速查询，但数据不那么重要，是可以删除的，删除后会自动去拉对象存储查数据重新建立索引。这里我们避免每次重启都重新建立索引，所以用 StatefulSet 部署 Store Gateway，挂载一块小容量的磁盘(索引占用不到多大空间)。
* 同样创建 headless service，用于 Query 对 Store Gateway 进行服务发现。
* 部署两个副本，实现 Store Gateway 的高可用。
* Store Gateway 也需要对象存储的配置，用于读取对象存储的数据，所以要挂载对象存储的配置文件。

### 安装 Ruler

准备 `thanos-rule.yaml`:

``` yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/name: thanos-rule
  name: thanos-rule
  namespace: thanos
spec:
  clusterIP: None
  ports:
  - name: grpc
    port: 10901
    targetPort: grpc
  - name: http
    port: 10902
    targetPort: http
  selector:
    app.kubernetes.io/name: thanos-rule
---

apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    app.kubernetes.io/name: thanos-rule
  name: thanos-rule
  namespace: thanos
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: thanos-rule
  serviceName: thanos-rule
  podManagementPolicy: Parallel
  template:
    metadata:
      labels:
        app.kubernetes.io/name: thanos-rule
    spec:
      containers:
      - args:
        - rule
        - --grpc-address=0.0.0.0:10901
        - --http-address=0.0.0.0:10902
        - --rule-file=/etc/thanos/rules/*rules.yaml
        - --objstore.config-file=/etc/thanos/objectstorage.yaml
        - --data-dir=/var/thanos/rule
        - --label=rule_replica="$(NAME)"
        - --alert.label-drop="rule_replica"
        - --query=dnssrv+_http._tcp.thanos-query.thanos.svc.cluster.local
        env:
        - name: NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        image: thanosio/thanos:v0.11.0
        livenessProbe:
          failureThreshold: 24
          httpGet:
            path: /-/healthy
            port: 10902
            scheme: HTTP
          periodSeconds: 5
        name: thanos-rule
        ports:
        - containerPort: 10901
          name: grpc
        - containerPort: 10902
          name: http
        readinessProbe:
          failureThreshold: 18
          httpGet:
            path: /-/ready
            port: 10902
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 5
        terminationMessagePolicy: FallbackToLogsOnError
        volumeMounts:
        - mountPath: /var/thanos/rule
          name: data
          readOnly: false
        - name: thanos-objectstorage
          subPath: objectstorage.yaml
          mountPath: /etc/thanos/objectstorage.yaml
        - name: thanos-rule
          mountPath: /etc/thanos/rules
      volumes:
      - name: thanos-objectstorage
        secret:
          secretName: thanos-objectstorage
      - name: thanos-rule
        configMap:
          name: thanos-rule
  volumeClaimTemplates:
  - metadata:
      labels:
        app.kubernetes.io/name: thanos-rule
      name: data
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 100Gi
```

* Ruler 是有状态服务，使用 Statefulset 部署，挂载磁盘以便存储根据 rule 配置计算出的新数据。
* 同样创建 headless service，用于 Query 对 Ruler 进行服务发现。
* 部署两个副本，且使用 `--label=rule_replica=` 给所有数据添加 `rule_replica` 的 label (与 Query 配置的 `replica_label` 相呼应)，用于实现 Ruler 高可用。同时指定 `--alert.label-drop` 为 `rule_replica`，在触发告警发送通知给 AlertManager 时，去掉这个 label，以便让 AlertManager 自动去重 (避免重复告警)。
* 使用 `--query` 指定 Query 地址，这里还是用 DNS SRV 来做服务发现，但效果跟配 `dns+thanos-query.thanos.svc.cluster.local:9090` 是一样的，最终都是通过 Query 的 ClusterIP (VIP) 访问，因为它是无状态的，可以直接由 K8S 来给我们做负载均衡。
* Ruler 也需要对象存储的配置，用于上传计算出的数据到对象存储，所以要挂载对象存储的配置文件。
* `--rule-file` 指定挂载的 rule 配置，Ruler 根据配置来生成数据和触发告警。

``` yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: thanos-rules
  labels:
    name: thanos-rules
  namespace: thanos
data:
  record.rules.yaml: |-
    groups:
    - name: k8s.rules
      rules:
      - expr: |
          sum(rate(container_cpu_usage_seconds_total{job="cadvisor", metrics_path="/metrics/cadvisor", image!="", container!="POD"}[5m])) by (namespace)
        record: namespace:container_cpu_usage_seconds_total:sum_rate
      - expr: |
          sum(container_memory_usage_bytes{job="cadvisor", image!="", container_name!=""}) by (namespace)
        record: namespace:container_memory_usage_bytes:sum
      - expr: |
          sum by (namespace, pod_name, container_name) (
            rate(container_cpu_usage_seconds_total{job="cadvisor", image!="", container_name!=""}[5m])
          )
        record: namespace_pod_name_container_name:container_cpu_usage_seconds_total:sum_rate
```

* 配置内容仅为示例，根据自身情况来配置，格式基本兼容 Prometheus 的 rule 配置格式，参考: https://thanos.io/components/rule.md/#configuring-rules

### 安装 Compact

准备 `thanos-compact.yaml`:

``` yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/name: thanos-compact
  name: thanos-compact
  namespace: thanos
spec:
  ports:
  - name: http
    port: 10902
    targetPort: http
  selector:
    app.kubernetes.io/name: thanos-compact
---

apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    app.kubernetes.io/name: thanos-compact
  name: thanos-compact
  namespace: thanos
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: thanos-compact
  serviceName: thanos-compact
  template:
    metadata:
      labels:
        app.kubernetes.io/name: thanos-compact
    spec:
      containers:
      - args:
        - compact
        - --wait
        - --objstore.config-file=/etc/thanos/objectstorage.yaml
        - --data-dir=/var/thanos/compact
        - --debug.accept-malformed-index
        - --log.level=debug
        - --retention.resolution-raw=90d
        - --retention.resolution-5m=180d
        - --retention.resolution-1h=360d
        env:
        - name: OBJSTORE_CONFIG
          valueFrom:
            secretKeyRef:
              key: thanos.yaml
              name: thanos-objectstorage
        image: thanosio/thanos:v0.11.0
        livenessProbe:
          failureThreshold: 4
          httpGet:
            path: /-/healthy
            port: 10902
            scheme: HTTP
          periodSeconds: 30
        name: thanos-compact
        ports:
        - containerPort: 10902
          name: http
        readinessProbe:
          failureThreshold: 20
          httpGet:
            path: /-/ready
            port: 10902
            scheme: HTTP
          periodSeconds: 5
        terminationMessagePolicy: FallbackToLogsOnError
        volumeMounts:
        - mountPath: /var/thanos/compact
          name: data
          readOnly: false
        - name: thanos-objectstorage
          subPath: objectstorage.yaml
          mountPath: /etc/thanos/objectstorage.yaml
      terminationGracePeriodSeconds: 120
      volumes:
      - name: thanos-objectstorage
        secret:
          secretName: thanos-objectstorage
  volumeClaimTemplates:
  - metadata:
      labels:
        app.kubernetes.io/name: thanos-compact
      name: data
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 100Gi

```

* Compact 只能部署单个副本，因为如果多个副本都去对对象存储的数据做压缩和降采样的话，会造成冲突。
* 使用 StatefulSet 部署，方便自动创建和挂载磁盘。磁盘用于存放临时数据，因为 Compact 需要一些磁盘空间来存放数据处理过程中产生的中间数据。
* `--wait` 让 Compact 一直运行，轮询新数据来做压缩和降采样。
* Compact 也需要对象存储的配置，用于读取对象存储数据以及上传压缩和降采样后的数据到对象存储。
* 创建一个普通 service，主要用于被 Prometheus 使用 kubernetes 的 endpoints 服务发现来采集指标(其它组件的 service 也一样有这个用途)。
* `--retention.resolution-raw` 指定原始数据存放时长，`--retention.resolution-5m` 指定降采样到数据点 5 分钟间隔的数据存放时长，`--retention.resolution-1h` 指定降采样到数据点 1 小时间隔的数据存放时长，它们的数据精细程度递减，占用的存储空间也是递减，通常建议它们的存放时间递增配置 (一般只有比较新的数据才会放大看，久远的数据通常只会使用大时间范围查询来看个大致，所以建议将精细程度低的数据存放更长时间)

### 安装 Receiver

``` yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: thanos-receive-hashrings
  namespace: kube-system
data:
  thanos-receive-hashrings: |
    [
      {
        "hashring": "soft-tenants",
        "endpoints":
        [
          "thanos-receive-0.thanos-receive.kube-system.svc.cluster.local:10901",
          "thanos-receive-1.thanos-receive.kube-system.svc.cluster.local:10901",
          "thanos-receive-2.thanos-receive.kube-system.svc.cluster.local:10901"
        ]
      }
    ]
---

apiVersion: v1
kind: Service
metadata:
  name: thanos-receive
  namespace: kube-system
  labels:
    kubernetes.io/name: thanos-receive
spec:
  ports:
  - name: http
    port: 10902
    protocol: TCP
    targetPort: 10902
  - name: remote-write
    port: 19291
    protocol: TCP
    targetPort: 19291
  - name: grpc
    port: 10901
    protocol: TCP
    targetPort: 10901
  selector:
    kubernetes.io/name: thanos-receive
  clusterIP: None
---

apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    kubernetes.io/name: thanos-receive
  name: thanos-receive
  namespace: kube-system
spec:
  replicas: 3
  selector:
    matchLabels:
      kubernetes.io/name: thanos-receive
  serviceName: thanos-receive
  template:
    metadata:
      labels:
        kubernetes.io/name: thanos-receive
    spec:
      containers:
      - args:
        - receive
        - --grpc-address=0.0.0.0:10901
        - --http-address=0.0.0.0:10902
        - --remote-write.address=0.0.0.0:19291
        - --objstore.config=$(OBJSTORE_CONFIG)
        - --tsdb.path=/var/thanos/receive
        - --tsdb.retention=2h
        - --label=receive_replica="$(NAME)"
        - --label=receive="true"
        - --receive.hashrings-file=/etc/thanos/thanos-receive-hashrings
        - --receive.local-endpoint=$(NAME).thanos-receive.kube-system.svc.cluster.local:10901
        env:
        - name: NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        image: registry.cpu.oa.com/library/thanos:v0.11.0
        livenessProbe:
          failureThreshold: 4
          httpGet:
            path: /-/healthy
            port: 10902
            scheme: HTTP
          periodSeconds: 30
        name: thanos-receive
        ports:
        - containerPort: 10901
          name: grpc
        - containerPort: 10902
          name: http
        - containerPort: 19291
          name: remote-write
        readinessProbe:
          httpGet:
            path: /-/ready
            port: 10902
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 30
        resources:
          limits:
            cpu: "8"
            memory: 16Gi
          requests:
            cpu: "4"
            memory: 8Gi
        volumeMounts:
        - mountPath: /var/thanos/receive
          name: thanos-receive-data
          readOnly: false
        - mountPath: /etc/thanos/
          name: thanos-receive-hashrings
      terminationGracePeriodSeconds: 120
      volumes:
      - name: thanos-receive-data
        hostPath:
          path: /data/thanos-receive
          type: DirectoryOrCreate
      - configMap:
          defaultMode: 420
          name: thanos-receive-hashrings
        name: thanos-receive-hashrings
```
