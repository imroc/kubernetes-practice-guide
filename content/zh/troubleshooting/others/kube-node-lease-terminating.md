---
title: "kube-node-lease namespace 卡在 Terminating"
state: Alpha
---

## 原因

可能是勿删 ns，删除 kube-node-lease 后，ns 一直卡在 Terminating 状态。通常是存在 finalizers，通过 `kubectl get ns kube-node-lease -o yaml` 可以看到是否有 finalizers:

``` bash
$ kubectl get ns -o yaml kube-node-lease
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    openpitrix_runtime: runtime-9M5z8pAzL8ox
  creationTimestamp: "2019-11-11T06:09:09Z"
  deletionGracePeriodSeconds: 0
  deletionTimestamp: "2020-03-17T02:25:02Z"
  finalizers:
  - finalizers.kubesphere.io/namespaces
  labels:
    kubesphere.io/workspace: system-workspace
  name: kube-node-lease
  ownerReferences:
  - apiVersion: tenant.kubesphere.io/v1alpha1
    blockOwnerDeletion: true
    controller: true
    kind: Workspace
    name: system-workspace
    uid: d4310acd-1fdc-11ea-a370-a2c490b9ae47
  resourceVersion: "1239449686"
  selfLink: /api/v1/namespaces/kube-node-lease
  uid: c63ce63a-0449-11ea-9b80-6aa4eb51927f
spec: {}
```

此例是因为之前装过 kubesphere，然后卸载了，但没有清理 finalizers，将其删除就可以了。

## 拓展

k8s 资源的 metadata 里如果存在 finalizers，那么该资源一般是由某应用创建的，或者是这个资源是此应用关心的。应用会在资源的 metadata 里的 finalizers 加了一个它自己可以识别的标识，这意味着这个资源被删除时需要由此应用来做删除前的清理，清理完了它需要将标识从该资源的 finalizers 中移除，然后才会最终彻底删除资源。比如 Rancher 创建的一些资源就会写入 finalizers 标识。

如果应用被删除，而finalizer没清理，删除资源时就会一直卡在terminating，可以手动删除finalizer来解决。

## 参考资料

* Node Lease 的 Proposal: https://github.com/kubernetes/enhancements/blob/master/keps/sig-node/0009-node-heartbeat.md