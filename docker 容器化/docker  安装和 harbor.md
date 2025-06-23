# 安装docker

- **harbor仓库是由docker-compose部署的，所以部署harbor仓库之前，需要先将docker环境和docker-compose环境安装好**
- **安装docker+docker-compose环境**

## 注意 下载 docekr这边要换源  然后然后加速器 也要更换  

```
#卸载当前docker环境
yum -y remove docker \
docker-client \
docker-client-latest \
docker-common \
docker-latest \
docker-latest-logrotate \
docker-logrotate \
docker-selinux \
docker-engine-selinux \
docker-engine

yum -y remove docker-ce docker-ce-cli containerd.io
rm -rf var/lib/docker

#安装docker
# step 1: 安装必要的一些系统工具
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
# Step 2: 添加软件源信息
sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# Step 3
sudo sed -i 's+download.docker.com+mirrors.aliyun.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
# Step 4: 更新并安装Docker-CE
sudo yum makecache fast

    
yum install docker-ce docker-ce-cli containerd.io -y

systemctl start docker  &&  systemctl enable docker

#配置doker镜像加速器
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://hub.uuuadc.top",
    "https://docker.anyhub.us.kg",
    "https://dockerhub.jobcher.com",
    "https://dockerhub.icu",
    "https://docker.ckyl.me",
    "https://docker.awsl9527.cn",
    "https://055621bd456149969d0f0a95af1aa3d1.mirror.swr.myhuaweicloud.com"
    ]
}
EOF

###华为云
"registry-mirrors": [ "https://055621bd456149969d0f0a95af1aa3d1.mirror.swr.myhuaweicloud.com"

systemctl daemon-reload

systemctl restart docker  && systemctl status docker

#安装docker-compose
wget  https://github.com/docker/compose/releases/download/v2.22.0/docker-compose-linux-x86_64

mv docker-compose-linux-x86_64  /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

docker-compose --version



```

### 1.1.2、安装harbor仓库

- **github官网harbor下载地址：**[**https://github.com/goharbor/harbor/**](https://github.com/goharbor/harbor/)
- **harbor仓库可以在线安装和离线安装，离线安装就是将所有的镜像都打成了一个tar包，在线安装则是执行install.sh安装脚本，执行后会在线下载harbor所需要的镜像**


- - 在线安装：<https://github.com/goharbor/harbor/releases/download/v2.9.1/harbor-online-installer-v2.9.1.tgz>
  - 离线安装：<https://github.com/goharbor/harbor/releases/download/v2.9.1/harbor-offline-installer-v2.9.1.tgz>


- **本文档用的是在线安装的方式**

```
wget https://github.com/goharbor/harbor/releases/download/v2.9.1/harbor-online-installer-v2.9.1.tgz




tar -xzvf  harbor-online-installer-v2.9.1.tgz 

cd harbor/

ls

## 备份下harbor.yml.tmpl 为harbor.yml 改下hostname  然后注释掉 hhtps

./install.sh
```

到此差不多安装完成  

# 管理harbor仓库的命令

```
docker-compose up -d          # 后台启动，如果容器不存在根据镜像自动创建
docker-compose down -v        # 停止容器并删除容器
docker-compose start          # 启动容器，容器不存在就无法启动，不会自动创建镜像
docker-compose stop           # 停止容器
docker-compose restart 		  # 重启容器
```

## 1.2、配置harbor仓库使用私有证书

- **使用cfssl工具创建证书**

```
#下载
#cfssl是使用go编写，由CloudFlare开源的一款PKI/TLS工具。主要程序有：
- cfssl，是CFSSL的命令行工具。
- cfssljson用来从cfssl程序获取JSON输出，并将证书，密钥，CSR和bundle写入文件中。


#下载cfssl证书生成工具
wget "https://github.com/cloudflare/cfssl/releases/download/v1.6.3/cfssl_1.6.3_linux_amd64" -O /usr/local/bin/cfssl

wget "https://github.com/cloudflare/cfssl/releases/download/v1.6.3/cfssljson_1.6.3_linux_amd64" -O /usr/local/bin/cfssljson

chmod +x /usr/local/bin/cfssl*

[root@harbor-registry ~]# cfssl version
Version: 1.6.3
Runtime: go1.18

#或者上传二进制文件
mv  cfssl_linux_amd64 /usr/local/bin/cfssl
mv  cfssljson_linux_amd64  /usr/local/bin/cfssljson
chmod +x /usr/local/bin/cfssl*


root in 🌐 harbor-server in ~ 
❯ cfssl version
Version: 1.6.3
Runtime: go1.18

#生成CA证书
mkdir -p /data/ssl/  &&  cd /data/ssl

cat > ca-csr.json <<EOF
{
"CN": "harbor",
"key": {
"algo": "rsa",
"size": 2048
},
"names": [
{
"C": "CN",
"ST": "Beijing",
"L": "Beijing"
}
]
}
EOF

#生成证书
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

#配置ca策略证书
cat > ca-config.json <<EOF
{
"signing": {
"default": {
"expiry": "87600h"
},
"profiles": {
"harbor": {
"expiry": "87600h",
"usages": [
"signing",
"key encipherment",
"server auth",
"client auth"
]
}
}
}
}
EOF

#配置harbor请求csr文件，hosts为请求的主机IP或域名名称
cat > harbor-csr.json <<EOF
{
"CN": "harbor",
"hosts": [
"192.168.17.112",
"harbor.myharbor.com"
],
"key": {
"algo": "rsa",
"size": 2048
},
"names": [
{
"C": "CN",
"ST": "Beijing",
"L": "Beijing"
}
]
}
EOF


#生成harbor证书
cfssl gencert \
-ca=ca.pem \
-ca-key=ca-key.pem \
-config=ca-config.json \
-profile=harbor \
harbor-csr.json | cfssljson -bare harbor


#配置habor启用证书
mkdir -p /data/harbor/ssl/
cp /data/ssl/harbor*pem    /data/harbor/ssl/

vim /data/harbor/harbor.yml
hostname: 192.168.17.112

# http related config
http:
  # port for http, default is 80. If https enabled, this port will redirect to https port
  port: 80

# https related config
https:
  # https port for harbor, default is 443
#  port: 443
  # The path of cert and key files for nginx
  ##证书
  certificate: /data/harbor/ssl/harbor.pem
  ##私钥
  private_key: /data/harbor/ssl/harbor-key.pem

#配置docker登录harbor，创建harbor证书目录，其中为证书的hosts名称
mkdir -p /etc/docker/certs.d/{192.168.17.112,harbor.myharbor.com}/

#使用域名访问先建本立本地host解析
echo '192.168.17.112  harbor.myharbor.com' >>/etc/hosts

#复制ca根证书与harbor服务证书
cp /data/ssl/ca.pem  /etc/docker/certs.d/192.168.17.112/
cp /data/ssl/ca.pem  /etc/docker/certs.d/harbor.myharbor.com/
cp /data/ssl/harbor*pem  /etc/docker/certs.d/192.168.17.112/
cp /data/ssl/harbor*pem  /etc/docker/certs.d/harbor.myharbor.com/

#Harbor docker login x509 certificate signed by unknown authority(说明自签名证书不信任)

#系统导入并信任我们生成的CA证书
cp /data/ssl/ca.pem  /etc/pki/ca-trust/source/anchors
update-ca-trust extract
systemctl restart docker

#修改harbor参数以后重启harbor
cd /root/harbor/
./prepare
docker-compose down
docker-compose up -d

#本机登录harbor仓库
root in 🌐 harbor-server in ~/harbor 
❯ docker login -u admin -p Harbor12345  192.168.17.112
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded

#其他docker登录harbor；先导入并信任自签名生成的CA证书，再执行docker login
cp /data/ssl/ca.pem  /etc/pki/ca-trust/source/anchors
update-ca-trust extract
systemctl restart docker	
```

### 1.2.1、重启harbor服务器后，登录harbor失败

**现象：由于突然断电的情况，导致harbor服务器被迫中断，重启服务器重启harbor服务后（docker-compose retart），登录harbor仓库发现无法登录，明明账号密码都对**

****

**解决方法**

```
root in 🌐 harbor-server in ~/harbor 
❯ pwd
/root/harbor

root in 🌐 harbor-server in ~/harbor 
❯ ./prepare 
prepare base dir is set to /root/harbor
Clearing the configuration file: /config/portal/nginx.conf
Clearing the configuration file: /config/log/logrotate.conf
Clearing the configuration file: /config/log/rsyslog_docker.conf
Clearing the configuration file: /config/nginx/nginx.conf
Clearing the configuration file: /config/core/env
Clearing the configuration file: /config/core/app.conf
Clearing the configuration file: /config/registry/passwd
Clearing the configuration file: /config/registry/config.yml
Clearing the configuration file: /config/registry/root.crt
Clearing the configuration file: /config/registryctl/env
Clearing the configuration file: /config/registryctl/config.yml
Clearing the configuration file: /config/db/env
Clearing the configuration file: /config/jobservice/env
Clearing the configuration file: /config/jobservice/config.yml
Generated configuration file: /config/portal/nginx.conf
Generated configuration file: /config/log/logrotate.conf
Generated configuration file: /config/log/rsyslog_docker.conf
Generated configuration file: /config/nginx/nginx.conf
Generated configuration file: /config/core/env
Generated configuration file: /config/core/app.conf
Generated configuration file: /config/registry/config.yml
Generated configuration file: /config/registryctl/env
Generated configuration file: /config/registryctl/config.yml
Generated configuration file: /config/db/env
Generated configuration file: /config/jobservice/env
Generated configuration file: /config/jobservice/config.yml
loaded secret from file: /data/secret/keys/secretkey
Generated configuration file: /compose_location/docker-compose.yml
Clean up the input dir

#再次重启harbor
root in 🌐 harbor-server in ~/harbor 
❯ docker-compose restart
[+] Restarting 9/9
 ✔ Container nginx              Started                                                                     1.6s 
 ✔ Container harbor-jobservice  Started                                                                     1.8s 
 ✔ Container harbor-log         Started                                                                    10.3s 
 ✔ Container redis              Started                                                                     1.9s 
 ✔ Container harbor-db          Started                                                                     2.0s 
 ✔ Container registry           Started                                                                     1.2s 
 ✔ Container registryctl        Started                                                                     1.8s 
 ✔ Container harbor-core        Started                                                                     1.9s 
 ✔ Container harbor-portal      Started                                                                     2.0s
 
#再次尝试登录harbor即可！ 

#解释：在Harbor中，prepare脚本是用于准备和配置Harbor部署的工具。它是一个自动化脚本，可以帮助用户在部署Harbor之前进行一些准备工作和配置。

#具体来说，prepare脚本执行以下任务：
- 检查并设置必要的环境变量，例如HARBOR_HOME和HARBOR_VERSION。
- 检查并安装必要的依赖软件包，例如docker-compose。
- 配置Harbor的部署模式，例如单节点或多节点。
- 提供一些配置选项，例如是否启用HTTPS、是否启用LDAP认证等。
- 生成Harbor的配置文件和证书文件。
- 启动Harbor服务。
```

## 1.3、制作基础镜像，上传至harbor仓库中

```
#制作包含jdk的基础镜像
mkdir /dockerbuild  &&  cd /dockerbuild
tar -xzvf jdk-11.0.13_linux-x64_bin.tar.gz && mv jdk-11.0.13  jdk
#解压【jdk11】至当前目录下改名为jdk

#Dockerfile如下所示
vim Dockerfile

FROM daocloud.io/library/ubuntu:latest
##timezone配置时区
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
  &&  apt install -y tzdata --no-install-recommends \
  &&  echo "Asia/Shanghai" > /etc/timezone  \
  && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
  && dpkg-reconfigure -f noninteractive tzdata
##jdk11
ENV JAVA_HOME /usr/local/jdk
ENV PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH
ENV CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib:$JAVA_HOME/lib/tools.jar
ADD jdk /usr/local/jdk

docker build -t jdk_app  .		#-t打标签，.代表的是当前目录

#参数解释：
#其中ENV DEBIAN_FRONTEND noninteractive指令用于设置环境变量DEBIAN_FRONTEND为noninteractive。这个环境变量的设置告诉apt-get和其他相关工具在安装软件包时不要产生任何与用户交互的提示，以确保在自动化构建过程中不会发生任何阻塞。通过设置DEBIAN_FRONTEND为noninteractive，安装过程将默认采用非交互模式，自动选择默认选项并继续进行安装。
# --no-install-recommends选项表示不安装推荐的软件包
# dpkg-reconfigure -f noninteractive tzdata： 运行dpkg-reconfigure命令以非交互方式重新配置tzdata软件包，以应用新的时区设置


#查看构建好的基础镜像
root in 🌐 harbor-server in /dockerbuild took 2m20s 
❯ docker images
REPOSITORY                    TAG       IMAGE ID       CREATED              SIZE
jdk_app                       latest    7eecbd1a07a4   About a minute ago   406MB
```

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1722566196538-c0cf8961-0ad7-410b-bc3c-ad1f49fb8d34.png)

\#打标记、上传到harbor仓库中

docker tag jdk_app  10.36.135.254/public/jdk_app

docker push  10.36.135.254/public/jdk_app

**问题：怎么知道如何打tag？去到harbor仓库中，查看推送命令**

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1722566219223-d21cce6b-f40e-429d-b59f-3d8b31857c86.png)

**开始执行打标记、推送操作**

```
#在项目中标记镜像： 
docker tag SOURCE_IMAGE[:TAG] 192.168.17.112/library/REPOSITORY[:TAG]

#推送镜像到当前项目： 
docker push 192.168.17.112/library/REPOSITORY[:TAG]

#打tag标签
root in 🌐 harbor-server in /dockerbuild 
❯ docker tag jdk_app:latest 192.168.17.112/library/jdk_app:latest

root in 🌐 harbor-server in /dockerbuild 
❯ docker images
REPOSITORY                       TAG       IMAGE ID       CREATED         SIZE
192.168.17.112/library/jdk_app   latest    7eecbd1a07a4   7 minutes ago   406MB
#打完tag的镜像
jdk_app                          latest    7eecbd1a07a4   7 minutes ago   406MB

#推送到harbor
root in 🌐 harbor-server in /dockerbuild 
❯ docker push 192.168.17.112/library/jdk_app:latest
The push refers to repository [192.168.17.112/library/jdk_app]
d84f0cd802cb: Preparing 
13b80b6639bb: Preparing 
346be19f13b0: Preparing 
935f303ebf75: Preparing 
0e64bafdc7ee: Preparing 
unauthorized: authentication required

root in 🌐 harbor-server in /dockerbuild 
❯ echo $?
1
#这是推送失败的提示，原因是没有做登录操作

#登录harbor，发现无法登录
root in 🌐 harbor-server in /data/ssl 
❯ docker login -u admin -p Harbor12345  192.168.17.112
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
Error response from daemon: login attempt to https://192.168.17.112/v2/ failed with status: 401 Unauthorized

#原因是因为加了ca证书后，Harbor服务器启用了HTTPS，并且使用自签名证书，Docker客户端可能会拒绝与Harbor服务器建立安全连接。在这种情况下，您可以尝试跳过证书验证来进行登录，使用--insecure-registry选项或将证书添加到Docker的信任列表中。

#解决方法如下：
#其实就是ca证书出了问题，再重新拷贝一份证书覆盖到/etc/pki/……目录下即可
#系统导入并信任我们生成的CA证书
cp /data/ssl/ca.pem  /etc/pki/ca-trust/source/anchors
update-ca-trust extract
systemctl restart docker

#修改harbor参数以后重启harbor
cd /root/harbor/
./prepare
docker-compose down
docker-compose up -d

#再次登录
root in 🌐 harbor-server in ~/harbor 
❯ docker login -u admin -p Harbor12345  192.168.17.112
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded

#再次推送到harbor仓库
root in 🌐 harbor-server in ~/harbor 
❯ docker push 192.168.17.112/library/jdk_app:latest
The push refers to repository [192.168.17.112/library/jdk_app]
d84f0cd802cb: Pushed 
13b80b6639bb: Pushed 
346be19f13b0: Pushed 
935f303ebf75: Pushed 
0e64bafdc7ee: Pushed 
latest: digest: sha256:614f2de83769fdb66f5c3954ffb4b4c3a0152e7497613e4a65dd4cf62a6f8ae0 size: 1368
```

查看是否上传成功 

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1722566239545-13284d1d-b420-4fd7-8e52-c89f80225c48.png)

# 扩展  openssl 自检证书

```
部署harbor https认证实战
- 安装docker
	(1)下载docker的rpm包
[root@harbor.oldboyedu.com ~]# yum -y install wget
[root@harbor.oldboyedu.com ~]# wget http://192.168.15.253/Kubernetes/Day01-/softwares/oldboyedu-docker-ce-23_0_1.tar.gz


	(2)解压并安装软件包
[root@harbor.oldboyedu.com ~]# tar xf oldboyedu-docker-ce-23_0_1.tar.gz 
[root@harbor.oldboyedu.com ~]# yum -y localinstall oldboyedu-docker-ce-23_0_1/*.rpm


	(3)添加自动补全功能
[root@harbor.oldboyedu.com ~]# yum -y install bash-completion
[root@harbor.oldboyedu.com ~]# source /usr/share/bash-completion/bash_completion

	
	(4)配置镜像加速
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://tuv7rqqq.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload
systemctl restart docker


	(5)验证镜像加速是否成功
[root@harbor.oldboyedu.com ~]# docker info | grep "Registry Mirrors" -A 1
 Registry Mirrors:
  https://tuv7rqqq.mirror.aliyuncs.com/
[root@harbor.oldboyedu.com ~]# 


	(6)将docker设置为开机自启动
[root@harbor.oldboyedu.com ~]# systemctl enable --now docker
Created symlink from /etc/systemd/system/multi-user.target.wants/docker.service to /usr/lib/systemd/system/docker.service.
[root@harbor.oldboyedu.com ~]# 




- 安装docker compose
	(1)添加epel源
[root@harbor.oldboyedu.com ~]# curl  -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

	(2)安装docker-compose
[root@harbor.oldboyedu.com ~]# yum -y install docker-compose

	(3)查看docker-compose版本
[root@harbor.oldboyedu.com ~]# docker-compose version 
docker-compose version 1.18.0, build 8dd22a9
docker-py version: 2.6.1
CPython version: 3.6.8
OpenSSL version: OpenSSL 1.0.2k-fips  26 Jan 2017
[root@harbor.oldboyedu.com ~]# 


- 安装harbor
	(1)下载harbor软件包
[root@harbor.oldboyedu.com ~]# wget http://192.168.15.253/Kubernetes/Day01-/softwares/harbor-offline-installer-v1.10.10.tgz

	(2)创建工作目录
[root@harbor.oldboyedu.com ~]# mkdir -pv /oldboyedu/softwares

	(3)加压harbor软件包
[root@harbor.oldboyedu.com ~]# tar xf harbor-offline-installer-v1.10.10.tgz -C /oldboyedu/softwares/

	(4)创建证书的工作目录
[root@harbor.oldboyedu.com ~]# mkdir -pv /oldboyedu/softwares/harbor/certs/{ca,server,client}

	(5)生成自建CA证书
		5.1 进入证书目录
[root@harbor.oldboyedu.com ~]# cd /oldboyedu/softwares/harbor/certs/
		
		5.2 生成CA私钥
[root@harbor.oldboyedu.com certs]# openssl genrsa -out ca/ca.key 4096

		5.3 生成ca的自签名证书
[root@harbor.oldboyedu.com certs]# openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=oldboyedu.com" \
 -key ca/ca.key \
 -out ca/ca.crt
	
	
	(6)生成harbor服务器的证书文件及客户端证书
		6.1 生成harbor主机的私钥
[root@harbor.oldboyedu.com certs]# openssl genrsa -out server/harbor.oldboyedu.com.key 4096


		6.2 生成harbor主机的证书申请
[root@harbor.oldboyedu.com certs]# openssl req -sha512 -new \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=harbor.oldboyedu.com" \
    -key server/harbor.oldboyedu.com.key \
    -out server/harbor.oldboyedu.com.csr
    
    
		6.3 生成x509 v3扩展文件
[root@harbor.oldboyedu.com certs]# cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=oldboyedu.com
DNS.2=oldboyedu
DNS.3=harbor.oldboyedu.com
EOF


		6.4 使用"v3.ext"给harbor主机签发证书
[root@harbor.oldboyedu.com certs]# openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca/ca.crt -CAkey ca/ca.key -CAcreateserial \
    -in server/harbor.oldboyedu.com.csr \
    -out server/harbor.oldboyedu.com.crt
    
    
		6.5 将crt文件转换为cert客户端证书文件
[root@harbor.oldboyedu.com certs]# openssl x509 -inform PEM -in server/harbor.oldboyedu.com.crt -out server/harbor.oldboyedu.com.cert


		6.6 准备docker客户端证书
[root@harbor.oldboyedu.com certs]# cp server/harbor.oldboyedu.com.{cert,key} client/
[root@harbor.oldboyedu.com certs]# cp ca/ca.crt client/
[root@harbor.oldboyedu.com certs]# 
[root@harbor.oldboyedu.com certs]# ll client/
total 12
-rw-r--r-- 1 root root 2033 Apr 12 10:09 ca.crt
-rw-r--r-- 1 root root 2122 Apr 12 10:09 harbor.oldboyedu.com.cert
-rw-r--r-- 1 root root 3247 Apr 12 10:09 harbor.oldboyedu.com.key
[root@harbor.oldboyedu.com certs]# 


		6.7 查看所有证书文件结果
[root@harbor.oldboyedu.com certs]# ll -R
.:
total 4
drwxr-xr-x 2 root root  48 Apr 12 09:46 ca
drwxr-xr-x 2 root root  85 Apr 12 10:09 client
drwxr-xr-x 2 root root 135 Apr 12 09:47 server
-rw-r--r-- 1 root root 275 Apr 12 09:45 v3.ext

./ca:
total 12
-rw-r--r-- 1 root root 2033 Apr 12 09:41 ca.crt
-rw-r--r-- 1 root root 3243 Apr 12 09:40 ca.key
-rw-r--r-- 1 root root   17 Apr 12 09:46 ca.srl

./client:
total 12
-rw-r--r-- 1 root root 2033 Apr 12 10:09 ca.crt
-rw-r--r-- 1 root root 2122 Apr 12 10:09 harbor.oldboyedu.com.cert
-rw-r--r-- 1 root root 3247 Apr 12 10:09 harbor.oldboyedu.com.key

./server:
total 16
-rw-r--r-- 1 root root 2122 Apr 12 09:47 harbor.oldboyedu.com.cert
-rw-r--r-- 1 root root 2122 Apr 12 09:46 harbor.oldboyedu.com.crt
-rw-r--r-- 1 root root 1716 Apr 12 09:44 harbor.oldboyedu.com.csr
-rw-r--r-- 1 root root 3247 Apr 12 09:43 harbor.oldboyedu.com.key
[root@harbor.oldboyedu.com certs]# 



	(7)配置harbor服务器使用证书
		7.1 切换工作目录
[root@harbor.oldboyedu.com certs]# cd ..
[root@harbor.oldboyedu.com harbor]# 
[root@harbor.oldboyedu.com harbor]# pwd
/oldboyedu/softwares/harbor
[root@harbor.oldboyedu.com harbor]# 


		7.2 修改配置文件
[root@harbor.oldboyedu.com harbor]# echo alias yy=\'egrep -v \"\^.*#\|\^\$\"\'  >> /root/.bashrc 
[root@harbor.oldboyedu.com harbor]# 
[root@harbor.oldboyedu.com harbor]# source /root/.bashrc
[root@harbor.oldboyedu.com harbor]# 
[root@harbor.oldboyedu.com harbor]# yy harbor.yml 
hostname: harbor.oldboyedu.com
...
https:
  port: 443
  certificate: /oldboyedu/softwares/harbor/certs/server/harbor.oldboyedu.com.crt
  private_key: /oldboyedu/softwares/harbor/certs/server/harbor.oldboyedu.com.key
harbor_admin_password: 1
...


	(8)安装harbor服务
[root@harbor.oldboyedu.com harbor]# ./install.sh 


	(9)Windows验证harbor的https
		9.1 windows配置主机解析
# C:\Windows\System32\drivers\etc\hosts
...
10.0.0.250 harbor.oldboyedu.com

		9.2 浏览器访问
https://harbor.oldboyedu.com


	(10)Linux验证harbor的https
		10.1 配置地址解析
[root@harbor.oldboyedu.com ~]# echo 10.0.0.250 harbor.oldboyedu.com >> /etc/hosts


		10.2 在docker客户端节点创建自签证书域名存放路径
[root@harbor.oldboyedu.com ~]# mkdir -pv /etc/docker/certs.d/harbor.oldboyedu.com

		10.3 服务端将证书文件拷贝到客户端docker节点，若不执行该操作，则会报错"x509: certificate signed by unknown authority"
[root@harbor.oldboyedu.com ~]# cp /oldboyedu/softwares/harbor/certs/client/* /etc/docker/certs.d/harbor.oldboyedu.com/
[root@harbor.oldboyedu.com ~]# 
[root@harbor.oldboyedu.com ~]# ll /etc/docker/certs.d/harbor.oldboyedu.com/
total 12
-rw-r--r-- 1 root root 2033 Apr 12 10:11 ca.crt
-rw-r--r-- 1 root root 2122 Apr 12 10:11 harbor.oldboyedu.com.cert
-rw-r--r-- 1 root root 3247 Apr 12 10:11 harbor.oldboyedu.com.key
[root@harbor.oldboyedu.com ~]# 

		10.4 登录验证
[root@harbor.oldboyedu.com ~]# docker login -u admin -p 1 harbor.oldboyedu.com
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
[root@harbor.oldboyedu.com ~]# 


		10.5 退出登录
[root@harbor.oldboyedu.com ~]# more /root/.docker/config.json
{
	"auths": {
		"harbor.oldboyedu.com": {
			"auth": "YWRtaW46MQ=="
		}
	}
}
[root@harbor.oldboyedu.com ~]# 
[root@harbor.oldboyedu.com ~]# echo YWRtaW46MQ==
YWRtaW46MQ==
[root@harbor.oldboyedu.com ~]# 
[root@harbor.oldboyedu.com ~]# 
[root@harbor.oldboyedu.com ~]# echo YWRtaW46MQ== | base64 -d | more 
admin:1
[root@harbor.oldboyedu.com ~]# 
[root@harbor.oldboyedu.com ~]# docker logout harbor.oldboyedu.com
Removing login credentials for harbor.oldboyedu.com
[root@harbor.oldboyedu.com ~]# 
[root@harbor.oldboyedu.com ~]# more /root/.docker/config.json
{
	"auths": {}
}
[root@harbor.oldboyedu.com ~]# 

```