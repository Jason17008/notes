openvpn 



ca负责颁发证书



nit  初始化

build -ca  是需要给自己的这个ca颁发证书 



gen-req  server nopass    gen-req 证书申请  server 前缀 nopass 不要密码 



./easyrsa  sign server server    第一个sever 类型   第二个server  是前缀  sign 颁发的 





然后就是密钥交换生成

./easyrsa gen-dh   

```plain
Diffie-Hellman 密钥交换方法是迪菲（Whitefield Diffie）和赫尔曼（Martin Hellman）在1976年公布
的一种秘钥交换算法，它是一种建立秘钥的方法，而不是加密方法，所以秘钥必须和其他一种加密算法
结合使用。这种密钥交换技术的目的在于使两个用户安全地交换一个密钥，用此密钥做为对称密钥来加
密后续的报文传输。
参考链接
用 openssl 命令也可以创建
https://en.wikipedia.org/wiki/Di
```



然后给客户端颁发证书 （这个时候可以该配置文件 可以给用户发证书  有效期设置一个时间  ）



./easyrsa gen-req  viperliu nopass   先申请

./easyrsa sign  client  viperliu  在颁发  

然后就是打包了



./easyrsa  remove  viperliu  吊销证书 









正式的搭建流程 

```plain
yum install -y  easy-rsa 

mkdir /etc/openvpn

cp -r /usr/share/easy-rsa/3/ /etc/openvpn/easy-rsa

cp /usr/share/doc/easy-rsa-3.0.8/vars.example /etc/openvpn/easy-rsa/vars

vim /vars

#CA机构证书有效期
set_var EASYRSA_CA_EXPIRE 36500
#openvpn 服务器证书有效期
#set_var EASYRSA_CERT_EXPIRE 3650
```





```plain
初始化pki
给ca机构颁发证书
#cd /etc/openvpn/easy-rsa/


./easyrsa init-pki

./easyrsa build-ca nopass    

##回车接受默认值 


申请服务端证书

./easyrsa gen-req server nopass

##回车接受默认值 

开始给服务端颁发证书
./easyrsa sign server server

输入yes回车


创建 Diffie-Hellman 密钥
./easyrsa gen-dh
```



/

```plain
下面是给服务端颁发证书

#建议修改给客户端颁发证书的有效期,可适当减少,比如:90天
[root@centos8 ~]#vim /etc/openvpn/easy-rsa/vars
#set_var EASYRSA_CERT_EXPIRE   825 
#将上面行修改为下面
set_var EASYRSA_CERT_EXPIRE 90


申请服务端证书
./easyrsa gen-req wangxiaochun nopass
回车一次 

给服务端颁发证书
./easyrsa sign client wangxiaochun
输入yes回车
```



自动化颁发证书脚本

```plain
#!/bin/bash
read -p "请输入用户的姓名拼音(如:${NAME}): " NAME
cd /etc/openvpn/easy-rsa/
./easyrsa gen-req ${NAME} nopass <<EOF
EOF
./easyrsa sign client ${NAME} <<EOF
yes
EOF
```



yum -y install openvpn

**将CA和服务器证书相关文件复制到服务器相应的目录**

```plain
cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/server/
cp /etc/openvpn/easy-rsa/pki/issued/server.crt /etc/openvpn/server/
cp /etc/openvpn/easy-rsa/pki/private/server.key /etc/openvpn/server/
cp /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn/server/
```



**将客户端私钥与证书相关文件复制到服务器相关的目录**

```plain
mkdir /etc/openvpn/client/wangxiaochun/

find /etc/openvpn/easy-rsa/ \( -name "wangxiaochun.key" -o -name "wangxiaochun.crt" -o -name ca.crt \) -exec cp {} /etc/openvpn/client/wangxiaochun/ \;

复制过去文件
```



**配置 OpenVPN 服务器并启动服务**



```plain
cp /usr/share/doc/openvpn-2.4.12/sample/sample-config-files/server.conf  /etc/openvpn/server/

vim server.conf 

port 1194
proto tcp
dev tun
ca /etc/openvpn/server/ca.crt
cert /etc/openvpn/server/server.crt
key /etc/openvpn/server/server.key  # This file should be kept secret
dh /etc/openvpn/server/dh.pem
server 10.8.0.0 255.255.255.0
push "route 172.30.0.0 255.255.255.0"
keepalive 10 120
cipher AES-256-CBC
compress lz4-v2
push "compress lz4-v2"
max-clients 2048
user openvpn
group openvpn
status /var/log/openvpn/openvpn-status.log
log-append /var/log/openvpn/openvpn.log
verb 3
mute 20
```

**准备服务器日志相关目录与文件**



```plain
getent passwd openvpn
mkdir /var/log/openvpn
chown openvpn.openvpn /var/log/openvpn


openvpn --config /etc/openvpn/server/server.conf --test
cat /usr/lib/systemd/system/openvpn@.service

[Unit]
Description=OpenVPN Robust And Highly Flexible Tunneling Application On %I
After=network.target
[Service]
Type=notify
PrivateTmp=true
ExecStart=/usr/sbin/openvpn --cd /etc/openvpn/server/ --config %i.conf
[Install]
WantedBy=multi-user.target



systemctl daemon-reload
systemctl enable --now openvpn@server

查看状态 

systemctl status   openvpn@server


可以先测试
openvpn --config /etc/openvpn/server.conf --test

手动启动的话 这样启动  


openvpn --config /etc/openvpn/server/server.conf --daemon --log-append /var/log/openvpn-server.log
```



启动完成之后

```plain
grep '^[[:alpha:]].*' /usr/share/doc/openvpn-2.4.12/sample/sample-config-files/client.conf > /etc/openvpn/client/wangxiaochun/client.ovpn

这样生成一个示例的client的配置文件

打包 文件 下载到windows客户端 

要修改  clinet.ovpn 
```





# windows作为客户端

https://openvpn.net/community-downloads/ 



```plain
这块后面就很乱了。
注意下 tcp  udp 
证书跟名字对应
tls 那个注释一下 

client
dev tun
proto tcp
remote 122.112.253.37  1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert wangxiaochun.crt
key wangxiaochun.key
remote-cert-tls server
#tls-auth ta.key 1
cipher AES-256-CBC
verb 3
```

进行连接  





这个时候 可以访问openvpn的机器 但是访问不了同网段的设备 

echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf

sysctl -p



在OpenVPN server 主机上设置 SNAT 转发，将从 10.8.0.0/24 网段主机请求的源IP转换成本机 

IP(172.30.0.66)

iptables -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 

10.8.0.0/24 -j MASQUERADE



将 OpenVPN server 主机的 iptables 规则设置为开机加载，保证重启后有效

echo 'iptables -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 

10.8.0.0/24 -j MASQUERADE' >> /etc/rc.d/rc.local





后面的操作主要是都是设置用户名密码  以及 账户的注销  常用的如下 

```plain
vim /etc/openvpn/server.conf


script-security 3 #允许使用自定义脚本
auth-user-pass-verify /etc/openvpn/checkpsw.sh via-env #指定自定义脚本路径
username-as-common-name #开启用户密码验证
[root@openvpn-server openvpn]# vim checkpsw.sh
#!/bin/sh
###########################################################
# checkpsw.sh (C) 2004 Mathias Sundman <mathias@openvpn.se>
#
# This script will authenticate OpenVPN users against
# a plain text file. The passfile should simply contain
# one row per user with the username first followed by
# one or more space(s) or tab(s) and then the password.
PASSFILE="/etc/openvpn/psw-file"
#LOG_FILE="/var/log/openvpn-password.log" #修改此处
LOG_FILE="/var/log/openvpn/openvpn-password.log"
TIME_STAMP=`date "+%Y-%m-%d %T"`
###########################################################
if [ ! -r "${PASSFILE}" ]; then
  echo "${TIME_STAMP}: Could not open password file \"${PASSFILE}\" for 
reading." >> ${LOG_FILE}
  exit 1
fi
CORRECT_PASSWORD=`awk '!/^;/&&!/^#/&&$1=="'${username}'"{print $2;exit}' 
${PASSFILE}`
if [ "${CORRECT_PASSWORD}" = "" ]; then
  echo "${TIME_STAMP}: User does not exist: username=\"${username}\", 
password=\"${password}\"." >> ${LOG_FILE}
  exit 1
fi
if [ "${password}" = "${CORRECT_PASSWORD}" ]; then
  echo "${TIME_STAMP}: Successful authentication: username=\"${username}\"." >> 
${LOG_FILE}
  exit 0
fi
echo "${TIME_STAMP}: Incorrect password: username=\"${username}\", 
password=\"${password}\"." >> ${LOG_FILE}
exit 1
```

chmod a+x checkpsw.sh

cat /etc/openvpn/psw-file

user1 123456 

user2 654321





systemctl restart openvpn.service





客户端增加如下

```plain
auth-user-pass
```



# linux 作为客户端

```plain
openvpn --daemon --cd /etc/openvpn/client --config client.ovpn 
--log-append /var/log/openvpn.log
```





# 如果想支持账号密码





checkpsw.sh

```plain
#!/bin/sh
###########################################################
# checkpsw.sh (C) 2004 Mathias Sundman <mathias@openvpn.se>
#
# This script will authenticate OpenVPN users against
# a plain text file. The passfile should simply contain
# one row per user with the username first followed by
# one or more space(s) or tab(s) and then the password.

PASSFILE="/etc/openvpn/psw-file"
LOG_FILE="/var/log/openvpn-password.log"
TIME_STAMP=`date "+%Y-%m-%d %T"`

###########################################################

if [ ! -r "${PASSFILE}" ]; then
  echo "${TIME_STAMP}: Could not open password file \"${PASSFILE}\" for reading." >> ${LOG_FILE}
  exit 1
fi

CORRECT_PASSWORD=`awk '!/^;/&&!/^#/&&$1=="'${username}'"{print $2;exit}' ${PASSFILE}`

if [ "${CORRECT_PASSWORD}" = "" ]; then 
  echo "${TIME_STAMP}: User does not exist: username=\"${username}\", password=\"${password}\"." >> ${LOG_FILE}
  exit 1
fi

if [ "${password}" = "${CORRECT_PASSWORD}" ]; then 
  echo "${TIME_STAMP}: Successful authentication: username=\"${username}\"." >> ${LOG_FILE}
  exit 0
fi

echo "${TIME_STAMP}: Incorrect password: username=\"${username}\", password=\"${password}\"." >> ${LOG_FILE}
exit 1
```

chmod +x /etc/openvpn/checkpsw.sh



vim /etc/openvpn/psw-file 

```plain
wang 123456
test 654321
```



server.conf 增加最后三行

```plain
port 1194
proto tcp
dev tun
ca /etc/openvpn/server/ca.crt
cert /etc/openvpn/server/server.crt
key /etc/openvpn/server/server.key  # This file should be kept secret
dh /etc/openvpn/server/dh.pem
server 10.8.0.0 255.255.255.0
push "route 172.30.0.0 255.255.0.0"
keepalive 10 120
cipher AES-256-CBC
compress lz4-v2
push "compress lz4-v2"
max-clients 2048
user openvpn
group openvpn
status /var/log/openvpn/openvpn-status.log
log-append /var/log/openvpn/openvpn.log
verb 3
mute 20

script-security 3      
auth-user-pass-verify /etc/openvpn/checkpsw.sh via-env 
username-as-common-name  
```



客户端增加1行

```plain
auth-user-pass
```