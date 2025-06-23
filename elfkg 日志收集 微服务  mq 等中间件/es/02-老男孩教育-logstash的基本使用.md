[TOC]



# 一.logstash filter插件概述

```
	数据从源传输到存储的过程中，logstash的filter过滤器能够解析各种事件，识别已命名的字段结构，并将它们转换成通用格式，以便轻松，更快速地分析和实现商业价值。
	
	常用的插件如下所示:
		(1)利用grok从非结构化数据中派生出结构;
		(2)利用geoip从IP地址分析出地理坐标;
		(3)利用useragent从请求中分析操作系统，设备类型;
	
	推荐阅读:
		https://www.elastic.co/guide/en/logstash/7.15/filter-plugins.html
		
```





# 二.Grok插件的基本使用

## 1.什么是grok插件

```
	我们想要将非结构化转换成结构化数据，可以使用正则表达式来匹配对应的数据，但这样做将会使用非常复杂的正则表达式，换句话说，这样做实在是反人性的，可读性极差。

	grok其实是带有名字的正则表达式集合，grok内置了很多pattern可以直接使用。

    grok调试器:
        https://grokdebug.herokuapp.com/

	查看grok支持的pattern:
		https://grokdebug.herokuapp.com/patterns#

```



## 2.grok案例-将nginx日志非结构化转换为结构化案例

```
(1)编写配置文件
cat > oldboyedu_linux77/filter/01-http-grok-console.conf <<EOF
input {
  http {
    port => 9999
  }
}

filter {
  grok {
    patterns_dir => ["/oldboyedu/softwares/logstash/oldboyedu_linux77/filter/patterns"]
    match => {
      "message" => "%{COMBINEDAPACHELOG}"
      #"message" => "%{OLDBOYEDU_001:OLDBOYEDU-LOGSTASH00001_kafka} --- oldboyedu2021 --- %{POSTFIX_QUEUEID:queue_id_oldboyedu} --- oldboyedu linux77" 
    }
  }
}


output {
   stdout { 
      codec => rubydebug
      # codec => json 
   }
}
EOF
logstash -rf oldboyedu_linux77/filter/01-http-grok-console.conf


(2)发送测试数据
curl -X POST http://10.0.0.108:9999
127.0.0.1 - - [14/Oct/2021:21:09:21 +0800] "GET / HTTP/1.1" 200 4833 "-" "curl/7.29.0" "-"
```



## 3.grok案例-自定义匹配模式

```
(1)编写规则(文件名叫啥无所谓)
cat > /oldboyedu/softwares/logstash/oldboyedu_linux77/filter/patterns/oldboyedu-logstash << EOF
POSTFIX_QUEUEID [0-9A-F]{10,11}
OLDBOYEDU_001 [\d]{4}
EOF

(2)编写配置文件
cat > oldboyedu_linux77/filter/01-http-grok-console.conf <<EOF
input {
  http {
    port => 9999
  }
}

filter {
  grok {
    patterns_dir => ["/oldboyedu/softwares/logstash/oldboyedu_linux77/filter/patterns"]
    match => {
      "message" => "%{OLDBOYEDU_001:OLDBOYEDU-LOGSTASH00001_kafka} --- oldboyedu2021 --- %{POSTFIX_QUEUEID:queue_id_oldboyedu} --- oldboyedu linux77" 
    }
  }
}


output {
   stdout { 
      codec => rubydebug
      # codec => json 
   }
}
EOF
logstash -rf oldboyedu_linux77/filter/01-http-grok-console.conf

(3)发送测试数据(测试数据和我们上面的匹配规则要对应上哟~)
curl -X POST http://10.0.0.108:9999
6666 --- oldboyedu2021 --- BEF25A72965 --- oldboyedu linux77


```

![1634220558170](02-老男孩教育-logstash的基本使用.assets/1634220558170.png)



# 三.geoip插件的基本使用

## 1.什么是geoip插件

```
	根据IP地址提供的对应地域信息，比如国家名称，省份名称，城市名，经纬度等，方便进行地理数据分析。
```



## 2.geoip案例(通过geoip提取nginx日志中client字段，并获取地域信息)

```
如下所示，由于我们上面启动logstash的配置文件时使用"-r"参数因此我们只需修改配置文件即可。
[root@elk101.oldboyedu.com ~/logstash/filter]# 
[root@elk101.oldboyedu.com ~/logstash/filter]# vim grok_demo.conf 
[root@elk101.oldboyedu.com ~/logstash/filter]# 
[root@elk101.oldboyedu.com ~/logstash/filter]# cat grok_demo.conf 
input {
  http {
    port => 8888
  }
}

filter {
  # 将数据转换成半结构化数据
  grok {
    match => {
      "message" => "%{COMBINEDAPACHELOG}"
    }
  }

  # 对clientip字段进行IP地址的解析
  geoip {
    source => "clientip"
  }
 
}

output {
  stdout {
    codec => rubydebug
  }
}
[root@elk101.oldboyedu.com ~/logstash/filter]# 

```

![image-20210604112932277](02-老男孩教育-logstash的基本使用.assets/image-20210604112932277.png)



## 3.显示指定的字段

```
[root@elk101.oldboyedu.com ~/logstash/filter]# vim grok_demo.conf 
[root@elk101.oldboyedu.com ~/logstash/filter]# 
[root@elk101.oldboyedu.com ~/logstash/filter]# cat grok_demo.conf 
input {
  http {
    port => 8888
  }
}

filter {
  # 将数据转换成半结构化数据
  grok {
    match => {
      "message" => "%{COMBINEDAPACHELOG}"
    }
  }

  # 对clientip字段进行IP地址的解析
  geoip {
    # 指定基于哪个字段来进行IP地址的地域解析
    source => "clientip"
    # 只显示指定的字段，即提取需要获取的指标
    fields => ["country_name","country_code2","timezone","longitude","latitude"]
  }
 
}

output {
  stdout {
    codec => rubydebug
  }
}
[root@elk101.oldboyedu.com ~/logstash/filter]# 

```

![image-20210604114123374](02-老男孩教育-logstash的基本使用.assets/image-20210604114123374.png)



# 四.date插件的基本使用

## 1.什么是date插件

```
	将日期字符串解析为日志类型。然后替换"@timestamp"字段或指定的其它字段l。
	
	match类型为数组，用于指定日期匹配的格式，可以以此指定多种日期格式。
	
	target类型为字符串，用于指定赋值的字段名，默认是@timestamp。
	
	timezone类型为字符串，用于指定时区域。

	温馨提示:
		如下图所示，数据的写入文件的时间(@timestamp)和日志的实际访问时间(timestamp)截然不同。我们需要使用后者覆盖前者，这就得用到date插件。
```

![image-20210604132925770](02-老男孩教育-logstash的基本使用.assets/image-20210604132925770.png)



## 2.date案例

```
[root@elk101.oldboyedu.com ~/logstash/filter]# vim grok_demo.conf 
[root@elk101.oldboyedu.com ~/logstash/filter]# 
[root@elk101.oldboyedu.com ~/logstash/filter]# 
[root@elk101.oldboyedu.com ~/logstash/filter]# cat grok_demo.conf 
input {
  http {
    port => 8888
  }
}

filter {
  # 将数据转换成半结构化数据
  grok {
    match => {
      "message" => "%{COMBINEDAPACHELOG}"
    }
  }

  # 对clientip字段进行IP地址的解析
  geoip {
    # 指定基于哪个字段来进行IP地址的地域解析
    source => "clientip"
    # 只显示指定的字段，即提取需要获取的指标
    fields => ["country_name","country_code2","timezone","longitude","latitude"]
  }

  # 
  date {
    # 关于日期格式转换请参考官网，请对比"@timestamp" => 2021-06-04T03:39:08.187Z，注意下面匹配的时候Z前面有个空格哟~
    match => ["timestamp","dd/MMM/yyyy:HH:mm:ss Z"]
    # 指定转换后的时间名称，此处指定为"@timestamp"，表示要替换的写入数据的时间。
    target => "@timestamp"
    # 指定时区
    timezone => "Asia/Shanghai"

  }
 
}

output {
  stdout {
    codec => rubydebug
  }
}
[root@elk101.oldboyedu.com ~/logstash/filter]# 
[root@elk101.oldboyedu.com ~/logstash/filter]# 


推荐阅读:
	https://www.elastic.co/guide/en/logstash/7.12/plugins-filters-date.html
	
```



# 五.logstash的useragent插件的基本使用

## 1.useragent插件概述

```
	根据请求中的user-agent字段，解析出浏览器设备，操作系统等信息。
```



## 2.useragent案例

```
[root@elk101.oldboyedu.com ~/logstash/filter]# vim grok_demo.conf 
[root@elk101.oldboyedu.com ~/logstash/filter]# 
[root@elk101.oldboyedu.com ~/logstash/filter]# 
[root@elk101.oldboyedu.com ~/logstash/filter]# cat grok_demo.conf 
input {
  http {
    port => 8888
  }
}

filter {
  # 将数据转换成半结构化数据
  grok {
    match => {
      "message" => "%{COMBINEDAPACHELOG}"
    }
  }

  # 对clientip字段进行IP地址的解析
  geoip {
    # 指定基于哪个字段来进行IP地址的地域解析
    source => "clientip"
    # 只显示指定的字段，即提取需要获取的指标
    fields => ["country_name","country_code2","timezone","longitude","latitude"]
  }

  # 日期格式转换
  date {
    # 关于日期格式转换请参考官网，请对比"@timestamp" => 2021-06-04T03:39:08.187Z
    match => ["timestamp","dd/MMM/yyyy:HH:mm:ss Z"]
    # 指定转换后的时间名称，此处指定为"@timestamp"，表示要替换的写入数据的时间。
    target => "@timestamp"
    # 指定时区
    timezone => "Asia/Shanghai"

  }
 
  # 转换客户端插件信息
  useragent {
    # 指定从哪个字段获取数据解析
    source => "agent"
    # 转换后的新字段
    target => "useragent"
  }

}

output {
  stdout {
    codec => rubydebug
  }
}
[root@elk101.oldboyedu.com ~/logstash/filter]# 

```

![image-20210604140220557](02-老男孩教育-logstash的基本使用.assets/image-20210604140220557.png)





# 六.mutate插件

## 1.生成测试日志

```
略。
```



## 2.

```
[root@elk101.oldboyedu.com ~/logstash/filter]# cat file-to-es.conf 
input {
  file {
    path => "/oldboy/logs/apps.log"
    start_position => "beginning"
  }
}


filter {
  mutate {
    split => {
      # 按照"|"切割message字段
      "message" => "|"
    }
  }
}

output {
  elasticsearch {
    hosts => ["elk101.oldboyedu.com:9200","elk102.oldboyedu.com:9200","elk103.oldboyedu.com:9200"]
  }
}
[root@elk101.oldboyedu.com ~/logstash/filter]# 

```

