---
title: "泛域名动态转发 Service"
---

## 需求

集群对外暴露了一个公网IP作为流量入口\(可以是 Ingress 或 Service\)，DNS 解析配置了一个泛域名指向该IP（比如 `*.test.imroc.io`），现希望根据请求中不同 Host 转发到不同的后端 Service。比如 `a.test.imroc.io` 的请求被转发到 `my-svc-a`，`b.test.imroc.io` 的请求转发到 `my-svc-b`。当前 K8S 的 Ingress 并不原生支持这种泛域名转发规则，本文将给出一个解决方案来实现泛域名转发。

## 简单做法

先说一种简单的方法，这也是大多数人的第一反应：**配置 Ingress 规则**

假如泛域名有两个不同 Host 分别转发到不同 Service，Ingress 类似这样写:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: my-ingress
spec:
  rules:
  - host: a.test.imroc.io
    http:
      paths:
      - backend:
          serviceName: my-svc-a
          servicePort: 80
        path: /
  - host: b.test.imroc.io
    http:
      paths:
      - backend:
          serviceName: my-svc-b
          servicePort: 80
        path: /
```

但是！如果 Host 非常多会怎样？（比如200+）

* 每次新增 Host 都要改 Ingress 规则，太麻烦
* 单个 Ingress 上面的规则越来越多，更改规则对 LB 的压力变大，可能会导致偶尔访问不了

## 正确姿势

我们可以约定请求中泛域名 Host 通配符的 `*` 号匹配到的字符跟 Service 的名字相关联（可以是相等，或者 Service 统一在前面加个前缀，比如 `a.test.imroc.io` 转发到 `my-svc-a` 这个 Service\)，集群内起一个反向代理服务，匹配泛域名的请求全部转发到这个代理服务上，这个代理服务只做一件简单的事，解析 Host，正则匹配抓取泛域名中 `*` 号这部分，把它转换为 Service 名字，然后在集群里转发（集群 DNS 解析\)

这个反向代理服务可以是 Nginx+Lua脚本 来实现，或者自己写个简单程序来做反向代理，这里我用 [OpenResty](https://openresty.org) 来实现，它可以看成是 Nginx 的发行版，自带 lua 支持。

有几点需要说明下：

* 我们使用 nginx 的  `proxy_pass` 来反向代理到后端服务，`proxy_pass` 后面跟的变量，我们需要用 lua 来判断 Host 修改变量
* nginx 的 `proxy_pass` 后面跟的如果是可变的域名（非IP，需要 dns 解析\)，它需要一个域名解析器，不会走默认的 dns 解析，需要在 `nginx.conf` 里添加 `resolver` 配置项来设置一个外部的 dns 解析器
* 这个解析器我们是用 go-dnsmasq 来实现，它可以将集群的 dns 解析代理给 nginx，以 sidecar 的形式注入到 pod 中，监听 53 端口

`nginx.conf` 里关键的配置如下图所示：

![nginx.conf](https://imroc.io/assets/blog/nginx-wilcard-conf.png)

下面给出完整的 yaml 示例

`proxy.yaml`:

```yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  labels:
    component: nginx
  name: proxy
spec:
  replicas: 1
  selector:
    matchLabels:
      component: nginx
  template:
    metadata:
      labels:
        component: nginx
    spec:
      containers:
      - name: nginx
        image: "openresty/openresty:centos"
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
        volumeMounts:
        - mountPath: /usr/local/openresty/nginx/conf/nginx.conf
          name: config
          subPath: nginx.conf
      - name: dnsmasq
        image: "janeczku/go-dnsmasq:release-1.0.7"
        args:
          - --listen
          - "127.0.0.1:53"
          - --default-resolver
          - --append-search-domains
          - --hostsfile=/etc/hosts
          - --verbose
      volumes:
      - name: config
        configMap:
          name: configmap-nginx

---

apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    component: nginx
  name: configmap-nginx
data:
  nginx.conf: |-
    worker_processes  1;

    error_log  /error.log;

    events {
        accept_mutex on;
        multi_accept on;
        use epoll;
        worker_connections  1024;
    }


    http {
        include       mime.types;
        default_type  application/octet-stream;
        log_format  main  '$time_local $remote_user $remote_addr $host $request_uri $request_method $http_cookie '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for" '
                          '$request_time $upstream_response_time "$upstream_cache_status"';

        log_format  browser '$time_iso8601 $cookie_km_uid $remote_addr $host $request_uri $request_method '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for" '
                          '$request_time $upstream_response_time "$upstream_cache_status" $http_x_requested_with $http_x_real_ip $upstream_addr $request_body';

        log_format client '{"@timestamp":"$time_iso8601",'
                          '"time_local":"$time_local",'
                          '"remote_user":"$remote_user",'
                          '"http_x_forwarded_for":"$http_x_forwarded_for",'
                          '"host":"$server_addr",'
                          '"remote_addr":"$remote_addr",'
                          '"http_x_real_ip":"$http_x_real_ip",'
                          '"body_bytes_sent":$body_bytes_sent,'
                          '"request_time":$request_time,'
                          '"status":$status,'
                          '"upstream_response_time":"$upstream_response_time",'
                          '"upstream_response_status":"$upstream_status",'
                          '"request":"$request",'
                          '"http_referer":"$http_referer",'
                          '"http_user_agent":"$http_user_agent"}';

        access_log  /access.log  main;

        sendfile        on;

        keepalive_timeout 120s 100s;
        keepalive_requests 500;
        send_timeout 60000s;
        client_header_buffer_size 4k;
        proxy_ignore_client_abort on;
        proxy_buffers 16 32k;
        proxy_buffer_size 64k;

        proxy_busy_buffers_size 64k;

        proxy_send_timeout 60000;
        proxy_read_timeout 60000;
        proxy_connect_timeout 60000;
        proxy_cache_valid 200 304 2h;
        proxy_cache_valid 500 404 2s;
        proxy_cache_key $host$request_uri$cookie_user;
        proxy_cache_methods GET HEAD POST;

        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Host                $http_host;
        proxy_set_header X-Real-IP           $remote_addr;
        proxy_set_header X-Forwarded-For     $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto   $scheme;
        proxy_set_header X-Frame-Options     SAMEORIGIN;

        server_tokens off;
        client_max_body_size 50G;
        add_header X-Cache $upstream_cache_status;
        autoindex off;

        resolver      127.0.0.1:53 ipv6=off;

        server {
            listen 80;

            location / {
                set $service  '';
                rewrite_by_lua '
                    local host = ngx.var.host
                    local m = ngx.re.match(host, "(.+).test.imroc.io")
                    if m then
                        ngx.var.service = "my-svc-" .. m[1]
                    end
                ';
                proxy_pass http://$service;
            }
        }
    }
```

让该代理服务暴露公网访问可以用 Service 或 Ingress

用 Service 的示例 \(`service.yaml`\):

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    component: nginx
  name: service-nginx
spec:
  type: LoadBalancer
  ports:
  - name: http
    port: 80
    targetPort: http
  selector:
    component: nginx
```

用 Ingress 的示例 \(`ingress.yaml`\):

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-nginx
spec:
  rules:
  - host: "*.test.imroc.io"
    http:
      paths:
      - backend:
          serviceName: service-nginx
          servicePort: 80
        path: /
```
