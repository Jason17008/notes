https://blog.csdn.net/weixin_46887489/article/details/134493855?spm=1001.2014.3001.5502





netshoot镜像`docker.io/nicolaka/netshoot`里面包括以下这些网络工具包:

```
apache2-utils \
bash \
bind-tools \
bird \
bridge-utils \
busybox-extras \
conntrack-tools \
curl \
dhcping \
drill \
ethtool \
file\
fping \
grpcurl \
iftop \
iperf \
iperf3 \
iproute2 \
ipset \
iptables \
iptraf-ng \
iputils \
ipvsadm \
jq \
libc6-compat \
liboping \
ltrace \
mtr \
net-snmp-tools \
netcat-openbsd \
nftables \
ngrep \
nmap \
nmap-nping \
nmap-scripts \
openssl \
py3-pip \
py3-setuptools \
scapy \
socat \
speedtest-cli \
openssh \
strace \
tcpdump \
tcptraceroute \
tshark \
util-linux \
vim \
git \
zsh \
websocat \
swaks \
perl-crypt-ssleay \
perl-net-ssleay

```

Netshoot with Docker Compose

```
version: "3.6"
services:
  tcpdump:
    image: docker.io/nicolaka/netshoot
    depends_on:
      - nginx
    command: tcpdump -i eth0 -w /data/nginx.pcap
    network_mode: service:nginx
    volumes:
      - $PWD/data:/data

  nginx:
    image: nginx:alpine
    ports:
      - 80:80

```

我这里给大家准备好了在k8s上以deployment形式运行的yaml配置

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: netshoot
  name: netshoot
spec:
  replicas: 1
  selector:
    matchLabels:
      app: netshoot
  template:
    metadata:
      labels:
        app: netshoot
    spec:
      containers:
      - image: docker.io/nicolaka/netshoot
        name: netshoot
        args:
        - /bin/bash
        - -c
        - >
           while :; do
             echo "[$(date +%F\ %T)] hello"
             sleep 1
           done


```





使用k8s自带debug功能来分析pod的网络流量 注： 这里使用的k8s版本是 v1.27.5 ， v1.20.4 以上版本应该都是可以支持的

https://blog.csdn.net/weixin_46887489/article/details/134519014?spm=1001.2014.3001.5502

```
0. 创建测试用的nginx服务
kubectl create deployment nginx --image=nginx:1.21.6
kubectl expose deployment nginx --port=80 --target-port=80

1. 创建一个 nginx 的副本，生成一个新的pod(boge-debugger)，并添加一个调试容器(nicolaka/netshoot)并附加到它
# kubectl -n default debug nginx-6f648b8457-dglgp -it --image=docker.io/nicolaka/netshoot --copy-to=boge-debugger

2. 新的debug用pod是没有任何label的
# kubectl -n default get pod boge-debugger --show-labels

3. 如果要引入流量，可以把生产的label加到这个debug的pod上面
# kubectl -n default label pods boge-debugger app=nginx  # 添加label

4. 这时可以看到endpoints已经把这个debug的pod地址更新进来了
# kubectl describe endpoints nginx

5. 在debug的pod内使用tcpdump抓包
# tcpdump -nv -i eth0 port 80

6. 去掉label并删除debug的pod(注意查看下endpoints是否已经去掉了debug的pod，并观察业务日志，确认没问题再删除)
# kubectl -n default label pods boge-debugger app-  # 去掉label
# kubectl describe endpoints nginx
# kubectl -n default delete pods boge-debugger
————————————————

```

