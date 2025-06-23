先创建目录 

```plain
mkdir -p /etc/openvpn
```

然后运行openvpn

```plain
docker run --rm -v /etc/openvpn:/etc/openvpn kylemanna/openvpn ovpn_genconfig -v /etc/localtime:/etc/localtime:ro  -v /etc/timezone:/etc/timezone:ro   -u tcp://39.105.128.155:1194 -s 10.218.0.0/16 -p "route 172.30.0.0 255.255.0.0"                   
```

命令翻译

```plain
docker run --rm \
  -v /etc/openvpn:/etc/openvpn \
  kylemanna/openvpn ovpn_genconfig \
  -u tcp://39.105.128.155:1194 \     # 你的公网IP和端口
  -s 10.218.0.0/16 \                   # VPN地址池
  -p "route 172.30.0.0 255.255.0.0" \   # 推送内网路由


  -v /etc/localtime:/etc/localtime:ro  -v /etc/timezone:/etc/timezone:ro
 指定时区  
```

容器启动不起来  这个时候需要创建文件 

```plain
docker run --rm -v /etc/openvpn:/etc/openvpn -it kylemanna/openvpn ovpn_initpki
```



输入yes

zed45231.

zed45231.

viperliu

zed45231.

zed45231.

**生成客户端证书**：

```plain
docker run --rm \
  -v /etc/openvpn:/etc/openvpn \
  -it kylemanna/openvpn easyrsa build-client-full client1 nopass
```

**私钥密码 zed452531.**

**导出客户端配置**：

```plain
docker run --rm \
  -v /etc/openvpn:/etc/openvpn \
  kylemanna/openvpn ovpn_getclient client1 > client1.ovpn
```