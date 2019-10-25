# 实用命令与脚本

获取集群所有节点占用的 podCIDR:

``` bash
$ kubectl get node -o jsonpath='{range .items[*]}{@.spec.podCIDR}{"\n"}{end}'
172.16.4.0/24
172.16.0.0/24
172.16.6.0/24
```
