# 诡异的 No route to host

## 问题反馈

有用户反馈 Deployment 滚动更新的时候，业务日志偶尔会报 "No route to host" 的错误。

## 分析

之前没遇到滚动更新会报 "No route to host" 的问题，我们先看下滚动更新导致连接异常有哪些常见的报错:

* `Connection reset by peer`: 连接被重置。通常是连接建立过，但 server 端发现 client 发的包不对劲就返回 RST，应用层就报错连接被重置。比如在 server 滚动更新过程中，client 给 server 发的请求还没完全结束，或者本身是一个类似 grpc 的多路复用长连接，当 server 对应的旧 Pod 删除(没有做优雅结束，停止时没有关闭连接)，新 Pod 很快创建启动并且刚好有跟之前旧 Pod 一样的 IP，这时 kube-proxy 也没感知到这个 IP 其实已经被删除然后又被重建了，针对这个 IP 的规则就不会更新，旧的连接依然发往这个 IP，但旧 Pod 已经不在了，后面继续发包时依然转发给这个 Pod IP，最终会被转发到这个有相同 IP 的新 Pod 上，而新 Pod 收到此包时检查报文发现不对劲，就返回 RST 给 client 告知将连接重置。针对这种情况，建议应用自身处理好优雅结束：Pod 进入 Terminating 状态后会发送 `SIGTERM` 信号给业务进程，业务进程的代码需处理这个信号，在进程退出前关闭所有连接。
* `Connection refused`: 连接被拒绝。通常是连接还没建立，client 正在发 SYN 包请求建立连接，但到了 server 之后发现端口没监听，内核就返回 RST 包，然后应用层就报错连接被拒绝。比如在 server 滚动更新过程中，旧的 Pod 中的进程很快就停止了(网卡还未完全销毁)，但 client 所在节点的 iptables/ipvs 规则还没更新，包就可能会被转发到了这个停止的 Pod (由于 k8s 的 controller 模式，从 Pod 删除到 service 的 endpoint 更新，再到 kube-proxy watch 到更新并更新 节点上的 iptables/ipvs 规则，这个过程是异步的，中间存在一点时间差，所以有可能存在 Pod 中的进程已经监听，但 iptables/ipvs 规则还没更新的情况)。针对这种情况，建议给容器加一个 preStop，在真正销毁 Pod 之前等待一段时间，留时间给 kube-proxy 更新转发规则，更新完之后就不会再有新连接往这个旧 Pod 转发了，preStop 示例:

  ``` yaml
  lifecycle:
    preStop:
      exec:
        command:
        - /bin/bash
        - -c
        - sleep 30
  ```

  另外，还可能是新的 Pod 启动比较慢，虽然状态已经 Ready，但实际上可能端口还没监听，新的请求被转发到这个还没完全启动的 Pod 就会报错连接被拒绝。针对这种情况，建议给容器加就绪检查 (readinessProbe)，让容器真正启动完之后才将其状态置为 Ready，然后 kube-proxy 才会更新转发规则，这样就能保证新的请求只被转发到完全启动的 Pod，readinessProbe 示例:

  ``` yaml
  readinessProbe:
    httpGet:
      path: /healthz
      port: 80
      httpHeaders:
      - name: X-Custom-Header
        value: Awesome
    initialDelaySeconds: 15
    timeoutSeconds: 1
  ```

* `Connection timed out`: 连接超时。通常是连接还没建立，client 发 SYN 请求建立连接一直等到超时时间都没有收到 ACK，然后就报错连接超时。这个可能场景跟前面 `Connection refused` 可能的场景类似，不同点在于端口有监听，但进程无法正常响应了: 转发规则还没更新，旧 Pod 的进程正在停止过程中，虽然端口有监听，但已经不响应了；或者转发规则更新了，新 Pod 端口也监听了，但还没有真正就绪，还没有能力处理新请求。针对这些情况的建议跟前面一样：加 preStop 和 readinessProbe。

下面我们来继续分析下滚动更新时发生 `No route to host` 的可能情况。

这个报错很明显，IP 无法路由，通常是将报文发到了一个已经彻底销毁的 Pod (网卡已经不在)。不可能发到一个网卡还没创建好的 Pod，因为即便不加存活检查，也是要等到 Pod 网络初始化完后才可能 Ready，然后 kube-proxy 才会更新转发规则。

什么情况下会转发到一个已经彻底销毁的 Pod？ 借鉴前面几种滚动更新的报错分析，我们推测应该是 Pod 很快销毁了但转发规则还没更新，从而新的请求被转发了这个已经销毁的 Pod，最终报文到达这个 Pod 所在 PodCIDR 的 Node 上时，Node 发现本机已经没有这个 IP 的容器，然后 Node 就返回 ICMP 包告知 client 这个 IP 不可达，client 收到 ICMP 后，应用层就会报错 "No route to host"。

所以根据我们的分析，关键点在于 Pod 销毁太快，转发规则还没来得及更新，导致后来的请求被转发到已销毁的 Pod。针对这种情况，我们可以给容器加一个 preStop，留时间给 kube-proxy 更新转发规则来解决，参考 《Kubernetes实践指南》中的部分章节: https://k8s.imroc.io/best-practice/high-availability-deployment-of-applications#smooth-update-using-prestophook-and-readinessprobe

## 问题没有解决

我们自己没有复现用户的 "No route to host" 的问题，可能是复现条件比较苛刻，最后将我们上面理论上的分析结论作为解决方案给到了用户。

但用户尝试加了 preStop 之后，问题依然存在，服务滚动更新时偶尔还是会出现 "No route to host"。

## 深入分析

为了弄清楚根本原因，我们请求用户协助搭建了一个可以复现问题的测试环境，最终这个问题在测试环境中可以稳定复现。

仔细观察，实际是部署两个服务：ServiceA 和 ServiceB。使用 ab 压测工具去压测 ServiceA （短连接），然后 ServiceA 会通过 RPC 调用 ServiceB (短连接)，滚动更新的是 ServiceB，报错发生在 ServiceA 调用 ServiceB 这条链路。

在 ServiceB 滚动更新期间，新的 Pod Ready 了之后会被添加到 IPVS 规则的 RS 列表，但旧的 Pod 不会立即被踢掉，而是将新的 Pod 权重置为1，旧的置为 0，通过在 client 所在节点查看 IPVS 规则可以看出来:

``` bash
root@VM-0-3-ubuntu:~# ipvsadm -ln -t 172.16.255.241:80
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  172.16.255.241:80 rr
  -> 172.16.8.106:80              Masq    0      5          14048
  -> 172.16.8.107:80              Masq    1      2          243
```

为什么不立即踢掉旧的 Pod 呢？因为要支持优雅结束，让存量的连接处理完，等存量连接全部结束了再踢掉它(ActiveConn+InactiveConn=0)，这个逻辑可以通过这里的代码确认：https://github.com/kubernetes/kubernetes/blob/v1.17.0/pkg/proxy/ipvs/graceful_termination.go#L170

然后再通过 `ipvsadm -lnc | grep 172.16.8.106` 发现旧 Pod 上的连接大多是 `TIME_WAIT` 状态，这个也容易理解：因为 ServiceA 作为 client 发起短连接请求调用 ServiceB，调用完成就会关闭连接，TCP 三次挥手后进入 `TIME_WAIT` 状态，等待 2*MSL (2 分钟) 的时长再清理连接。

经过上面的分析，看起来都是符合预期的，那为什么还会出现 "No route to host" 呢？难道权重被置为 0 之后还有新连接往这个旧 Pod 转发？我们来抓包看下：

``` bash
root@VM-0-3-ubuntu:~# tcpdump -i eth0 host 172.16.8.106 -n -tttt
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
2019-12-13 11:49:47.319093 IP 10.0.0.3.36708 > 172.16.8.106.80: Flags [S], seq 3988339656, win 29200, options [mss 1460,sackOK,TS val 3751111666 ecr 0,nop,wscale 9], length 0
2019-12-13 11:49:47.319133 IP 10.0.0.3.36706 > 172.16.8.106.80: Flags [S], seq 109196945, win 29200, options [mss 1460,sackOK,TS val 3751111666 ecr 0,nop,wscale 9], length 0
2019-12-13 11:49:47.319144 IP 10.0.0.3.36704 > 172.16.8.106.80: Flags [S], seq 1838682063, win 29200, options [mss 1460,sackOK,TS val 3751111666 ecr 0,nop,wscale 9], length 0
2019-12-13 11:49:47.319153 IP 10.0.0.3.36702 > 172.16.8.106.80: Flags [S], seq 1591982963, win 29200, options [mss 1460,sackOK,TS val 3751111666 ecr 0,nop,wscale 9], length 0
```

果然是！即使权重为 0，仍然会尝试发 SYN 包跟这个旧 Pod 建立连接，但永远无法收到 ACK，因为旧 Pod 已经销毁了。为什么会这样呢？难道是 IPVS 内核模块的调度算法有问题？尝试去看了下 linux 内核源码，并没有发现哪个调度策略的实现函数会将新连接调度到权重为 0 的 rs 上。

这就奇怪了，可能不是调度算法的问题？继续尝试看更多的代码，主要是 `net/netfilter/ipvs/ip_vs_core.c` 中的 `ip_vs_in` 函数，也就是 IPVS 模块处理报文的主要入口，发现它会先在本地连接转发表看这个包是否已经有对应的连接了（匹配五元组），如果有就说明它不是新连接也就不会调度，直接发给这个连接对应的之前已经调度过的 rs (也不会判断权重)；如果没匹配到说明这个包是新的连接，就会走到调度这里 (rr, wrr 等调度策略)，这个逻辑看起来也没问题。

那为什么会转发到权重为 0 的 rs ？难道是匹配连接这里出问题了？新的连接匹配到了旧的连接？我开始做实验验证这个猜想，修改一下这里的逻辑：检查匹配到的连接对应的 rs 如果权重为 0，则重新调度。然后重新编译和加载 IPVS 内核模块，再重新压测一下，发现问题解决了！没有报 "No route to host" 了。

虽然通过改内核源码解决了，但我知道这不是一个好的解决方案，它会导致 IPVS 不支持连接的优雅结束，因为不再转发包给权重为 0 的 rs，存量的连接就会立即中断。

继续陷入深思......

这个实验只是证明了猜想：新连接匹配到了旧连接。那为什么会这样呢？难道新连接报文的五元组跟旧连接的相同了？

经过一番思考，发现这个是有可能的。因为 ServiceA 作为 client 请求 ServiceB，不同请求的源 IP 始终是相同的，关键点在于源端口是否可能相同。由于 ServiceA 向 ServiceB 发起大量短连接，ServiceA 所在节点就会有大量 `TIME_WAIT` 状态的连接，需要等 2 分钟 (2*MSL) 才会清理，而由于连接量太大，每次发起的连接都会占用一个源端口，当源端口不够用了，就会重用 `TIME_WAIT` 状态连接的源端口，这个时候当报文进入 IPVS 模块，检测到它的五元组跟本地连接转发表中的某个连接一致(`TIME_WAIT` 状态)，就以为它是一个存量连接，然后直接将报文转发给这个连接之前对应的 rs 上，然而这个 rs 对应的 Pod 早已销毁，所以抓包看到的现象是将 SYN 发给了旧 Pod，并且无法收到 ACK，伴随着返回 ICMP 告知这个 IP 不可达，也被应用解释为 "No route to host"。

后来无意间又发现一个还在 open 状态的 issue，虽然还没提到 "No route to host" 关键字，但讨论的跟我们这个其实是同一个问题。我也参与了讨论，有兴趣的同学可以看下：https://github.com/kubernetes/kubernetes/issues/81775

## 总结

这个问题通常发生的场景就是类似于我们测试环境这种：ServiceA 对外提供服务，当外部发起请求，ServiceA 会通过 rpc 或 http 调用 ServiceB，如果外部请求量变大，ServiceA 调用 ServiceB 的量也会跟着变大，大到一定程度，ServiceA 所在节点源端口不够用，复用 `TIME_WAIT` 状态连接的源端口，导致五元组跟 IPVS 里连接转发表中的 `TIME_WAIT` 连接相同，IPVS 就认为这是一个存量连接的报文，就不判断权重直接转发给之前的 rs，导致转发到已销毁的 Pod，从而发生 "No route to host"。

如何规避？集群规模小可以使用 iptables 模式，如果需要使用 ipvs 模式，可以增加 ServiceA 的副本，并且配置反亲和性 (podAntiAffinity)，让 ServiceA 的 Pod 部署到不同节点，分摊流量，避免流量集中到某一个节点，导致调用 ServiceB 时源端口复用。

如何彻底解决？暂时还没有一个完美的方案。

Issue 85517 讨论让 kube-proxy 支持自定义配置几种连接状态的超时时间，但这对 `TIME_WAIT` 状态无效。

Issue 81308 讨论 IVPS 的优雅结束是否不考虑不活跃的连接 (包括 `TIME_WAIT` 状态的连接)，也就是只考虑活跃连接，当活跃连接数为 0 之后立即踢掉 rs。这个确实可以更快的踢掉 rs，但无法让优雅结束做到那么优雅了，并且有人测试了，即便是不考虑不活跃连接，当请求量很大，还是不能很快踢掉 rs，因为源端口复用还是会导致不断有新的连接占用旧的连接，在较新的内核版本，`SYN_RECV` 状态也被视为活跃连接，所以活跃连接数还是不会很快降到 0。

这个问题的终极解决方案该走向何方，我们拭目以待，感兴趣的同学可以持续关注 issue 81775 并参与讨论。想学习更多 K8S 知识，可以关注本人的开源书《Kubernetes实践指南》: https://k8s.imroc.io