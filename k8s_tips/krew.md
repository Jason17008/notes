inux-x86_64 手动安装

```bash
wget https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz
tar zxvf krew.tar.gz ./krew-linux_amd64
./krew-linux_amd64 install krew

# 配置环境变量
echo 'export PATH=$PATH:$HOME/.krew/bin' >> ~/.bashrc
```



kubctl krew  查看命令



# Kubectl 插件之 dumpy

```shell
kubectl krew install dumpy
```



二进制安装

### 2. Manual installation:

```
curl -L -O https://github.com/larryTheSlap/dumpy/releases/download/v0.1.0/dumpy_Linux_x86_64.tar.gz
tar xf dumpy_Linux_x86_64.tar.gz 
chmod +x kubectl-dumpy && sudo mv kubectl-dumpy /usr/bin/kubectl-dumpy
```

### 创建一个捕获器

```
# 在 default 名称空间创建一个名为 capture-ingress-nginx 捕获器, 用于捕获 default 名称空间的 deployment nginx
(⎈|mykind) ➜ ~ k dumpy capture deployment nginx -n default -t default --name capture-nginx -f '-i any' --image registry.cn-hangzhou.aliyuncs.com/soulchild/dumpy:0.2.0
```

###  查看捕获器

```
k dumpy get capture-nginx
Getting capture details..

name: capture-nginx
namespace: default
tcpdumpfilters: -i any
image: registry.cn-hangzhou.aliyuncs.com/soulchild/dumpy:0.2.0
targetSpec:
    name: nginx
    namespace: default
    type: deployment
    container: nginx
    items:
        nginx-7dbbdcd99d-dz9r5  <-----  sniffer-capture-nginx-1761 [Running]
        nginx-7dbbdcd99d-g82gc  <-----  sniffer-capture-nginx-9964 [Running]
pvc:
pullsecret:
```

### 导出 pcap

```
导出之前可以看看 pod 日志有没有捕获到流量
(⎈|mykind) ➜ ~ k logs sniffer-capture-nginx-1761

# 导出 capture-nginx 捕获器的 pcap 到当前目录 -n 指定捕获器所在的名称空间
(⎈|mykind) ➜ ~ k dumpy export capture-nginx ./ -n default
```

重启捕获器
重启会重新创建 pod 并删除老 pod, 所以可以指定新的 filter, 可以理解为重新捕获

```
(⎈|mykind) ➜ ~ k dumpy restart capture-nginx

# or

(⎈|mykind) ➜ ~ k dumpy restart capture-nginx -f '-i eth0'
```

###  停止捕获

```
k dumpy stop capture-nginx -n default
```

### 删除捕获器

```
k dumpy delete capture-nginx -n default
```

