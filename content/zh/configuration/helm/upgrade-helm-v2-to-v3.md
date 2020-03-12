---
title: "Helm V2 迁移到 V3"
weight: 3
---

Helm V3 与 V2 版本架构变化较大，数据迁移比较麻烦，官方提供了一个名为 `helm-2to3` 的插件来简化迁移工作，本文将介绍如何利用此插件迁移 Helm V2 到 V3 版本。这里前提是 Helm V3 已安装，安装方法请参考 [这里](../install-helm/)。

## 安装 2to3 插件

一键安装:

```bash
$ helm3 plugin install https://github.com/helm/helm-2to3
Downloading and installing helm-2to3 v0.1.1 ...
https://github.com/helm/helm-2to3/releases/download/v0.1.1/helm-2to3_0.1.1_linux_amd64.tar.gz
Installed plugin: 2to3
```

检查插件是否安装成功:

```bash
$ helm3 plugin list
NAME    VERSION    DESCRIPTION
2to3    0.1.1      migrate Helm v2 configuration and releases in-place to Helm v3
```

## 迁移 Helm V2 配置

```bash
$ helm3 2to3 move config
[Helm 2] Home directory: /root/.helm
[Helm 3] Config directory: /root/.config/helm
[Helm 3] Data directory: /root/.local/share/helm
[Helm 3] Create config folder "/root/.config/helm" .
[Helm 3] Config folder "/root/.config/helm" created.
[Helm 2] repositories file "/root/.helm/repository/repositories.yaml" will copy to [Helm 3] config folder "/root/.config/helm/repositories.yaml" .
[Helm 2] repositories file "/root/.helm/repository/repositories.yaml" copied successfully to [Helm 3] config folder "/root/.config/helm/repositories.yaml" .
[Helm 3] Create data folder "/root/.local/share/helm" .
[Helm 3] data folder "/root/.local/share/helm" created.
[Helm 2] plugins "/root/.helm/plugins" will copy to [Helm 3] data folder "/root/.local/share/helm/plugins" .
[Helm 2] plugins "/root/.helm/plugins" copied successfully to [Helm 3] data folder "/root/.local/share/helm/plugins" .
[Helm 2] starters "/root/.helm/starters" will copy to [Helm 3] data folder "/root/.local/share/helm/starters" .
[Helm 2] starters "/root/.helm/starters" copied successfully to [Helm 3] data folder "/root/.local/share/helm/starters" .
```

上面的操作主要是迁移:

* Chart 仓库
* Helm 插件
* Chart starters

检查下 repo 和 plugin:

```bash
$ helm3 repo list
NAME      URL
stable    https://kubernetes-charts.storage.googleapis.com
local     http://127.0.0.1:8879/charts
$
$
$ helm3 plugin list
NAME    VERSION    DESCRIPTION
2to3    0.1.1      migrate Helm v2 configuration and releases in-place to Helm v3
push    0.1.1      Push chart package to TencentHub
```

## 迁移 Heml V2 Release

已经用 Helm V2 部署的应用也可以使用 `2to3` 的 `convert` 子命令迁移到 V3，先看下有哪些选项:

```bash
$ helm3 2to3 convert --help
migrate Helm v2 release in-place to Helm v3

Usage:
  2to3 convert [flags] RELEASE

Flags:
      --delete-v2-releases       v2 releases are deleted after migration. By default, the v2 releases are retained
      --dry-run                  simulate a convert
  -h, --help                     help for convert
  -l, --label string             label to select tiller resources by (default "OWNER=TILLER")
  -s, --release-storage string   v2 release storage type/object. It can be 'secrets' or 'configmaps'. This is only used with the 'tiller-out-cluster' flag (default "secrets")
  -t, --tiller-ns string         namespace of Tiller (default "kube-system")
      --tiller-out-cluster       when  Tiller is not running in the cluster e.g. Tillerless
```

* `--tiller-out-cluster`: 如果你的 Helm V2 是 tiller 在集群外面 \(tillerless\) 的安装方式，请带上这个参数
* `--dry-run`: 模拟迁移但不做真实迁移操作，建议每次迁移都先带上这个参数测试下效果，没问题的话再去掉这个参数做真实迁移
* `--tiller-ns`: 通常 tiller 如果部署在集群中，并且不在 `kube-system` 命名空间才指定

看下目前有哪些 helm v2 的 release:

```bash
$ helm ls
NAME     REVISION    UPDATED                     STATUS      CHART          APP VERSION    NAMESPACE
redis    1           Mon Sep 16 14:46:58 2019    DEPLOYED    redis-9.1.3    5.0.5          default
```

选一个用 `--dry-run` 试下效果:

```bash
$ helm3 2to3 convert redis --dry-run
NOTE: This is in dry-run mode, the following actions will not be executed.
Run without --dry-run to take the actions described below:

Release "redis" will be converted from Helm 2 to Helm 3.
[Helm 3] Release "redis" will be created.
[Helm 3] ReleaseVersion "redis.v1" will be created.
```

没有报错，去掉 `--dry-run` 执行迁移:

```bash
$ helm3 2to3 convert redis
Release "redis" will be converted from Helm 2 to Helm 3.
[Helm 3] Release "redis" will be created.
[Helm 3] ReleaseVersion "redis.v1" will be created.
[Helm 3] ReleaseVersion "redis.v1" created.
[Helm 3] Release "redis" created.
Release "redis" was converted successfully from Helm 2 to Helm 3. Note: the v2 releases still remain and should be removed to avoid conflicts with the migrated v3 releases.
```

检查迁移结果:

```bash
$ helm ls
NAME     REVISION    UPDATED                     STATUS      CHART          APP VERSION    NAMESPACE
redis    1           Mon Sep 16 14:46:58 2019    DEPLOYED    redis-9.1.3    5.0.5          default
$
$
$ helm3 ls -a
NAME     NAMESPACE    REVISION    UPDATED                                    STATUS      CHART
redis    default      1           2019-09-16 06:46:58.541391356 +0000 UTC    deployed    redis-9.1.3
```

* helm 3 的 release 区分了命名空间，带上 `-a` 参数展示所有命名空间的 release

## 参考资料

* How to migrate from Helm v2 to Helm v3: [https://helm.sh/blog/migrate-from-helm-v2-to-helm-v3/](https://helm.sh/blog/migrate-from-helm-v2-to-helm-v3/)

