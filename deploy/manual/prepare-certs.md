# 准备证书

我们使用 [cfssl](https://github.com/cloudflare/cfssl) 来生成证书

## 安装 cfssl

本步骤将会安装命令 `cfssl` 和 `cfssljson` 两个命令。

### 方式一: 直接下载安装二进制包

编译好的二进制包可以在这里找到: https://pkg.cfssl.org

根据自己的 OS 与 CPU 架构组合找到响应的二进制包，下载安装到 `PATH` 下，绝大多数情况下我们都是用的 `linux-amd64`，以这个为例:

``` bash
curl -o cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 \
  && curl -o cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 \
  && chmod +x cfssl cfssljson \
  && sudo mv cfssl cfssljson /usr/local/bin/
```

通过 go 命令安装，要求 go 版本在 1.12 以上并且合理配置了 `GOPATH`:

``` bash
go get -u github.com/cloudflare/cfssl/cmd/cfssl
go get -u github.com/cloudflare/cfssl/cmd/cfssljson
```

> cfssl 和 cfssljson 命令将会安装到 `$GOPATH/bin` 目录下，确保这个目录被添加到了 `PATH`
