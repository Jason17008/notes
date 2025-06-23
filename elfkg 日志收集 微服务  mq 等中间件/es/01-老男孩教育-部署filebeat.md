# 一、beats简介

```
    Beats可以将数据直接发送到Elasticsearch或通过Logstash发送，您可以在此处进一步处理和增强数据，然后再在Kibana中进行可视化。

    常用的Beats如下所示:
        审计数据(Audit data):
            Auditbeat
    
        日志文件(Log files):
            Filebeat
    
        云数据(Cloud data):
            Functionbeat
    
        监控检查数据(Availability):
            Heartbeat
    
        系统日志(Systemd journals):
            Journalbeat
    
        服务指标数据(Metrics):
            Metricbeat
    
        网络流量数据(Network traffic):
            Packetbeat
    
        Windows事件日志(Windows event logs):
            Winlogbeat

    推荐阅读:
       https://www.elastic.co/guide/en/beats/libbeat/current/index.html
 
```

![image-20210529210745551](01-老男孩教育-部署filebeat.assets/image-20210529210745551.png)



# 二、filebeat概述

## 1.什么是filebeat

```
	filebeat是用于"转发"和"集中日志数据"的轻量级数据采集器。

	filebeat会监视指定的日志文件路径，收集日志事件并将数据转发到elasticsearch，logstash，redis，kafka存储服务器。

    当您要面对成百上千，甚至成千上万的服务器，虚拟机的容器生成的日志时，请告别SSH吧。Filebeat将为您提供一种轻量级方法，用于转发和汇总日志与文件，让简单的事情不再繁杂。

官方网站:
	https://www.elastic.co/cn/beats/filebeat

```



## 2.filebeat的组件

```
	Filebeat包含两个主要组件，input(输入)和Harvester(收割机)，两个组件协同工作将文件的尾部最新数据发送出去。

	Harveste组件:
    	负责逐行读取单个文件的内容，然后将内容发送到输出。
    	
	input组件:
		输入负责管理收割机并找到所有要读取的源。该参数的源文件路径需要使用者手动配置。
		
    Spooler(缓冲区):
        如下图所示，将Harvester组件采集的数据进行统一的缓存，并发往目的端，可以是Elasticsearch，Logstash，kafka和Redis等。
        
	推荐阅读:
		https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-overview.html

```

![image-20210529213826372](01-老男孩教育-部署filebeat.assets/image-20210529213826372.png)



## 3.filebeat工作原理

```
	filebeat工作流程如下:
		(1)当filebeat启动后，filebeat通过Input读取指定的日志路径;
		(2)然后为该文件日志启动一个收割进程harvester，每一个收割进程读取一个日志文件的新内容,并发送这些新的日志数据到处理程序spooler;
		(3)处理程序spooler会集合这些事件，最后filebeat会发送集合的数据到你指定的位置。
	
	        
	Filebeat如何保持文件的状态？
		Filebeat保持每个文件的状态，并经常将状态刷新到注册表文件(data/registry/filebeat/log.json)中的磁盘。该状态用于记住收割机读取的最后一个偏移量，并确保发送所有日志行。

	Filebeat如何确保至少一次交付？
		Filebeat保证事件将至少传送到配置的输出一次并且不会丢失数据。Filebeat能够实现这种行为，因为它将每个事件的传递状态存储在注册表文件中。
		
	推荐阅读:
		https://www.elastic.co/guide/en/beats/filebeat/current/how-filebeat-works.html
		
```



# 三、部署filebeat环境

## 1.解压filebeat软件包

```bash
# filebeat的官网下载
https://www.elastic.co/cn/downloads/past-releases#filebeat		# 可选择版本
# 下载到windows然后上传到linux即可

[root@elk101.oldboyedu.com ~]# tar xf filebeat-7.12.1-linux-x86_64.tar.gz -C /oldboy/softwares/
[root@elk101.oldboyedu.com ~]# 

[root@elk101.oldboyedu.com /oldboy/softwares]# ln -sv filebeat-7.12.1-linux-x86_64 filebeat
"filebeat" -> "filebeat-7.12.1-linux-x86_64"
[root@elk101.oldboyedu.com /oldboy/softwares]# 
[root@elk101.oldboyedu.com /oldboy/softwares]# cd
[root@elk101.oldboyedu.com ~]# 
[root@elk101.oldboyedu.com ~]# vim /etc/profile.d/filebeat.sh
[root@elk101.oldboyedu.com ~]# 
[root@elk101.oldboyedu.com ~]# cat /etc/profile.d/filebeat.sh
#!/bin/bash

export FILE_BEAT=/oldboy/softwares/filebeat
export PATH=$PATH:$FILE_BEAT
[root@elk101.oldboyedu.com ~]# 
[root@elk101.oldboyedu.com ~]# source /etc/profile.d/filebeat.sh
[root@elk101.oldboyedu.com ~]# 
[root@elk101.oldboyedu.com ~]# 
[root@elk101.oldboyedu.com ~]# fi
fi                    filefrag              findfs                fipshmac              firewall-offline-cmd  
file                  find                  findmnt               firewall-cmd          fixfiles              
filebeat              find2perl             fipscheck             firewalld             
[root@elk101.oldboyedu.com ~]# ll
总用量 32068
drwxr-xr-x 4 root root       33 5月  29 23:25 conf
-rw-r--r-- 1 root root 32835893 5月  14 21:04 filebeat-7.12.1-linux-x86_64.tar.gz
[root@elk101.oldboyedu.com ~]# 
[root@elk101.oldboyedu.com ~]# rm -f /usr/local/bin/filebeat 
[root@elk101.oldboyedu.com ~]# 
[root@elk101.oldboyedu.com ~]# which filebeat 
/oldboy/softwares/filebeat/filebeat

```





## 2.查看filebeat工具的帮助信息

```
[root@elk101.oldboyedu.com ~]# filebeat -h
Usage:
  filebeat [flags]
  filebeat [command]

Available Commands:
  enroll      注册Kibana进行中央管理
  export      导出当前配置或索引模板
  generate    生成Filebeat模块、文件集和字段.yml
  help        关于任何命令的帮助
  keystore    管理机密密钥库
  modules     管理配置的模块
  run         运行filebeat
  setup        设置索引模板、仪表板和ML作业
  test        测试配置
  version     显示当前版本信息

Flags:
  -E, --E setting=value              配置覆盖
  -M, --M setting=value              模块配置覆盖
  -N, --N                            禁用测试的实际发布
  -c, --c string                     配置文件，相对于path.config（默认为“filebeat.yml”）
  -d, --d string                     启用某些调试选择器
  -e, --e                            登录到stderr并禁用syslog/file输出
	  --environment environmentVar   设置正在运行的环境（默认）
      -h, --help                     filebeat的帮助    
      --httpprof string              启动PPROF HTTP服务器
      --memprofile string            将内存配置文件写入此文件
      --modules string               已启用模块列表（逗号分隔）
      --once                         只运行filebeat一次，直到所有收割机达到EOF
      --path.config string           配置路径
      --path.data string             数据路径
      --path.home string             指定家路径
      --path.logs string             日志路径
      --plugin pluginList            加载其他插件
      --strict.perms                 对配置文件进行严格的权限检查（默认为true）
	-v, --v                          查看INFO level级别的日志信息，该级别日志很详细。

Use "filebeat [command] --help" for more information about a command.
[root@elk101.oldboyedu.com ~]# 



推荐阅读:
	https://www.elastic.co/guide/en/beats/filebeat/current/command-line-options.html

```



## 3.运行第一个filebeat实例，将标准输入的数据进行标准输出

```
[root@elk101.oldboyedu.com ~/conf]# vim stdin-to-console.yaml
[root@elk101.oldboyedu.com ~/conf]# 
[root@elk101.oldboyedu.com ~/conf]# cat stdin-to-console.yaml
filebeat.inputs:
- type: stdin
  enabled: true

output.console:
  pretty: true
  enable: true
[root@elk101.oldboyedu.com ~/conf]# 
[root@elk101.oldboyedu.com ~/conf]# filebeat -e -c stdin-to-console.yaml 

...(一堆日志信息)

hello oldboyedu  # 该行是咱们输出的数据
{
  "@timestamp": "2021-05-29T14:46:50.454Z",  # 时间戳信息
  "@metadata": {  # 元数据信息
    "beat": "filebeat",  # beat类型
    "type": "_doc",  # 文档类型
    "version": "7.12.1"  # 软件的版本编号
  },
  "ecs": {  # 对应的ESC信息，战术性忽略该值。我猜想应该不是只的云服务器的ESC。
    "version": "1.8.0"
  },
  "host": {  # 主机信息
    "name": "elk101.oldboyedu.com"
  },
  "agent": {  # 客户端相关信息
    "name": "elk101.oldboyedu.com",  # 名称
    "type": "filebeat",  # 类型
    "version": "7.12.1",  # 版本号
    "hostname": "elk101.oldboyedu.com",  # 主机名
    "ephemeral_id": "91babbb8-dc6e-45f1-8f3f-a2a376addbbe",
    "id": "39544967-3c36-42c9-96e7-772df657eead"
  },
  "log": {  # 日志信息
    "offset": 0,  # 偏移量
    "file": {  # 文件信息
      "path": ""  # 由于我们的配置文件中并没有指定文件，因此路径为空。
    }
  },
  "message": "hello oldboyedu",  # 这才是我们这正输入的数据，其它数据均是filebeat自行添加的。
  "input": {  # 输入信息
    "type": "stdin"  # 输出的类型
  }
}


温馨提示:
	(1)注意观察启动后，在当前目录下会多出来一个data目录哟~强烈查看一下"data/registry/filebeat/"目录。
	(2)如果该data目录存在，则我们无法在当前目录下继续启动新的配置文件，否则会报错""
```

![image-20210529225009153](01-老男孩教育-部署filebeat.assets/image-20210529225009153.png)



# 四、rsyslog部署使用(了解即可)

```shell
# 将日志收集到一个文件里面然后打到ES数据库里面

(1)安装rsyslog
	[root@elk103.oldboyedu.com ~]# yum -y install rsyslog

(2)配置rsyslog
	[root@elk103.oldboyedu.com ~]# vim /etc/rsyslog.conf 
	...

	# 开启TCP协议监听端口
	$ModLoad imtcp
	$InputTCPServerRun 514

	...

	# 配置收集日志的方式，目的是将本地所有日志聚合在同一个文件。
	*.*                                                /var/log/oldboyedu.log

(3)仅供参考
	[root@elk103.oldboyedu.com ~/conf/project/syslog]# vim 01-rsyslog-to-es.yaml 
	[root@elk103.oldboyedu.com ~/conf/project/syslog]# 
	[root@elk103.oldboyedu.com ~/conf/project/syslog]# 
	[root@elk103.oldboyedu.com ~/conf/project/syslog]# cat 01-rsyslog-to-es.yaml 
	filebeat.inputs:
	- type: log
	  paths:
		- /var/log/oldboyedu.log
	  tags: rsyslog

	output.elasticsearch:
	  hosts: ["elk101.oldboyedu.com:9200","elk102.oldboyedu.com:9200","elk103.oldboyedu.com:9200"]
	  #index: "oldboy-2021-%{[agent.version]}-%{+yyyy.MM.dd}"
	  indices:
		- index: "oldboyedu-rsyslog-%{+yyyy.MM.dd}"
		  when.contains:
			tags: "rsyslog"


	setup.ilm.enabled: false
	setup.template.name: "oldboyedu-rsyslog"
	setup.template.pattern: "oldboyedu-rsyslog*"
	setup.template.settings:
	  index.number_of_shards: 3
	  index.number_of_replicas: 0
```



# 企业实战

## 01.Nginx日志收集

```shell
一.nginx日志收集
(1)安装nginx
[root@elk103.oldboyedu.com ~]# yum -y install epel-release
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# yum -y install nginx


(2)创建配置文件
[root@elk103.oldboyedu.com ~]# vim /etc/nginx/conf.d/elk103.oldboyedu.com.conf
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# cat /etc/nginx/conf.d/elk103.oldboyedu.com.conf
server {
	listen 80;
	
	server_name elk103.oldboyedu.com;

	root /oldboy/data/nginx/code;

	location / {
		index index.html;
	}
}
[root@elk103.oldboyedu.com ~]# 


(3)创建测试数据
[root@elk103.oldboyedu.com ~]# mkdir -pv /oldboy/data/nginx/code
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# echo "<h1>linux75</h1>" > /oldboy/data/nginx/code/index.html
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# cat /oldboy/data/nginx/code/index.html
<h1>linux75</h1>
[root@elk103.oldboyedu.com ~]# 



(4)检查配置文件
[root@elk103.oldboyedu.com ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@elk103.oldboyedu.com ~]# 


(5)启动nginx服务
[root@elk103.oldboyedu.com ~]# systemctl start nginx



(6)测试nginx服务
	随机1~5秒钟发起一次"curl elk103.oldboyedu.com"请求。

# 编写脚本
[root@elk103.oldboyedu.com nginx]#cat /server/scripts/nginx.sh 
#!/bin/bash
while true
  do
  for i in "curl elk103.oldboyedu.com"
    do
	Time=$((RANDOM%5 +1 ))
	echo "本次间隔时间为：$Time"
	curl elk103.oldboyedu.com
	sleep $Time
  done
done



二.配置nginx收集JSON
(1)修改nginx的配置文件
	[root@elk103.oldboyedu.com ~]# vim /etc/nginx/nginx.conf
	
	...
	
    # 自定义nginx的日志格式为json格式
    log_format oldboyedu_nginx_json '{"@timestamp":"$time_iso8601",' 
                              '"host":"$server_addr",' 
                              '"clientip":"$remote_addr",' 
                              '"size":$body_bytes_sent,' 
                              '"responsetime":$request_time,' 
                              '"upstreamtime":"$upstream_response_time",' 
                              '"upstreamhost":"$upstream_addr",' 
                              '"http_host":"$host",' 
                              '"uri":"$uri",' 
                              '"domain":"$host",' 
                              '"xff":"$http_x_forwarded_for",' 
                              '"referer":"$http_referer",' 
                              '"tcp_xff":"$proxy_protocol_addr",' 
                              '"http_user_agent":"$http_user_agent",' 
                              '"status":"$status"}';


    access_log  /var/log/nginx/access.log  oldboyedu_nginx_json;


(2)测试配置文件是否正常
	[root@elk103.oldboyedu.com ~]# nginx -t
	nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
	nginx: configuration file /etc/nginx/nginx.conf test is successful
	[root@elk103.oldboyedu.com ~]# 

(3)重新加载nginx
	systemctl reload nginx
	
(4)配置filebeat的配置文件
	[root@elk103.oldboyedu.com ~/conf/project/nginx]# cat 02-nginx-to-es.yaml 
	filebeat.inputs:
	- type: log
	  paths: 
		- /var/log/nginx/access.log
	  tags: "nginx"
	  # 默认值为false，我们需要修改为true，即不会将消息存储至message字段!
	  json.keys_under_root: true

	output.elasticsearch:
	  hosts: ["elk101.oldboyedu.com:9200","elk102.oldboyedu.com:9200","elk103.oldboyedu.com:9200"]
	  #index: "oldboy-2021-%{[agent.version]}-%{+yyyy.MM.dd}"
	  indices:
		- index: "oldboyedu-linux75-nginx2021-%{+yyyy.MM.dd}"
		  when.contains:
			tags: "nginx"

	# 禁用索引的生命周期!
	setup.ilm.enabled: false
	# 指定索引模板的名称
	setup.template.name: "oldboyedu"
	# 指定索引模板的匹配模式
	setup.template.pattern: "oldboyedu-linux75-nginx*"
	# 指定索引模板的分片信息
	setup.template.settings:
	  index.number_of_shards: 5
	  index.number_of_replicas: 0
	[root@elk103.oldboyedu.com ~/conf/project/nginx]# 

(5)检查数据是否写入ES
	略。
	
	
课堂练习：
	(1)查询ES数据库nginx日志索引的"clientip","http_user_agent","status"等字段信息;
	GET    Nginx的URL
	{
    "_source":["clientip","http_user_agent","status"]
	}
	
	
	(2)基于上一步骤的数据进行分页，每页显示6条，查询第最后一页;
	{
    "_source": [
        "clientip",
        "http_user_agent",
        "status"
    ],
    "from":600,
    "size":6
    }
	

三.收集nginx的错误日志
[root@elk103.oldboyedu.com ~/conf/project/nginx]# cat 03-nginx-to-es.yaml 
filebeat.inputs:
- type: log
  paths: 
    - /var/log/nginx/access.log
  tags: "nginx-access"
  # 默认值为false，我们需要修改为true，即不会将消息存储至message字段!
  json.keys_under_root: true


- type: log
  paths: 
    - /var/log/nginx/error.log
  tags: "nginx-error"


output.elasticsearch:
  hosts: ["elk101.oldboyedu.com:9200","elk102.oldboyedu.com:9200","elk103.oldboyedu.com:9200"]
  #index: "oldboy-2021-%{[agent.version]}-%{+yyyy.MM.dd}"
  indices:
    - index: "oldboyedu-linux75-nginx-access-%{+yyyy.MM.dd}"
      when.contains:
        tags: "nginx-access"

    - index: "oldboyedu-linux75-nginx-error-%{+yyyy.MM.dd}"
      when.contains:
        tags: "nginx-error"

# 禁用索引的生命周期!
setup.ilm.enabled: false
# 指定索引模板的名称
setup.template.name: "oldboyedu"
# 指定索引模板的匹配模式
setup.template.pattern: "oldboyedu-linux75-nginx*"
# 指定索引模板的分片信息
setup.template.settings:
  index.number_of_shards: 5
  index.number_of_replicas: 0
```



## 02.Nginx多虚拟主机

```shell
(1)配置nginx的多虚拟主机
[root@elk103.oldboyedu.com /etc/nginx/conf.d]# cat bbs.oldboyedu.com.conf 
server {
	listen 80;
	
	server_name bbs.oldboyedu.com;

	root /oldboy/data/nginx/code/bbs;

	 # 指定access.log的存储路径及日志格式.
        access_log /var/log/nginx/bbs.log oldboyedu_nginx_json;

	location / {
		index index.html;
	}
}
[root@elk103.oldboyedu.com /etc/nginx/conf.d]# 
[root@elk103.oldboyedu.com /etc/nginx/conf.d]# cat blog.oldboyedu.com.conf 
server {
	listen 80;
	
	server_name blog.oldboyedu.com;

	root /oldboy/data/nginx/code/blog;

        # 指定access.log的存储路径及日志格式.
        access_log /var/log/nginx/blog.log oldboyedu_nginx_json;

	location / {
		index index.html;
	}
}
[root@elk103.oldboyedu.com /etc/nginx/conf.d]# 


(2)创建测试数据
[root@elk103.oldboyedu.com /etc/nginx/conf.d]# mkdir -pv /oldboy/data/nginx/code/{blog,bbs}
mkdir: 已创建目录 "/oldboy/data/nginx/code/blog"
mkdir: 已创建目录 "/oldboy/data/nginx/code/bbs"
[root@elk103.oldboyedu.com /etc/nginx/conf.d]# 
[root@elk103.oldboyedu.com /etc/nginx/conf.d]# echo "<h1>blog</h1>" > /oldboy/data/nginx/code/blog/index.html
[root@elk103.oldboyedu.com /etc/nginx/conf.d]# 
[root@elk103.oldboyedu.com /etc/nginx/conf.d]# echo "<h1>bbs</h1>" > /oldboy/data/nginx/code/bbs/index.html


(3)检查配置文件的语法
[root@elk103.oldboyedu.com ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@elk103.oldboyedu.com ~]# 

(4)修改主机名映射
[root@elk103.oldboyedu.com ~]# vim /etc/hosts
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# cat /etc/hosts

...

172.200.3.103 blog.oldboyedu.com
172.200.3.103 bbs.oldboyedu.com
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# 


(5)重启nginx服务
[root@elk103.oldboyedu.com ~]# systemctl reload nginx


(6)测试服务
[root@elk103.oldboyedu.com ~]# curl blog.oldboyedu.com
<h1>blog</h1>
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# curl bbs.oldboyedu.com
<h1>bbs</h1>
[root@elk103.oldboyedu.com ~]# 

(7)编写fielbeat的yaml
[root@elk101.oldboyedu.com ~/conf/project]# vim nginx_vm_host.yaml
[root@elk101.oldboyedu.com ~/conf/project]# 
[root@elk101.oldboyedu.com ~/conf/project]# cat nginx_vm_host.yaml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/nginx/access.log
  # false会将json解析的格式存储至message，改为true则不存储至message
  json.keys_under_root: true
  # 覆盖默认的message字段，使用自定义json格式的key
  json.overwrite_keys: true
  # 为访问日志("access.log")打标签
  tags: ["nginx-access"]

- type: log
  enabled: true
  paths:
    - /var/log/nginx/blog.log
  # false会将json解析的格式存储至message，改为true则不存储至message
  json.keys_under_root: true
  # 覆盖默认的message字段，使用自定义json格式的key
  json.overwrite_keys: true
  # 为访问日志("access.log")打标签
  tags: ["nginx-blog"]


- type: log
  enabled: true
  paths:
    - /var/log/nginx/demo.log
  # false会将json解析的格式存储至message，改为true则不存储至message
  json.keys_under_root: true
  # 覆盖默认的message字段，使用自定义json格式的key
  json.overwrite_keys: true
  # 为访问日志("access.log")打标签
  tags: ["nginx-demo"]

- type: log
  enable: true
  paths:
    - /var/log/nginx/error.log
  # 为错误日志("error.log")打标签
  tags: ["nginx-error"]

output.elasticsearch:
  hosts: ["elk101.oldboyedu.com:9200","elk102.oldboyedu.com:9200","elk103.oldboy
edu.com:9200"]  # index: "nginx-access-%{[agent.version]}-%{+yyyy.MM.dd}"
  # 注意哈，下面的标签不再是"index"啦~
  indices:
    - index: "nginx-access-%{[agent.version]}-%{+yyyy.MM.dd}"
      when.contains:
        tags: "nginx-access"

    - index: "nginx-error-%{[agent.version]}-%{+yyyy.MM.dd}"
      when.contains:
        tags: "nginx-error"

    - index: "nginx-blog-%{[agent.version]}-%{+yyyy.MM.dd}"
      when.contains:
        tags: "nginx-blog"

    - index: "nginx-demo-%{[agent.version]}-%{+yyyy.MM.dd}"
      when.contains:
        tags: "nginx-demo"

setup.ilm.enabled: false
# 定义模板名称.
setup.template.name: "nginx"
# 定义模板的匹配索引名称.
setup.template.pattern: "nginx-*"
[root@elk101.oldboyedu.com ~/conf/project]# 
[root@elk101.oldboyedu.com ~/conf/project]# filebeat -e -c nginx_vm_host.yaml
```





## 03.Tomcat日志收集

```shell
(1)部署tomcat
[root@elk103.oldboyedu.com ~]# tar zxf apache-tomcat-10.0.6.tar.gz -C /oldboy/softwares/
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# cd  /oldboy/softwares/
[root@elk103.oldboyedu.com /oldboy/softwares]#
[root@elk103.oldboyedu.com /oldboy/softwares]# ln -sv apache-tomcat-10.0.6 tomcat
"tomcat" -> "apache-tomcat-10.0.6"
[root@elk103.oldboyedu.com /oldboy/softwares]# 
[root@elk103.oldboyedu.com /oldboy/softwares]# cd
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# vim  /etc/profile.d/tomcat.sh
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# cat /etc/profile.d/tomcat.sh
#!/bin/bash

export TOMCAT_HOME=/oldboy/softwares/tomcat
export PATH=$PATH:$TOMCAT_HOME/bin
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# .  /etc/profile.d/tomcat.sh
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# catalina.sh 

(2)配置tomcat的JSON格式
[root@elk103.oldboyedu.com ~]# vim /oldboy/softwares/tomcat/conf/server.xml 

···(大概在133行哟~)

      <Host name="tomcat.oldboyedu.com"  appBase="webapps"
            unpackWARs="true" autoDeploy="true">

...(需要手动注释一下原内容)
<!--
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="localhost_access_log" suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />
-->



<Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
            prefix="tomcat.oldboyedu.com_access_log" suffix=".txt"
pattern="{&quot;clientip&quot;:&quot;%h&quot;,&quot;ClientUser&quot;:&quot;%l&quot;,&quot;authentica
ted&quot;:&quot;%u&quot;,&quot;AccessTime&quot;:&quot;%t&quot;,&quot;request&quot;:&quot;%r&quot;,&quot;status&quot;:&quot;%s&quot;,&quot;SendBytes&quot;:&quot;%b&quot;,&quot;Query?string&quot;:&quot;%q&quot;,&quot;partner&quot;:&quot;%{Referer}i&quot;,&quot;AgentVersion&quot;:&quot;%{User-Agent}i&quot;}"/>

...


(3)配置主机解析
[root@elk103.oldboyedu.com ~]# vim /etc/hosts

...

172.200.3.103 tomcat.oldboyedu.com
[root@elk103.oldboyedu.com ~]# 

(4)启动tomcat服务
[root@elk103.oldboyedu.com ~]# catalina.sh start

(5)验证服务
	略。
	
(6)使用filebeat收集日志
[root@elk103.oldboyedu.com ~/conf/project/tomcat]# cat 01.tomcat-to-es.yaml 
filebeat.inputs:
- type: log
  paths:
    - /oldboy/softwares/tomcat/logs/tomcat.oldboyedu.com_access_log.*.txt
  # false会将json解析的格式存储至message，改为true则不存储至message
  json.keys_under_root: true
  # 为访问日志("access.log")打标签
  tags: "tomcat-access"

output.elasticsearch:
  hosts: ["elk101.oldboyedu.com:9200","elk102.oldboyedu.com:9200","elk103.oldboyedu.com:9200"]
  # index: "nginx-access-%{[agent.version]}-%{+yyyy.MM.dd}"
  # 注意哈，下面的标签不再是"index"啦~
  indices:
    - index: "tomcat-access-%{[agent.version]}-%{+yyyy.MM.dd}"
      when.contains:
        tags: "tomcat-access"

setup.ilm.enabled: false
# 定义模板名称.
setup.template.name: "tomcat"
# 定义模板的匹配索引名称.
setup.template.pattern: "tomcat-*"
# 指定索引模板的分片信息
setup.template.settings:
  index.number_of_shards: 3
  index.number_of_replicas: 0
[root@elk103.oldboyedu.com ~/conf/project/tomcat]#



(6)收集错误日志
[root@elk103.oldboyedu.com ~/conf/project/tomcat]# cat  03.tomcat-to-es.yaml 
filebeat.inputs:
- type: log
  paths:
    - /oldboy/softwares/tomcat/logs/tomcat.oldboyedu.com_access_log.*.txt
  json.keys_under_root: true
  tags: "tomcat-access"

- type: log
  paths:
    - /oldboy/softwares/tomcat/logs/catalina*
  tags: "tomcat-error"
  multiline.type: pattern
  multiline.pattern: '^\d{2}'
  multiline.negate: true
  multiline.match: after
  multiline.max_lines: 1000

output.elasticsearch:
  hosts: ["elk101.oldboyedu.com:9200","elk102.oldboyedu.com:9200","elk103.oldboyedu.com:9200"]
  indices:
    - index: "tomcat-access-%{[agent.version]}-%{+yyyy.MM.dd}"
      when.contains:
        tags: "tomcat-access"

    - index: "tomcat-error-%{[agent.version]}-%{+yyyy.MM.dd}"
      when.contains:
        tags: "tomcat-error"

setup.ilm.enabled: false
setup.template.name: "tomcat"
setup.template.pattern: "tomcat-*"
setup.template.settings:
  index.number_of_shards: 3
  index.number_of_replicas: 0


```

