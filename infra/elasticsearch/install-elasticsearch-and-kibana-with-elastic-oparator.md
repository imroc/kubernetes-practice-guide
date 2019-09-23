# 使用 elastic-oparator 部署 Elasticsearch 和 Kibana

参考官方文档:

- https://www.elastic.co/cn/elasticsearch-kubernetes
- https://www.elastic.co/cn/blog/introducing-elastic-cloud-on-kubernetes-the-elasticsearch-operator-and-beyond

## 安装 elastic-operator

一键安装:

``` bash
kubectl apply -f https://download.elastic.co/downloads/eck/0.9.0/all-in-one.yaml
```

## 部署 Elasticsearch

准备一个命名空间用来部署 elasticsearch，这里我们使用 `monitoring` 命名空间:

``` bash
kubectl create ns monitoring
```

创建 CRD 资源部署 Elasticsearch，最简单的部署:

``` bash
cat <<EOF | kubectl apply -f -
apiVersion: elasticsearch.k8s.elastic.co/v1alpha1
kind: Elasticsearch
metadata:
  name: es
  namespace: monitoring
spec:
  version: 7.2.0
  nodes:
  - nodeCount: 1
    config:
      node.master: true
      node.data: true
      node.ingest: true
EOF
```

多节点部署高可用 elasticsearch 集群:

``` bash
cat <<EOF | kubectl apply -f -
apiVersion: elasticsearch.k8s.elastic.co/v1alpha1
kind: Elasticsearch
metadata:
  name: es
  namespace: monitoring
spec:
  version: 7.2.0
  nodes:
  - nodeCount: 1
    config:
      node.master: true
      node.data: true
      node.ingest: true
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 100Gi
    podTemplate:
      spec:
        affinity:
          podAntiAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                - key: elasticsearch.k8s.elastic.co/cluster-name
                  operator: In
                  values:
                  - es
              topologyKey: "kubernetes.io/hostname"
  - nodeCount: 2
    config:
      node.master: false
      node.data: true
      node.ingest: true
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 80Gi
    podTemplate:
      spec:
        affinity:
          podAntiAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                - key: elasticsearch.k8s.elastic.co/cluster-name
                  operator: In
                  values:
                  - es
              topologyKey: kubernetes.io/hostname
EOF
```

- `metadata.name` 是 elasticsearch 集群的名称
- `nodeCount` 大于 1 (多副本) 并且加了 pod 反亲和性 (避免调度到同一个节点) 可避免单点故障，保证高可用
- `node.master` 为 true 表示是 master 节点
- 可根据需求调整 `nodeCount` (副本数量) 和 `storage` (数据磁盘容量)
- 反亲和性的 `labelSelector.matchExpressions.values` 中写 elasticsearch 集群名称，更改集群名称时记得这里要也改下
- 强制开启 ssl 不允许关闭: https://github.com/elastic/cloud-on-k8s/blob/576f07faaff4393f9fb247e58b87517f99b08ebd///pkg/controller/elasticsearch/settings/fields.go#L51

查看部署状态:

``` bash
$ kubectl -n monitoring get es
NAME   HEALTH   NODES   VERSION   PHASE         AGE
es     green    3       7.2.0     Operational   3m
$
$ kubectl -n monitoring get pod -o wide
NAME                         READY   STATUS    RESTARTS   AGE    IP            NODE        NOMINATED NODE
es-es-c7pwnt5kz8             1/1     Running   0          4m3s   172.16.4.6    10.0.0.24   <none>
es-es-qpk7kkpdxh             1/1     Running   0          4m3s   172.16.5.6    10.0.0.48   <none>
es-es-vl56nv78hd             1/1     Running   0          4m3s   172.16.3.9    10.0.0.32   <none>
$
$ kubectl -n monitoring get svc
NAME             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
es-es-http       ClusterIP   172.16.15.74   <none>        9200/TCP   7m3s
```

elasticsearch 的默认用户名是 elastic，获取密码:

``` bash
$ kubectl -n monitoring get secret es-es-elastic-user -o jsonpath='{.data.elastic}' | base64 -d
rhd6jdw9brbj69d49k46px9j
```

后续连接 elasticsearch 时就用这对用户名密码:

- username: elastic
- password: rhd6jdw9brbj69d49k46px9j

## 部署 Kibana

还可以再部署一个 Kibana 集群作为 UI:

``` bash
cat <<EOF | kubectl apply -f -
apiVersion: kibana.k8s.elastic.co/v1alpha1
kind: Kibana
metadata:
  name: kibana
  namespace: monitoring
spec:
  version: 7.2.0
  nodeCount: 2
  podTemplate:
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: kibana.k8s.elastic.co/name
                operator: In
                values:
                - kibana
            topologyKey: kubernetes.io/hostname
  elasticsearchRef:
    name: es
    namespace: monitoring
EOF
```

- `nodeCount` 大于 1 (多副本) 并且加了 pod 反亲和性 (避免调度到同一个节点) 可避免单点故障，保证高可用
- 反亲和性的 `labelSelector.matchExpressions.values` 中写 kibana 集群名称，更改集群名称时记得这里要也改下
- `elasticsearchRef` 引用已经部署的 elasticsearch 集群，`name` 和 `namespace` 分别填部署的 elasticsearch 集群名称和命名空间

查看部署状态:

``` bash
$ kubectl -n monitoring get kb
NAME     HEALTH   NODES   VERSION   AGE
kibana   green    2       7.2.0     3m
$
$ kubectl -n monitoring get pod -o wide
NAME                         READY   STATUS    RESTARTS   AGE    IP            NODE        NOMINATED NODE
kibana-kb-58dc8994bf-224bl   1/1     Running   0          93s    172.16.0.92   10.0.0.3    <none>
kibana-kb-58dc8994bf-nchqt   1/1     Running   0          93s    172.16.3.10   10.0.0.32   <none>
$
$ kubectl -n monitoring get svc
NAME             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
kibana-kb-http   ClusterIP   172.16.8.71    <none>        5601/TCP   4m35s
```

还需要为 Kibana 暴露一个外部地址好让我们能从从浏览器访问，可以创建 Service 或 Ingress 来实现。
> 默认也会为 Kibana 创建 ClusterIP 类型的 Service，可以在 Kibana 的 CRD spec 里加 service 来自定义 service type 为 LoadBalancer 实现对外暴露，但我不建议这么做，因为一旦删除 CRD 对象，service 也会被删除，在云上通常意味着对应的负载均衡器也被自动删除，IP 地址就会被回收，下次再创建的时候 IP 地址就变了，所以推荐对外暴露方式使用单独的 Service 或 Ingress 来维护

### 创建 Service

先看下当前 kibana 的 service:

``` bash
$ kubectl -n monitoring get svc -o yaml kibana-kb-http
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: 2019-09-17T09:20:04Z
  labels:
    common.k8s.elastic.co/type: kibana
    kibana.k8s.elastic.co/name: kibana
  name: kibana-kb-http
  namespace: monitoring
  ownerReferences:
  - apiVersion: kibana.k8s.elastic.co/v1alpha1
    blockOwnerDeletion: true
    controller: true
    kind: Kibana
    name: kibana
    uid: 54fd304b-d92c-11e9-89f7-be8690a7fdcf
  resourceVersion: "5668802758"
  selfLink: /api/v1/namespaces/monitoring/services/kibana-kb-http
  uid: 55a1198f-d92c-11e9-89f7-be8690a7fdcf
spec:
  clusterIP: 172.16.8.71
  ports:
  - port: 5601
    protocol: TCP
    targetPort: 5601
  selector:
    common.k8s.elastic.co/type: kibana
    kibana.k8s.elastic.co/name: kibana
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
```

仅保留端口和 `selector` 的配置，如果集群支持 `LoadBanlancer` 类型的 service，可以修改 service 的 type 为 `LoadBalancer`:

``` bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: kibana
  namespace: monitoring
spec:
  ports:
  - port: 443
    protocol: TCP
    targetPort: 5601
  selector:
    common.k8s.elastic.co/type: kibana
    kibana.k8s.elastic.co/name: kibana
  type: LoadBalancer
EOF
```

拿到负载均衡器的 IP 地址:

``` bash
$ kubectl -n monitoring get svc
NAME             TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)         AGE
kibana           LoadBalancer   172.16.10.71   150.109.27.60   443:32749/TCP   47s
kibana-kb-http   ClusterIP      172.16.15.39   <none>          5601/TCP        118s
```

在浏览器访问: https://150.109.27.60:443

输入之前部署 elasticsearch 的用户名密码进行登录
