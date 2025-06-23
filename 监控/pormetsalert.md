**官网地址：**[**https://github.com/feiyu563/PrometheusAlert/tree/master**

### 11.1、promethesualert的介绍

`Prometheus Alert` 是开源的运维告警中心消息转发系统，支持主流的监控系统 `Prometheus`，日志系统 `Graylog` 和数据可视化系统 `Grafana` 发出的预警消息。通知渠道支持钉钉、微信、华为云短信、腾讯云短信、腾讯云电话、阿里云短信、阿里云电话等。

### 11.2、PrometheusAlert 特性

- 支持多种消息来源，目前主要有prometheus、graylog2、graylog3、grafana
- **支持多种类型的发送目标，支持钉钉、微信、腾讯短信、腾讯语音、华为短信**
- 针对Prometheus增加了告警级别，并且支持按照不同级别发送消息到不同目标对象
- 简化Prometheus分组配置，支持按照具体消息发送到单个或多个接收方
- 增加手机号码配置项，和号码自动轮询配置，可固定发送给单一个人告警信息，也可以通过自动轮询的方式发送到多个人员且支持按照不同日期发送到不同人员
- 增加 Dashboard，暂时支持测试配置是否正确

### 11.3、PrometheusAlert的优势

- **上述告警方法是邮件告警，通过以上实验我们可以看到，邮件告警并不能保证告警消息的时效性；想要保证时效性，那就必须要接入实时通讯工具，例如：企业微信、钉钉、飞书等；**
- **然而，使用prometheus监控想要将告警信息发送到这些位置，通常都需要结合python脚本来实现，shell脚本也可以，但是没有python那么的稳定；所以写python脚本的同时也考验了运维人员的python脚本能力，对python不熟悉的运维，这下就难倒了**
- **prometheusalert组件的开源，解决了运维人员肝代码的问题，它提供了现成的对接企业微信、钉钉、飞书、腾讯云短信/语音等一系列的接口，我们只需要修改它的app.conf配置文件自定义修改url即可**

### 11.4、常见的使用场景

```
示例场景：
使用场景（Prometheus+alertmanager+prometheusAlert）
示例应用范围：企业微信群机器人消息推送，钉钉群机器人消息推送
示例消息发送模式： Promtheus规则被触发，prometheus将告警信息发送给alertmanager，alertmanager
通过发送邮箱将详细发送给收件人，并调用prometheusalert的接口，prometheusalert接口收到
alertmanager请求之后根据模板发送消息至对应的webhook地址。
```

**流程图如下：**

### 11.5、安装部署

#### 11.5.1、本地部署

**1、下载插件**

```
#打开PrometheusAlert releases页面，根据需要选择需要的版本下载到本地解压并进入解压后的目录
如linux版本(https://github.com/feiyu563/PrometheusAlert/releases/download/v4.9/linux.zip)

# wget https://github.com/feiyu563/PrometheusAlert/releases/download/v4.9/linux.zip && unzip linux.zip && cd linux/

#运行PrometheusAlert
chmox a+x /PrometheusAlert
#前台运行alert
./PrometheusAlert (#后台运行请执行 nohup ./PrometheusAlert &)

#启动后可使用浏览器打开以下地址查看：http://自己的IP:8080
#默认登录帐号和密码在app.conf中有配置
```

**2、登录prometheusalert（账号密码可以在conf/app.conf配置文件中查看）**

### 11.6、配置prometheus对接企业微信群机器人

- **首先得先准备一个企业微信群机器人才能行，具体配置过程略**
- **修改app.conf配置文件，将机器人的地址填入到配置文件中**

```
[root@prometheus-server conf]# pwd
/root/linux/conf
[root@prometheus-server conf]# ls
app.conf
[root@prometheus-server conf]# vim app.conf
#找到73行的企业微信的配置
73 #默认企业微信机器人地址
74 wxurl=https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxxxxxx
#wxurl后面跟的是自己机器人的地址
```

- **修改了配置文件一定要重启程序**

```
[root@prometheus-server conf]# ps -ef|grep  PrometheusAlert|grep -v grep
root       1772      1  0 11:46 pts/0    00:00:00 ./PrometheusAlert
[root@prometheus-server conf]# kill -9 1772
[root@prometheus-server conf]# nohup  ../PrometheusAlert &
[root@prometheus-server conf]# netstat -ntlp|grep -i "prometheus"
tcp6       0      0 :::8080                 :::*                    LISTEN      1849/./PrometheusAl
```

### 11.7、测试企业微信告警功能

- **去到prometheusalert的web界面中，点击【告警管理】——>【告警测试】按钮进行测试**
- **再去到企业微信群看看是否有告警测试的消息**
- **有看到告警消息就说明prometheus——>企业微信群这一步链路打通了，可以接着往下配置对接alertmanager了**

### 11.8、配置Alertmanger使用prometheusalert发送告警

**官网配置参考链接：**[**https://github.com/feiyu563/PrometheusAlert/blob/master/doc/readme/conf-wechat.md**](https://github.com/feiyu563/PrometheusAlert/blob/master/doc/readme/conf-wechat.md)

- **官网参考示例**

```
global:
  resolve_timeout: 5m
route:
  group_by: ['instance']
  group_wait: 10m
  group_interval: 10s
  repeat_interval: 10m
  receiver: 'web.hook.prometheusalert'
receivers:
- name: 'web.hook.prometheusalert'
  webhook_configs:
  - url: 'http://[prometheusalert_url]:8080/prometheusalert?type=wx&tpl=prometheus-wx&wxurl=微信机器人地址,微信机器人地址2&at=zhangsan,lisi'
```

- **自定义配置**

```
[root@prometheus-server alertmanager]# pwd
/usr/local/alertmanager
[root@prometheus-server alertmanager]# vim alertmanager.yml
#主要修改以下内容
route:
  group_by: ['alertname']
  group_wait: 10s   #等待时间默认为30s，修改为10s
  group_interval: 5m
  repeat_interval: 10m
  receiver: 'prometheusalert'


receivers:
  - name: 'prometheusalert'
    webhook_configs:
      - url: 'http://192.168.17.128:8080/prometheusalert?type=wx&tpl=prometheus-wx&wxurl=https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxx-xxx-xxx&at=xxx'

#修改配置时需要注意：
#http://192.168.17.128:8080这一段改成自己机器的ip地址和端口
#url中，只需要修改key=xxxx，改成自己的机器人地址，at是艾特@人员的意思，可以写具体的人员
#其他的保持默认即可！

#修改完使用tool工具检查语法是否有误
[root@prometheus-server alertmanager]# ./amtool    check-config   alertmanager.yml
Checking 'alertmanager.yml'  SUCCESS
Found:
 - global config
 - route
 - 1 inhibit rules
 - 1 receivers
 - 0 templates
```

- **重启alertmanager**

```
[root@prometheus-server alertmanager]# systemctl restart alertmanager

#查看端口是否正常
[root@prometheus-server alertmanager]# netstat -ntlp|grep alert
tcp6       0      0 :::9093                 :::*                    LISTEN      3265/alertmanager
tcp6       0      0 :::9094                 :::*                    LISTEN      3265/alertmanager
```

### 11.9、停止node_exporter，观察告警情况

- **将128或129上的node_exporter停止，观察告警情况**

```
[root@localhost ~]# hostname -I
192.168.17.129

[root@localhost ~]# systemctl stop node_exporter.service
```

- **观察128上的promheus/alertmanager的web页面**
- **将129的node_exporter重新启动后，会收到服务恢复的通知**

[root@localhost ~]# systemctl restart node_exporter.service

### 11.10、拓展（修改企业微信告警模板&&增加prometheusalert启停脚本）

#### 11.10.1、自定义企业微信告警模板

- **这里的自定义内容主要体现在告警时间方面，默认的告警模板时间是格林尼治标准时间，跟北京时间差了8小时，影响运维人员对告警信息的评判**
- **话不多说，直接上图看看没有修改过模板的告警信息**
- **可以看到时间完全不匹配**
- **下面对模板进行修改**

```
//模板内容如下：

{{ $var := .externalURL}}{{ range $k,$v:=.alerts }}
{{if eq $v.status "resolved"}}
#### [Prometheus恢复信息]({{$v.generatorURL}})
> <font color="info">告警名称</font>：[{{$v.labels.alertname}}]({{$var}})
> <font color="info">告警级别</font>：{{$v.labels.severity}}
> <font color="info">开始时间</font>：{{GetCSTtime $v.startsAt}}
> <font color="info">结束时间</font>：{{GetCSTtime $v.endsAt}}
> <font color="info">故障主机</font>：{{$v.labels.instance}}
> <font color="info">恢复描述</font>：{{$v.annotations.resolved}}
{{else}}
#### [Prometheus告警信息]({{$v.generatorURL}})
> <font color="#FF0000">告警名称</font>：[{{$v.labels.alertname}}]({{$var}})
> <font color="#FF0000">告警级别</font>：{{$v.labels.severity}}
> <font color="#FF0000">开始时间</font>：{{GetCSTtime $v.startsAt}}
> <font color="#FF0000">故障主机</font>：{{$v.labels.instance}}
> <font color="#FF0000">告警描述</font>：{{$v.annotations.description}}
{{end}}
{{ end }}
```

- **修改过后的告警消息**

#### 11.10.2、新增prometheusalert启停脚本

```
[root@prometheus-server linux]# vim  alert.sh

#!/bin/bash
export PROMETHEUS_ALERT_HOME="/root/linux/"
alert_pid=` ps -ef|grep Prom|grep -v grep|awk '{print $2}'`
case "$1" in
start)
       nohup $PROMETHEUS_ALERT_HOME/PrometheusAlert &
        ;;
stop)
        kill $alert_pid &> /dev/null
        ;;
restart)
        kill $alert_pid &> /dev/null
        sleep 5
        nohup $PROMETHEUS_ALERT_HOME/PrometheusAlert &
        ;;
esac

[root@prometheus-server linux]# bash  alert.sh  start
```