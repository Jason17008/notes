背景 ：

在进行多连接的时候vpn操作的时候 必须要断掉旧环境 然后连接新的环境

可以查看文档 这个 





[如何在 OpenVPN 添加虚拟网卡 - 公有云文档中心](https://docsv4.qingcloud.com/user_guide/network/vpc/faq/openvpn_add_virtual_network_adapter/)





添加多块网卡 多个vpn连接用 









# docker容器化 

https://github.com/wheelybird/openvpn-server-ldap-otp





```plain
docker run            
--name openvpn            
--volume /etc/openvpn:/etc/openvpn            
-v /etc/localtime:/etc/localtime:ro            
--detach=true            
--restart=always            
-p 61194:1194/tcp            
-e "OVPN_SERVER_CN=122.112.217.185"           
-e "LDAP_URI=ldap://58.33.197.42:30389"            
-e "LDAP_BASE_DN=OU=运维部,OU=研发中心,OU=总裁办,OU=上海极豆科技有限公司,DC=jidouit,DC=com"            
-e "LDAP_BIND_USER_DN=CN=Administrator,CN=Users,DC=jidouit,DC=com"   -e "LDAP_BIND_USER_PASS=Jidou@1234" 
-e "LDAP_LOGIN_ATTRIBUTE=sAMAccountName" 
-e "LDAP_FILTER=(objectClass=user)"  
-e "OVPN_NETWORK=10.218.0.0 255.255.0.0" 
-e "OVPN_ROUTES=10.32.0.0 255.255.0.0,10.33.0.0 255.255.0.0"         -e "OVPN_DNS_SERVERS=114.114.114.114" 
-e "OVPN_IDLE_TIMEOUT=36000"   
-e  "OVPN_PROTOCOL=tcp"          
-e "ENABLE_OTP=true"             
-e "FAIL2BAN_ENABLED=true"            
-e "FAIL2BAN_MAXRETRIES=20"             
--cap-add=NET_ADMIN        
wheelybird/openvpn-ldap-otp:v1.8
```





详细解读

```plain
docker run            
--name openvpn            
--volume /etc/openvpn:/etc/openvpn            
-v /etc/localtime:/etc/localtime:ro            
--detach=true            
--restart=always            
-p 61194:1194/tcp            
-e "OVPN_SERVER_CN=122.112.217.185"           #OpenVPN 服务器证书通用名（通常应为域名，此处直接使用 IP）
-e "LDAP_URI=ldap://58.33.197.42:30389"     #LDAP 服务器地址及端口（明文协议        
-e "LDAP_BASE_DN=OU=运维部,OU=研发中心,OU=总裁办,OU=上海极豆科技有限公司,DC=jidouit,DC=com" #LDAP 搜索基础路径           
-e "LDAP_BIND_USER_DN=CN=Administrator,CN=Users,DC=jidouit,DC=com"   -e "LDAP_BIND_USER_PASS=Jidou@1234" #LDAP 管理员密码（⚠️ 明文暴露，建议改用密钥文件）
-e "LDAP_LOGIN_ATTRIBUTE=sAMAccountName" #LDAP 用户登录名属性（适用于 Active Directory）
-e "LDAP_FILTER=(objectClass=user)"   #LDAP 用户筛选条件
-e "OVPN_NETWORK=10.218.0.0 255.255.0.0" #VPN 客户端分配的 IP 地址池（10.218.0.0/16）
-e "OVPN_ROUTES=10.32.0.0 255.255.0.0,10.33.0.0 255.255.0.0"   #VPN 客户端可访问的内网路由（10.32.0.0/16 和 10.33.0.0/16）      -e "OVPN_DNS_SERVERS=114.114.114.114" #指定客户端使用的 DNS 服务器
-e "OVPN_IDLE_TIMEOUT=36000"   #客户端空闲超时时间（10 小时）
-e  "OVPN_PROTOCOL=tcp"        #	OpenVPN 使用 TCP 协议   
-e "ENABLE_OTP=true"          #启用 OTP（一次性密码）双因素认证   
-e "FAIL2BAN_ENABLED=true"    #启用 Fail2Ban 防御暴力破解        
-e "FAIL2BAN_MAXRETRIES=20"   #允许的失败登录尝试次数             
--cap-add=NET_ADMIN          #授予容器网络管理权限（用于配置 VPN 路由）
wheelybird/openvpn-ldap-otp:v1.8
```





使用如下

```plain
docker exec -ti openvpn-new add-otp-user  viperliu

然后根据提示 绑定扫码
记录5次 助记词
```





脚本参考 

```plain
#!/bin/bash

#
# Generate OpenVPN users via google authenticator
#

if [ -z $1 ]; then
    echo "Usage: add_otp_user USERNAME"
    exit 1
fi


# Ensure the otp folder is present
[ -d /etc/openvpn/otp ] || mkdir -p /etc/openvpn/otp

google-authenticator \
                     --time-based \
                     --disallow-reuse \
                     --force \
                     --rate-limit=3 \
                     --rate-time=30 \
                     --window-size=3 \
                     -l "${1}@${OVPN_SERVER_CN}" \
                     -s /etc/openvpn/otp/${1}.google_authenticator




以下为 我在嘉车账号做测试 0-1尝试接入 过程 
docker pull  hub-sh.aijidou.com/mirror/wheelybird/openvpn-ldap-otp:v1.8
docker tag hub-sh.aijidou.com/mirror/wheelybird/openvpn-ldap-otp:v1.8 openvpn-new:v1.8  
下面是运行的命令 只修改了ip地址  下发的路由 下发的网段   组织架构一定要正确
```

dockerrun  \
--name openvpn  \
--volume /etc/[openvpn:/etc/openvpn](http://openvpn/etc/openvpn)  \
-v /etc/[localtime:/etc/localtime:ro](http://localtime/etc/localtime:ro)  \
--detach=true  \
--restart=always             \
-p 61194:1194/tcp             \
-e "OVPN_SERVER_CN=119.3.58.33"            \
-e "LDAP_URI=ldap://58.33.197.42:30389"             \
-e "LDAP_BASE_DN=OU=运维部,OU=总裁办,OU=上海极豆科技有限公司,DC=jidouit,DC=com"             \
-e "LDAP_BIND_USER_DN=CN=Administrator,CN=Users,DC=jidouit,DC=com"   -e"LDAP_BIND_USER_PASS=Jidou@1234"  \
-e "LDAP_LOGIN_ATTRIBUTE=sAMAccountName"  \
-e "LDAP_FILTER=(objectClass=user)"   \
-e "OVPN_NETWORK=10.250.0.0 255.255.0.0"  \
-e "OVPN_ROUTES=10.240.0.0 255.255.0.0,10.33.0.0 255.255.0.0"         -e"OVPN_DNS_SERVERS=114.114.114.114"  \
-e "OVPN_IDLE_TIMEOUT=36000"    \
-e  "OVPN_PROTOCOL=tcp"           \
-e "ENABLE_OTP=true"              \
-e "FAIL2BAN_ENABLED=true"             \
-e "FAIL2BAN_MAXRETRIES=20"              \
--cap-add=NET_ADMIN         \
openvpn-new:v1.8 











```plain
docker exec -ti openvpn show-client-config  
可以查看.ovpn 的文件
记得加上宿主机的端口 比如61194 


测试下来 发现 centos操作系统 上  无法连接  需要增加iptables规则
nsenter -n -p -t 26404 iptables -t nat -A POSTROUTING -s "10.250.0.0/16" -d "10.240.0.0/16" -o "eth0" -j MASQUERADE
解释   进入PID为26404的进程所在的网络命名空间，在该环境中执行：
向iptables的NAT表追加一条规则：所有来自10.250.0.0/16网段、发往10.240.0.0/16网段的流量，在通过eth0网卡出口时，自动进行源地址伪装。



ubuntu操作 直接运行即可
```

dockerrun  \
--name openvpn  \
--volume /etc/[openvpn:/etc/openvpn](http://openvpn/etc/openvpn)  \
-v /etc/[localtime:/etc/localtime:ro](http://localtime/etc/localtime:ro)  \
--detach=true  \
--restart=always             \
-p 61194:1194/tcp             \
-e "OVPN_SERVER_CN=122.112.253.37"            \
-e "LDAP_URI=ldap://58.33.197.42:30389"             \
-e "LDAP_BASE_DN=OU=运维部,OU=总裁办,OU=上海极豆科技有限公司,DC=jidouit,DC=com"             \
-e "LDAP_BIND_USER_DN=CN=Administrator,CN=Users,DC=jidouit,DC=com"   -e"LDAP_BIND_USER_PASS=Jidou@1234"  \
-e "LDAP_LOGIN_ATTRIBUTE=sAMAccountName"  \
-e "LDAP_FILTER=(objectClass=user)"   \
-e "OVPN_NETWORK=10.250.0.0 255.255.0.0"  \
-e "OVPN_ROUTES=10.240.0.0 255.255.0.0,10.32.0.0 255.255.0.0"         -e"OVPN_DNS_SERVERS=114.114.114.114"  \
-e "OVPN_IDLE_TIMEOUT=36000"    \
-e  "OVPN_PROTOCOL=tcp"           \
-e "ENABLE_OTP=true"              \
-e "FAIL2BAN_ENABLED=true"             \
-e "FAIL2BAN_MAXRETRIES=20"              \
--cap-add=NET_ADMIN         \
openvpn-new:v1.8









如果不想要otp的密码的话注释下面的三行 直接运行

dockerrun  \
--name openvpn  \
--volume /etc/[openvpn:/etc/openvpn](http://openvpn/etc/openvpn)  \
-v /etc/[localtime:/etc/localtime:ro](http://localtime/etc/localtime:ro)  \
--detach=true  \
--restart=always             \
-p 61194:1194/tcp             \
-e "OVPN_SERVER_CN=122.112.253.37"            \
-e "LDAP_URI=ldap://58.33.197.42:30389"             \
-e "LDAP_BASE_DN=OU=运维部,OU=总裁办,OU=上海极豆科技有限公司,DC=jidouit,DC=com"             \
-e "LDAP_BIND_USER_DN=CN=Administrator,CN=Users,DC=jidouit,DC=com"   -e"LDAP_BIND_USER_PASS=Jidou@1234"  \
-e "LDAP_LOGIN_ATTRIBUTE=sAMAccountName"  \
-e "LDAP_FILTER=(objectClass=user)"   \
-e "OVPN_NETWORK=10.250.0.0 255.255.0.0"  \
-e "OVPN_ROUTES=10.240.0.0 255.255.0.0,10.32.0.0 255.255.0.0"         -e"OVPN_DNS_SERVERS=114.114.114.114"  \
-e "OVPN_IDLE_TIMEOUT=36000"    \
-e  "OVPN_PROTOCOL=tcp"