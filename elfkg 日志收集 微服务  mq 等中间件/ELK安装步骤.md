# 引文：

本文章中使用的ES，kibana，filebeat和logstash包版本都是7.6.2

下载地址：https://www.elastic.co/cn/downloads/

# 一.Elasticsearch

使用安装部署脚本安装软件

## 定期删除es索引数据

编写shell脚本：**es-index-clear.sh**

```
#/bin/bash
#es-index-clear
#只保留15天内的日志索引
LAST_DATA=`date -d "-15 days" "+%Y.%m.%d"`
curl -XDELETE http://IP地址:9200/*${LAST_DATA} --user 账号:密码
```

执行命令：crontab -e，每天凌晨一点清除索引

```
0 1 * * * /脚本所在路径/es-index-clear.sh
```

## 单节点重启之后健康状态是yellow,解决方法如下

这个错是因为安装的时候Elasticsearch是单节点，但是分片默认有一个副分区，所以报此警告

具体参考:[https://blog.csdn.net/gamer_gyt/article/details/53230165](https://links.jianshu.com/go?to=https%3A%2F%2Fblog.csdn.net%2Fgamer_gyt%2Farticle%2Fdetails%2F53230165)

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329202134-c46c32e9-400b-4332-bd64-d18235029d48.png)

提交请求:curl -XPUT "http://localhost:9200/_settings" -d '{"number_of_replicas":0}'

# 二.Elastalert(日志告警)

## 配置python3.6.9环境

```
yum -y install wget openssl openssl-devel gcc gcc-c++
#下载包
wget https://www.python.org/ftp/python/3.6.9/Python-3.6.9.tgz
```

```
tar xf Python-3.6.9.tgz
#换色部分使用root用户执行
cd Python-3.6.9 
./configure --prefix=/usr/local/python --with-openssl
make && make install
```

配置

```
#使用root账户执行命令
mv /usr/bin/python /usr/bin/python_old
ln -s /usr/local/python/bin/python3 /usr/bin/python
ln -s /usr/local/python/bin/pip3 /usr/bin/pip
pip install --upgrade pip
```

使用yum命令随机下载一个命令，例如sudo yum install -y git

此时会出现报错，根据提示修改文件

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329202025-40ff395f-25a4-4425-b1ea-7c636319f448.png)

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329202036-ad69ca61-30ab-45f3-85bb-b5da6c68fb3b.png)

进入到/bin/yum中修改第一行数据，将#!/usr/bin/python改成#!/usr/bin/python2.7

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329202072-0f4bef99-c99e-4772-a797-da542605fbae.png)

文件/usr/libexec/urlgrabber-ext-down中也一样

验证：

```
python -V
    Python 3.6.9
$ pip -V 
        pip 19.3 from /usr/local/python/lib/python3.6/site-packages/pip (python 3.6)
```

## **安装elastalert**

下载包

```
git clone https://github.com/Yelp/elastalert.git
cd elastalert
```

安装

```
pip install "elasticsearch<7,>6"
pip install -r requirements.txt
sudo python setup.py install
```

安装成功之后可以看到四个命令

```
ll /usr/local/python/bin/elastalert*
    /usr/local/python/bin/elastalert
    /usr/local/python/bin/elastalert-create-index
    /usr/local/python/bin/elastalert-rule-from-kibana
    /usr/local/python/bin/elastalert-test-rule
```

软连接到/usr/bin下面，方便使用

```
sudo ln -s /usr/local/python/bin/elastalert* /usr/bin
```

配置config.yaml(注意修改文件中的路径)

```
cd elastalert
vi config.yaml #黄色部分是内容
rules_folder: /home/devops/elastalert/rules
run_every:
  minutes: 1
buffer_time:
  minutes: 15
es_host: ESIP地址
es_port: ES端口
es_username: ES登录账户
es_password: ES登录密码
writeback_index: elastalert_status
writeback_alias: elastalert_alerts
alert_time_limit:
  days: 2
```

创建告警索引

```
elastalert-create-index
```

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329202013-71178cb5-4062-482a-93b0-bb03a8a4b12f.png)

ES中可以看到创建成功的索引

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329204096-b5c4ebb5-38c5-4b81-9761-c0f8d827d100.png)

获取配置飞书插件

```
git clone https://github.com/gpYang/elastalert-feishu-plugin.git
```

插件拉取之后将elastalert_modules文件夹放到elastalert文件夹下：

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329204143-06ae977f-09b1-4dd7-bfbd-98fd592c2934.png)

将elastalert路径写入loaders.py文件最上方

```
sudo vi /usr/local/python/lib/python3.6/site-packages/elastalert-0.2.4-py3.6.egg/elastalert/loaders.py
#黄色部分为写入的内容
import sys
sys.path.append("elastalert_modules所在文件夹路径")
```

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329204162-28a45dda-4185-4561-ba34-cdc55964bc24.png)

配置rules(注意修改配置中的路径)

```
mkdir rules
cd rules
vi logWarning.yaml #下方黄色部分为内容
name: logWarningrule
es_host: ESip地址
es_port: ES端口
es_username: ES登录账号
es_password: ES登录密码
type: frequency
#正则匹配es中的索引
index: cmdb*
#限定时间内，发生事件次数
num_events: 3
#与上面参数结合使用，当前表示在1分钟内发生3次就报警
timeframe:
  minutes: 1 
filter:
- query:
    match:
      message: "*ERROR*" 
alert:
- "elastalert_modules.feishu_alert.FeishuAlert"
feishualert_url: "https://open.feishu.cn/open-apis/bot/v2/hook/"
feishualert_botid: "飞书机器人webook中url的最后一段"
feishualert_title: "日志告警"
feishualert_body: 
  "
   日志告警\n
   来源：{app}\n
   告警信息：{message}\n
   日志信息：{log}\n
   告警匹配数：{num_matches}\n
  "
```

测试规则

执行命令测试刚刚配置的规则，如图所示，没有报错，则可以使用

```
elastalert-test-rule --config config.yaml rules/logWarning.yaml
```

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329204195-4eb16042-6ec1-47d1-9579-338a0847411c.png)

如果报错：

```
pip list | grep elasticsearch #查看elasticsearch版本，如果版本不是7.0.0
pip uninstall elasticsearch -y 
pip install elasticsearch==7.0.0
pip uninstall jira
pip install jira==3.2.0
```

创建service文件

```
sudo vi /usr/lib/systemd/system/elastalert.service
#黄色部分为配置内容
[unit]
Description=elastalert Server 
After=network.target
[Service] 
User=devops 
Group=devops
Type=simple 
Restart=on-failure 
WorkingDirectory=/home/devops/elastalert
ExecStart=/usr/local/python/bin/python3 -m elastalert.elastalert --verbose --config /home/devops/elastalert/config.yaml
 
[Install] 
WantedBy=multi-user.target
```

执行命令启动

```
#重新加载service环境
sudo systemctl daemon-reload
#启动elastalert
sudo systemctl start elastalert
#查看elastalert状态
sudo systemctl status elastalert
#添加开机自启
sudo systemctl enable elastalert.service
```

# 三.kibana

## 1.将压缩包上传到服务器/opt目录下，执行命令：

cd /opt

sudo tar -zxvf kibana-7.6.2-linux-x86_64.tar.gz

sudo ln -s kibana-7.6.2-linux-x86_64 kibana

sudo chown -R {用户}:{组} kibana-7.6.2-linux-x86_64 kibana

sudo chown -h {用户}:{组} kibana

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329204467-bbc56e8a-53ce-4971-980f-b663783890f0.png)

## 2.修改kibana配置文件，执行命令:

cd /opt/kibana/config

vi vi kibana.yml

  server.port: 5601

  server.host: "kibana地址"

  elasticsearch.hosts: ["http://es地址:9200"]

  elasticsearch.username: "es登录用户"

  elasticsearch.password: "es登录密码"

  elasticsearch.preserveHost: true

  elasticsearch.pingTimeout: 1500

  elasticsearch.requestTimeout: 30000

  pid.file: /opt/kibana/config/kibana.pid

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329204776-c07b0cb9-d96d-4406-ac41-478135aac1db.png)

## 3.配置service文件，执行命令

sudo vi /usr/lib/systemd/system/kibana.service

  [Unit]

  Description=Kibana

  [Service]

  Type=simple

  User=用户

  Group=用户组

  EnvironmentFile=-/opt/kibana/config

  EnvironmentFile=-/opt/kibana

  ExecStart=/opt/kibana/bin/kibana "-c /opt/kibana/config/kibana.yml"

  Restart=always

  WorkingDirectory=/

  [Install]

  WantedBy=multi-user.target

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329204816-17e8044e-09b3-48f0-a61e-263f5b7f2cfe.png)

## 4.启动kibana，以及配置开机自启，执行命令：

sudo systemctl daemon-reload #新增或修改service文件后需要先执行此命令reload环境

suddo system start kibana #启动kibana命令

sudo systemctl status kibana #查看kibana启动状态的命令

sudo systemctl enable kibana #将kibana设置开机自启

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329204901-bc1b17e3-5750-412d-80ba-ede073d9d834.png)

## 5.登录页面查看kibana

登录地址：http://kibanaIP:5601

账户号密码为elasticsearch的登录账号密码

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329205191-ce58966e-4fac-470c-a5e9-7e07f340b7f0.png)

# 四.FileBeat

执行filebeat安装部署脚本

## 目前脚本部署只支持filebeat推送至es，需要手动修改filebeat配置

vi /opt/filebeat/filebeat.yml

output.logstash：推送的logstash地址

paths：监控的日志

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329205106-eb170498-f0ed-4600-8d24-7dea6696b156.png)

# 五.logstash

## 1.将压缩包上传到服务器/opt目录下，执行命令

cd /opt

sudo tar -zxvf logstash-7.6.2.tar.gz

sudo ln -s logstash-7.6.2 logstash

sudo chown -R {用户}:{组} logstash-7.6.2

sudo chown -h {用户}:{组} logstash

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329205247-88701f7e-4512-4148-bc50-5132dc1ebb51.png)

## 2.修改logstash配置，执行命令：

cd /opt/logstash-7.6.2/config

vi logstash-sample.conf

  \# Sample Logstash configuration for creating a simple

  \# Beats -> Logstash -> Elasticsearch pipeline.

  input {

   beats {

   port => 5044

   }

  }

  \#filter {

  \# mutate {

  \# split => {"message"=>"|"}

  \# }

  \#}

  output {

   elasticsearch {

   hosts => ["http://{es地址}:9200"]

   index => "%{+YYYY.MM.dd}" #输出到es的格式

   user => "{es登录账号}"

   password => "{es登录密码}"

   }

  }

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329205416-58623e73-d3ea-46a8-8fc5-dc0e2d6dfef0.png)

## 3.配置service文件，执行命令

sudo vi /usr/lib/systemd/system/logstash.service 

  [Unit]

  Description=logstash

  [Service]

  Type=simple

  User=devops

  Group=devops

  EnvironmentFile=-/opt/logstash

  EnvironmentFile=-/opt/logstash

  ExecStart=/opt/logstash/bin/logstash "--path.settings" "/opt/logstash/config" "--path.config" "/opt/logstash/config/logstash-sample.conf"

  Restart=always

  WorkingDirectory=/

  Nice=19

  LimitNOFILE=16384

  [Install]

  WantedBy=multi-user.target

4.启动logstash，配置自启动

sudo systemctl daemon-reload #新增或修改service文件后需要先执行此命令reload环境

suddo system start logstash #启动logstash命令

sudo systemctl status logstash #查看logstash启动状态的命令

sudo systemctl enable logstash #将logstash设置开机自启

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329205537-1ddb72fb-7a1a-4f66-b3ac-c770f4a50a8d.png)

5.启动es-head查看数据

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329205591-e5d51ef3-55a2-4415-9898-b31b1b684fb3.png)