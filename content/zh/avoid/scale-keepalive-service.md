---
title: "解决长连接服务扩容失效"
---

在现网运营中，有很多场景为了提高效率，一般都采用建立长连接的方式来请求。我们发现在客户端以长连接请求服务端的场景下，K8S的自动扩容会失效。原因是客户端长连接一直保留在老的Pod容器中，新扩容的Pod没有新的连接过来，导致K8S按照步长扩容第一批Pod之后就停止了扩容操作，而且新扩容的Pod没能承载请求，进而出现服务过载的情况，自动扩容失去了意义。

对长连接扩容失效的问题，我们的解决方法是将长连接转换为短连接。我们参考了 nginx keepalive 的设计，nginx 中 keepalive_requests 这个配置项设定了一个TCP连接能处理的最大请求数，达到设定值(比如1000)之后服务端会在 http 的 Header 头标记 “`Connection:close`”，通知客户端处理完当前的请求后关闭连接，新的请求需要重新建立TCP连接，所以这个过程中不会出现请求失败，同时又达到了将长连接按需转换为短连接的目的。通过这个办法客户端和云K8S服务端处理完一批请求后不断的更新TCP连接，自动扩容的新Pod能接收到新的连接请求，从而解决了自动扩容失效的问题。

由于Golang并没有提供方法可以获取到每个连接处理过的请求数，我们重写了 `net.Listener` 和 `net.Conn`，注入请求计数器，对每个连接处理的请求做计数，并通过 `net.Conn.LocalAddr()` 获得计数值，判断达到阈值 1000 后在返回的 Header 中插入 “`Connection:close`” 通知客户端关闭连接，重新建立连接来发起请求。以上处理逻辑用 Golang 实现示例代码如下：

``` go
package main

import (
	"net"
	"github.com/gin-gonic/gin"
	"net/http"
)

// 重新定义net.Listener
type counterListener struct {
	net.Listener
}

// 重写net.Listener.Accept(),对接收到的连接注入请求计数器
func (c *counterListener) Accept() (net.Conn, error) {
	conn, err := c.Listener.Accept()
	if err != nil {
		return nil, err
	}
	return &counterConn{Conn: conn}, nil
}

// 定义计数器counter和计数方法Increment()
type counter int

func (c *counter) Increment() int {
	*c++
	return int(*c)
}

// 重新定义net.Conn,注入计数器ct
type counterConn struct {
	net.Conn
	ct counter
}

// 重写net.Conn.LocalAddr()，返回本地网络地址的同时返回该连接累计处理过的请求数
func (c *counterConn) LocalAddr() net.Addr {
	return &counterAddr{c.Conn.LocalAddr(), &c.ct}
}

// 定义TCP连接计数器,指向连接累计请求的计数器
type counterAddr struct {
	net.Addr
	*counter
}

func main() {
	r := gin.New()
	r.Use(func(c *gin.Context) {
		localAddr := c.Request.Context().Value(http.LocalAddrContextKey)
		if ct, ok := localAddr.(interface{ Increment() int }); ok {
			if ct.Increment() >= 1000 {
				c.Header("Connection", "close")
			}
		}
		c.Next()
	})
	r.GET("/", func(c *gin.Context) {
		c.String(200, "plain/text", "hello")
	})
	l, err := net.Listen("tcp", ":8080")
	if err != nil {
		panic(err)
	}
	err = http.Serve(&counterListener{l}, r)
	if err != nil {
		panic(err)
	}
}

```