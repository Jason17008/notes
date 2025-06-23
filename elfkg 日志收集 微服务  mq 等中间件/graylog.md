

![](https://cdn.nlark.com/yuque/0/2024/png/35538885/1720863756943-da1c375a-888f-45ba-91eb-c5243f3f5b08.png)  


安装 

```plain
官网: https://www.graylog.org/
Graylog 是一个开源的日志聚合、分析、审计、展现和预警工具。

graylog技术栈的部署安装
1.安装jdk1.8
#解压并重命名
tar -xzvf jdk-8u211-linux-x64.tar.gz  -C /usr/local
mv /usr/local/jdk1.8.0_211/ /usr/local/java

#修改环境变量
    cat > /etc/profile.d/jdk.sh <<-EOF
    JAVA_HOME=/usr/local/java
    #指定java安装目录
    PATH=\$JAVA_HOME/bin:\$PATH
    #用于指定java系统查找命令的路径
    export JAVA_HOME PATH
    #类的路径，在编译运行java程序时，如果有调用到其他类的时候，在classpath中寻找需要的类。
EOF
    #刷新环境变量
    source /etc/profile



2.安装mongodb
cat > /etc/yum.repos.d/mongodb-org.repo<<EOF
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc
EOF

yum clean all && yum makecache && yum install mongodb-org  -y
3.启动服务
systemctl daemon-reload
systemctl enable mongod.service
systemctl start mongod.service
systemctl --type=service --state=active | grep mongod

4.安装elasticsearch
cat >  /etc/yum.repos.d/elasticsearch.repo<<EOF
[elasticsearch-7.x]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/oss-7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

yum clean all && yum makecache && yum install elasticsearch-oss  -y

vim  /etc/elasticsearch/elasticsearch.yml
cluster.name: graylog
action.auto_create_index: false

启动elasticsearch
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl restart elasticsearch.service
systemctl --type=service --state=active | grep elasticsearch

安装graylog-server  
cat >/etc/yum.repos.d/graylog.repo <<-EOF
[graylog]
name=graylog
baseurl=https://packages.graylog2.org/repo/el/stable/4.2/\$basearch/
gpgcheck=1
repo_gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-graylog
EOF

yum clean all && yum makecache && yum install graylog-server  pwgen  -y

#如果安装失败,是gpg签名问题,报错:获取 GPG 密钥失败：[Errno 14] curl#37 - "Couldn't open file /etc/pki/rpm-gpg/RPM-GPG-KEY-graylog"
则,执行以下命令:yum install graylog-server  pwgen  -y --nogpgcheck  不验证签名

修改 /etc/sysconfig/graylog-server
定义源码jdk路径
JAVA=/usr/local/jdk/bin/java

pwgen -N 1 -s 96
#生成96位的密码，这个在使用集群的时候，可以使用

生成的密码串配置在server.conf中
vim /etc/graylog/server/server.conf
password_secret =  密码串

创建您的root_password_sha2，运行以下命令：
echo -n "Enter Password: " && head -1 </dev/stdin | tr -d '\n' | sha256sum | cut -d" " -f1
要输入admin的密码，才能生成字符串，密码是自己定义的。
#例:
echo -n "Enter Password: " && head -1 </dev/stdin | tr -d '\n' | sha256sum | cut -d" " -f1
Enter Password: QianFeng@123	#自定义密码
4f345d67039cf53d50efdf4e249499c788e3655b51d34f53f0b7687ffb36de01	#生成出来的字符串


生成的字符串配置在root_password_sha2中
vim /etc/graylog/server/server.conf
root_password_sha2 = 字符串


其他配置
#设置 Graylog Web 界面的绑定地址
http_bind_address = 0.0.0.0:9000

#设置时区
root_timezone = Asia/Shanghai

#设置 Graylog Web 界面的公开访问地址
http_publish_uri = http://192.168.17.129:9000/


启动graylog
systemctl daemon-reload
systemctl enable graylog-server.service
systemctl start graylog-server.service
systemctl --type=service --state=active | grep graylog

netstat -ntlp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name          
tcp        0      0 127.0.0.1:27017         0.0.0.0:*               LISTEN      2601/mongod         
tcp6       0      0 127.0.0.1:9300          :::*                    LISTEN      3273/java
tcp6       0      0 ::1:9300                :::*                    LISTEN      3273/java   
tcp6       0      0 :::9000                 :::*                    LISTEN      17001/java                
tcp6       0      0 127.0.0.1:9200          :::*                    LISTEN      3273/java           
tcp6       0      0 ::1:9200                :::*                    LISTEN      3273/java

#web界面访问:http://192.168.17.129:9000/
默认管理员用户名admin，密码为root_password_sha2步骤配置设定的密码，即：123456

源码下载连接如下 
wget   https://downloads.graylog.org/releases/graylog/graylog-4.2.13.tgz


```



# 开始配置
0.graylog_server配置

![](https://cdn.nlark.com/yuque/0/2024/jpeg/35538885/1720865105595-1ad3a9e9-7401-4b63-8b78-44f4712b6e3d.jpeg)

![](https://cdn.nlark.com/yuque/0/2024/png/35538885/1720865110729-853c0bb0-f7d7-488a-b532-da8abfb3c7df.png)

配置fiebeat 客户端

```plain
1.安装filebeat并启动
下载地址
https://www.elastic.co/cn/downloads/past-releases#filebeat
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.13.2-linux-x86_64.tar.gz


配置systemd启动
tar -xzvf filebeat-7.13.2-linux-x86_64.tar.gz -C /usr/local/
mv /usr/local/filebeat-7.13.2-linux-x86_64/  /usr/local/filebeat

cat  >/usr/lib/systemd/system/filebeat.service <<-EOF
[Unit]
Description=Filebeat
Wants=network-online.target
After=network-online.target

[Service]

ExecStart=/usr/local/filebeat/filebeat -c /usr/local/filebeat/filebeat.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload && systemctl enable --now  filebeat

2.filebeat写入到graylog中
sed -ri.bak '/^.*#/d;/^$/d' /usr/local/filebeat/filebeat.yml	#删除空行和注释
vim /usr/local/filebeat/filebeat.yml

filebeat.inputs:
- input_type: log
  paths:
    - /var/log/nginx/*.log
  type: log
  ###多行合并展现
  tail_files: true
  multiline.type: pattern
  multiline.pattern: '^\d{4}'
  multiline.negate: true
  multiline.match: after
output.logstash:
   hosts: ["192.168.241.13:5044"]



#完整的配置文件如下：
filebeat.inputs:
- type: log
  enabled: false
  paths:
    - /var/log/*.log
- type: filestream
  enabled: false
  paths:
    - /var/log/*.log
- input_type: log
  paths:
    - /var/log/nginx/*.log
  type: log
  ###多行合并展现
  tail_files: true
  multiline.type: pattern·
  multiline.pattern: '^\d{4}'
  multiline.negate: true
  multiline.match: after
filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 1
setup.kibana:
output.logstash:
  hosts: ["192.168.17.128:5044"]
processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~



3.本地安装nginx并启动
yum -y install nginx && systemctl enable --now nginx

4.重启filebeat服务
systemctl restart filebeat
netstat -ntlp|grep 5044






```

2.配置stream

![](https://cdn.nlark.com/yuque/0/2024/jpeg/35538885/1720880298087-1df746f7-759b-4dd8-bb61-eadb3c97ed7e.jpeg)

![](https://cdn.nlark.com/yuque/0/2024/jpeg/35538885/1720880312061-5082cac4-d4e8-436c-8440-2348f4a77541.jpeg)

![](https://cdn.nlark.com/yuque/0/2024/jpeg/35538885/1720880317643-e466642a-1d9c-4522-84b3-7f47d766faf9.jpeg)

