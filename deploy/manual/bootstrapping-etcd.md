# 部署 ETCD

## 签发证书

``` bash
cat > etcd-csr.json <<EOF
{
    "CN": "etcd",
    "hosts": [
      "127.0.0.1",
      "10.200.16.79",
      "10.200.17.6",
      "10.200.16.70"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "SiChuan",
            "L": "Chengdu",
            "O": "etcd",
            "OU": "etcd"
        }
    ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  etcd-csr.json | cfssljson -bare etcd
```

> hosts 需要包含 etcd 每个实例所在节点的内网 IP

会生成下面两个重要的文件:

* `etcd-key.pem`: kube-apiserver 证书密钥
* `etcd.pem`: kube-apiserver 证书

> 这里证书可以只创建一次，所有 etcd 实例都公用这里创建的证书

## 下载安装

下载 release 包:

``` bash
wget -q --show-progress --https-only --timestamping \
  "https://github.com/etcd-io/etcd/releases/download/v3.4.1/etcd-v3.4.1-linux-amd64.tar.gz"
```

解压安装 `etcd` 和 `etcdctl`  到 PATH:

``` bash
tar -xvf etcd-v3.4.1-linux-amd64.tar.gz
sudo mv etcd-v3.4.1-linux-amd64/etcd* /usr/local/bin/
```

## 配置

创建配置相关目录，放入证书文件:

``` bash
sudo mkdir -p /etc/etcd /var/lib/etcd
sudo cp ca.pem etcd-key.pem etcd.pem /etc/etcd/
```

etcd 集群每个成员都需要一个名字，这里第一个成员名字用 infra0，第二个可以用 infra1，以此类推，你也可以直接用节点的 hostname:

``` bash
NAME=infra0
```

记当前部署 ETCD 的节点的内网 IP 为 INTERNAL_IP:

``` bash
INTERNAL_IP=10.200.16.79
```

创建 systemd 配置:

``` bash
cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${NAME} \\
  --cert-file=/etc/etcd/etcd.pem \\
  --key-file=/etc/etcd/etcd-key.pem \\
  --peer-cert-file=/etc/etcd/etcd.pem \\
  --peer-key-file=/etc/etcd/etcd-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster infra0=https://10.200.16.79:2380,infra1=https://10.200.17.6:2380,infra2=https://10.200.16.70:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

* `initial-cluster` 包含所有 etcd 的成员的名称和成员间通信的 https 监听地址，逗号隔开。

## 启动

``` bash
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
```

## 验证

等所有 etcd 成员安装启动成功后，来验证下是否可用:

``` bash
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/etcd.pem \
  --key=/etc/etcd/etcd-key.pem
```

输出:

``` txt
a7f995caeeaf7a59, started, infra1, https://10.200.17.6:2380, https://10.200.17.6:2379, false
b90901a06e9aec53, started, infra2, https://10.200.16.70:2380, https://10.200.16.70:2379, false
ba126eb695f5ba71, started, infra0, https://10.200.16.79:2380, https://10.200.16.79:2379, false
```
