# tcp\_tw\_recycle 引发丢包

`tcp_tw_recycle` 这个内核参数用来快速回收 `TIME_WAIT` 连接，不过如果在 NAT 环境下会引发问题。

RFC1323 中有如下一段描述：

`An additional mechanism could be added to the TCP, a per-host cache of the last timestamp received from any connection. This value could then be used in the PAWS mechanism to reject old duplicate segments from earlier incarnations of the connection, if the timestamp clock can be guaranteed to have ticked at least once since the old connection was open. This would require that the TIME-WAIT delay plus the RTT together must be at least one tick of the sender’s timestamp clock. Such an extension is not part of the proposal of this RFC.`

* 大概意思是说TCP有一种行为，可以缓存每个连接最新的时间戳，后续请求中如果时间戳小于缓存的时间戳，即视为无效，相应的数据包会被丢弃。
* Linux是否启用这种行为取决于tcp\_timestamps和tcp\_tw\_recycle，因为tcp\_timestamps缺省就是开启的，所以当tcp\_tw\_recycle被开启后，实际上这种行为就被激活了，当客户端或服务端以NAT方式构建的时候就可能出现问题，下面以客户端NAT为例来说明：
* 当多个客户端通过NAT方式联网并与服务端交互时，服务端看到的是同一个IP，也就是说对服务端而言这些客户端实际上等同于一个，可惜由于这些客户端的时间戳可能存在差异，于是乎从服务端的视角看，便可能出现时间戳错乱的现象，进而直接导致时间戳小的数据包被丢弃。如果发生了此类问题，具体的表现通常是是客户端明明发送的SYN，但服务端就是不响应ACK。
* 在4.12之后的内核已移除tcp\_tw\_recycle内核参数: [https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=4396e46187ca5070219b81773c4e65088dac50cc](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=4396e46187ca5070219b81773c4e65088dac50cc) [https://github.com/torvalds/linux/commit/4396e46187ca5070219b81773c4e65088dac50cc](https://github.com/torvalds/linux/commit/4396e46187ca5070219b81773c4e65088dac50cc)

