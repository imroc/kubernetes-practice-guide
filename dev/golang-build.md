# Go 语言编译原理与优化

## 编译阶段 (Compilation)

### debug 参数

`-m` 打印编译器更多想法的细节

``` bash
-gcflags '-m'
```

`-S` 打印汇编

``` bash
-gcflags '-S'
```

### 优化和内联

默认开启了优化和内联，但是debug的时候开启可能会出现一些奇怪的问题，通过下面的参数可以禁止任何优化

``` bash
-gcflags '-N -l'
```

内联级别：

- `-gcflags='-l -l'` 内联级别2，更积极，可能更快，可能会制作更大的二进制文件。
- `-gcflags='-l -l -l'` 内联级别3，再次更加激进，二进制文件肯定更大，也许更快，但也许会有 bug。
- `-gcflags=-l=4` (4个-l)在 Go 1.11 中将支持实验性的[中间栈内联优化](https://github.com/golang/go/issues/19348)。

### 逃逸分析

- 如果一个局部变量值超越了函数调用的生命周期，编译器自动将它逃逸到堆
- 如果一个通过new或make来分配的对象，在函数内即使将指针传递给了其它函数，其它函数会被内联到当前函数，相当于指针不会逃逸出本函数，最终不返回指针的话，该指针对应的值也都会分配在栈上，而不是在堆

## 链接阶段 (Linking)

- Go 支持 internal 和 external 两种链接方式: internal 使用 go 自身实现的 linker，external 需要启动外部的 linker
- linker 的主要工作是将 `.o` (object file) 链接成最终可执行的二进制
- 对应命令: `go tool link`，对应源码: `$GOROOT/src/cmd/link`
- 通过 `-ldflags` 给链接器传参，参数详见: `go tool link --help`

### 关于 CGO

- 启用cgo可以调用外部依赖的c库
- go的编译器会判断环境变量 `CGO_ENABLED` 来决定是否启用cgo，默认 `CGO_ENABLED=1` 即启用cgo
- 源码文件头部的 `build tag` 可以根据cgo是否启用决定源码是否被编译(`// +build cgo` 表示希望cgo启用时被编译，相反的是 `// +build !cgo`)
- 标准库中有部分实现有两份源码，比如: `$GOROOT/src/os/user/lookup_unix.go` 和 `$GOROOT/src/os/user/cgo_lookup_unix.go` ，它们有相同的函数，但实现不一样，前者是纯go实现，后者是使用cgo调用外部依赖来实现，标准库中使用cgo比较常见的是 `net` 包。

### internal linking

- link 默认使用 internal 方式
- 直接使用 go 本身的实现的 linker 来链接代码，
- 功能比较简单，仅仅是将 `.o` 和预编译的 `.a` 写到最终二进制文件中(`.a`文件在 `$GOROOT/pkg` 和 `$GOPATH/pkg` 中，其实就是`.o`文件打包的压缩包，通过 `tar -zxvf` 可以解压出来查看)

### external linking

- 会启动外部 linker (gcc/clang)，通过 `-ldflags '-linkmode "external"'` 启用 external linking
- 通过 `-extldflags` 给外部 linker 传参，比如： `-ldflags '-linkmode "external" -extldflags "-static"'`

### static link

go编译出来就是一个二进制，自带runtime，不需要解释器，但并不意味着就不需要任何依赖，但也可以通过静态链接来做到完全不用任何依赖，全部”揉“到一个二进制文件中。实现静态链接的方法：

- 如果是 `external linking`，可以这样: `-ldflags '-linkmode external -extldflags -static'`
- 如果用默认的 `internal linking`，可以这样: `-ldflags '-d'`

### ldflags 其它常用参数

- `-s -w` 是去除符号表和DWARF调试信息(可以减小二进制体积，但不利于调试，可在用于生产环境)，示例: `-ldflags '-s -w'`
- `-X` 可以给变量注入值，比如编译时用脚本动态注入当前版本和 `commit id` 到代码的变量中，通常程序的 `version` 子命令或参数输出当前版本信息时就用这种方式实现，示例：`-ldflags '-X myapp/pkg/version/version=v1.0.0'`

## 使用 Docker 编译

使用 Docker 编译可以不用依赖本机 go 环境，将编译环境标准化，特别在有外部动态链接库依赖的情况下很有用，可以直接 run 一个容器来编译，给它挂载源码目录和二进制输出目录，这样我们就可以拿到编译出来的二进制了，这里以编译cfssl为例:

``` bash
ROOT_PKG=github.com/cloudflare/cfssl
CMD_PKG=$ROOT_PKG/cmd
LOCAL_SOURCE_PATH=/Users/roc/go/src/$ROOT_PKG
LOCAL_OUTPUT_PATH=$PWD
GOPATH=/go/src
ROOT_PATH=$GOPATH/$ROOT_PKG
CMD_PATH=$GOPATH/$CMD_PKG
docker run --rm \
  -v $LOCAL_SOURCE_PATH:$ROOT_PATH \
  -v $LOCAL_OUTPUT_PATH:/output \
  -w $ROOT_PATH \
  golang:1.13 \
  go build -v \
  -ldflags '-d' \
  -o /output/ \
  $CMD_PATH/...
```

编译镜像可以参考下面示例（使用docker多阶段构建，完全静态编译，没有外部依赖）:

``` dockerfile
FROM golang:1.12-stretch as builder
MAINTAINER rockerchen@tencent.com
ENV BUILD_DIR /go/src/cloud.tencent.com/qc_container_cluster/hpa-metrics-server
WORKDIR $BUILD_DIR

COPY ./ $BUILD_DIR
RUN CGO_ENABLED=0 go build -v -o /hpa-metrics-server \
    -ldflags '-d' \
    ./

FROM ubuntu:16.04
MAINTAINER rockerchen@tencent.com
RUN apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y curl iproute2 inetutils-tools telnet inetutils-ping
RUN apt-get install --no-install-recommends --no-install-suggests ca-certificates -y
COPY --from=builder /hpa-metrics-server /hpa-metrics-server
RUN chmod a+x /hpa-metrics-server
```

## 参考资料

* Go 性能调优之 —— 编译优化: https://segmentfault.com/a/1190000016354799
