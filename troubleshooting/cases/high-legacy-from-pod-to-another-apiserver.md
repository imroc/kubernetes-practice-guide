# Pod 访问另一个集群的 apiserver 有延时

现象：集群 a 的 Pod 内通过 kubectl 访问集群 b 的内网地址，偶尔出现延时的情况，但直接在宿主机上用同样的方法却没有这个问题。

提炼环境和现象精髓:

1. 在 pod 内将另一个集群 apiserver 的 ip 写到了 hosts，因为 TKE apiserver 开启内网集群外内网访问创建的内网 LB 暂时没有支持自动绑内网 DNS 域名解析，所以集群外的内网访问 apiserver 需要加 hosts
2. pod 内执行 kubectl 访问另一个集群偶尔延迟 5s，有时甚至10s

观察到 5s 延时，感觉跟之前 conntrack 的丢包导致 [DNS 解析 5S 延时](/troubleshooting/cases/dns-lookup-5s-delay.md) 有关，但是加了 hosts 呀，怎么还去解析域名？

进入 pod netns 抓包: 执行 kubectl 时确实有 dns 解析，并且发生延时的时候 dns 请求没有响应然后做了重试。

看起来延时应该就是之前已知 conntrack 丢包导致 dns 5s 超时重试导致的。但是为什么会去解析域名? 明明配了 hosts 啊，正常情况应该是优先查找 hosts，没找到才去请求 dns 呀，有什么配置可以控制查找顺序?

搜了一下发现: `/etc/nsswitch.conf` 可以控制，但看有问题的 pod 里没有这个文件。然后观察到有问题的 pod 用的 alpine 镜像，试试其它镜像后发现只有基于 alpine 的镜像才会有这个问题。

再一搜发现: musl libc 并不会使用 `/etc/nsswitch.conf` ，也就是说 alpine 镜像并没有实现用这个文件控制域名查找优先顺序，瞥了一眼 musl libc 的 `gethostbyname` 和 `getaddrinfo` 的实现，看起来也没有读这个文件来控制查找顺序，写死了先查 hosts，没找到再查 dns。

这么说，那还是该先查 hosts 再查 dns 呀，为什么这里抓包看到是先查的 dns? (如果是先查 hosts 就能命中查询，不会再发起dns请求)

访问 apiserver 的 client 是 kubectl，用 go 写的，会不会是 go 程序解析域名时压根没调底层 c 库的 `gethostbyname` 或 `getaddrinfo`?

搜一下发现果然是这样: go runtime 用 go 实现了 glibc 的 `getaddrinfo` 的行为来解析域名，减少了 c 库调用 (应该是考虑到减少 cgo 调用带来的的性能损耗)

issue: [net: replicate DNS resolution behaviour of getaddrinfo(glibc) in the go dns resolver](https://github.com/golang/go/issues/18518)

翻源码验证下:

Unix 系的 OS 下，除了 openbsd， go runtime 会读取 `/etc/nsswitch.conf` (`net/conf.go`):

``` go
if runtime.GOOS != "openbsd" {
	confVal.nss = parseNSSConfFile("/etc/nsswitch.conf")
}
```

`hostLookupOrder` 函数决定域名解析顺序的策略，Linux 下，如果没有 `nsswitch.conf` 文件就 dns 比 hosts 文件优先 (`net/conf.go`):

``` go
// hostLookupOrder determines which strategy to use to resolve hostname.
// The provided Resolver is optional. nil means to not consider its options.
func (c *conf) hostLookupOrder(r *Resolver, hostname string) (ret hostLookupOrder) {
    ......
	// If /etc/nsswitch.conf doesn't exist or doesn't specify any
	// sources for "hosts", assume Go's DNS will work fine.
	if os.IsNotExist(nss.err) || (nss.err == nil && len(srcs) == 0) {
        ......
		if c.goos == "linux" {
			// glibc says the default is "dns [!UNAVAIL=return] files"
			// https://www.gnu.org/software/libc/manual/html_node/Notes-on-NSS-Configuration-File.html.
			return hostLookupDNSFiles
		}
		return hostLookupFilesDNS
	}
```

可以看到 `hostLookupDNSFiles` 的意思是 dns first (`net/dnsclient_unix.go`):

``` go
// hostLookupOrder specifies the order of LookupHost lookup strategies.
// It is basically a simplified representation of nsswitch.conf.
// "files" means /etc/hosts.
type hostLookupOrder int

const (
	// hostLookupCgo means defer to cgo.
	hostLookupCgo      hostLookupOrder = iota
	hostLookupFilesDNS                 // files first
	hostLookupDNSFiles                 // dns first
	hostLookupFiles                    // only files
	hostLookupDNS                      // only DNS
)

var lookupOrderName = map[hostLookupOrder]string{
	hostLookupCgo:      "cgo",
	hostLookupFilesDNS: "files,dns",
	hostLookupDNSFiles: "dns,files",
	hostLookupFiles:    "files",
	hostLookupDNS:      "dns",
}
```

所以虽然 alpine 用的 musl libc 不是 glibc，但 go 程序解析域名还是一样走的 glibc 的逻辑，而 alpine 没有 `/etc/nsswitch.conf` 文件，也就解释了为什么 kubectl 访问 apiserver 先做 dns 解析，没解析到再查的 hosts，导致每次访问都去请求 dns，恰好又碰到 conntrack 那个丢包问题导致 dns 5s 延时，在用户这里表现就是 pod 内用 kubectl 访问 apiserver 偶尔出现 5s 延时，有时出现 10s 是因为重试的那次 dns 请求刚好也遇到 conntrack 丢包导致延时又叠加了 5s 。

解决方案:

1. 换基础镜像，不用 alpine
2. 挂载 `nsswitch.conf` 文件 (可以用 hostPath)
