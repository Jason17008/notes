脚本快捷部署



```
#!/bin/bash

IP=39.105.128.155
PORT=1194
prvite_ip=172.30.0.0

# 配置阿里云 epel 源
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

# 安装 openvpn easy-rsa httpd lrzsz 软件
yum install -y openvpn easy-rsa lrzsz httpd

# 拷贝 easy-rsa 软件到 openvpn 目录
cp -a /usr/share/easy-rsa/[[:digit:]]*.[[:digit:]]*.[[:digit:]]* /etc/openvpn/easy-rsa

# 切换到 easy-rsa 目录，方便执行easyrsa命令
cd /etc/openvpn/easy-rsa

# 初始化 pki 目录
./easyrsa init-pki

# 创建 ca 证书
./easyrsa build-ca nopass

# 创建 server 密钥和证书
./easyrsa build-server-full server nopass

# 创建dn
./easyrsa gen-dh

# 准备证书吊销列表文件
./easyrsa gen-crl

# 准备 server 用的证书和秘密等文件，统一放到 /etc/openvpn/server/
cp pki/ca.crt /etc/openvpn/server/
cp pki/dh.pem /etc/openvpn/server/
cp pki/issued/server.crt /etc/openvpn/server/
cp pki/private/server.key /etc/openvpn/server/

# 准备 server 配置文件，绝对路径必须 /etc/openvpn/service.conf ，下面是配置文件模板
# cp /usr/share/doc/openvpn-[[:digit:]]*.[[:digit:]]*.[[:digit:]]*/sample/sample-config-files/server.conf /etc/openvpn/service.conf

echo 'local 0.0.0.0
port '$PORT'
proto udp
dev tun
ca /etc/openvpn/server/ca.crt
cert /etc/openvpn/server/server.crt
key /etc/openvpn/server/server.key
dh /etc/openvpn/server/dh.pem
server 10.10.10.0 255.255.255.0
rotue $prvite_ip 255.255.0.0
client-to-client
duplicate-cn
keepalive 10 120
cipher AES-256-CBC
max-clients 100
persist-key
persist-tun
status /var/www/html/index.txt
log-append /var/log/openvpn.log
verb 3
mute 20
explicit-exit-notify 1
crl-verify /etc/openvpn/easy-rsa/pki/crl.pem ' > /etc/openvpn/service.conf

# 启动服务，并设置开机自动运行
systemctl enable openvpn@service && systemctl start openvpn@service

# 创建 client 证书和密钥
./easyrsa build-client-full demo nopass

# 准备 client 配置文件，下面是配置文件模板
# cp /usr/share/doc/openvpn-[[:digit:]]*.[[:digit:]]*.[[:digit:]]*/sample/sample-config-files/client.conf /etc/openvpn/client/

echo 'client
dev tun
proto udp
remote '$IP' '$PORT'
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3' > /etc/openvpn/client/demo.ovpn

# 为 client 配置ca证书
echo '<ca>' >> /etc/openvpn/client/demo.ovpn
cat /etc/openvpn/easy-rsa/pki/ca.crt >> /etc/openvpn/client/demo.ovpn
echo '</ca>' >> /etc/openvpn/client/demo.ovpn

# 为 client 配置证书
echo '<cert>' >> /etc/openvpn/client/demo.ovpn
cat /etc/openvpn/easy-rsa/pki/issued/demo.crt >> /etc/openvpn/client/demo.ovpn
echo '</cert>' >> /etc/openvpn/client/demo.ovpn

# 为 client 配置密钥
echo '<key>' >> /etc/openvpn/client/demo.ovpn
cat /etc/openvpn/easy-rsa/pki/private/demo.key >> /etc/openvpn/client/demo.ovpn
echo '</key>' >> /etc/openvpn/client/demo.ovpn
```



记得改外网ip 和内网ip  然后导出demo.ovpn 这个文件 进行测试



```
#!/bin/bash

IP=39.105.128.155
PORT=1194
USER=$1

# 切换到 easy-rsa 目录，方便执行easyrsa命令
cd /etc/openvpn/easy-rsa

# 创建 client 证书和密钥
./easyrsa build-client-full $USER nopass

# 准备 client 配置文件，下面是配置文件模板

echo 'client
dev tun
proto udp
remote '$IP' '$PORT'
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3' > /etc/openvpn/client/$USER.ovpn

# 为 client 配置ca证书
echo '<ca>' >> /etc/openvpn/client/$USER.ovpn
cat /etc/openvpn/easy-rsa/pki/ca.crt >> /etc/openvpn/client/$USER.ovpn
echo '</ca>' >> /etc/openvpn/client/$USER.ovpn

# 为 client 配置证书
echo '<cert>' >> /etc/openvpn/client/$USER.ovpn
cat /etc/openvpn/easy-rsa/pki/issued/$USER.crt >> /etc/openvpn/client/$USER.ovpn
echo '</cert>' >> /etc/openvpn/client/$USER.ovpn

# 为 client 配置密钥
echo '<key>' >> /etc/openvpn/client/$USER.ovpn
cat /etc/openvpn/easy-rsa/pki/private/$USER.key >> /etc/openvpn/client/$USER.ovpn
echo '</key>' >> /etc/openvpn/client/$USER.ovpn

```



快捷下发用户  无密码版本 





脚本删除用户

```
#!/bin/bash

USER=$1

# 切换到 easy-rsa 目录，方便执行easyrsa命令
cd /etc/openvpn/easy-rsa

# 注销用户，即吊销证书
./easyrsa revoke $USER
./easyrsa gen-crl
```

