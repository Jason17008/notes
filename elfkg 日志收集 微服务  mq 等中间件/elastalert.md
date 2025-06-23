### ElastAlert 工作原理

周期性的查询Elastsearch并且将数据传递给规则类型，规则类型定义了需要查询哪些数据。

当一个规则匹配触发，就会给到一个或者多个的告警，这些告警具体会根据规则的配置来选择告警途径，就是告警行为，比如邮件、企业微信等

### ElastAlert 安装配置

#### 1.Python3以及相关依赖安装

`yum -y install wget openssl openssl-devel gcc gcc-c++`

`wget https://www.python.org/ftp/python/3.6.9/Python-3.6.9.tgz`

`tar xf Python-3.6.9.tgz`

`cd Python-3.6.9 && ./configure --prefix=/usr/local/python --with-openssl`

`make && make install`

`mv /usr/bin/python /usr/bin/python_old`

`ln -s /usr/local/python/bin/python3 /usr/bin/python`

`ln -s /usr/local/python/bin/pip3 /usr/bin/pip`

`pip3 install --upgrade pip`

`sed -i '1s/python/python2.7/g' /usr/bin/yum`

`sed -i '1s/python/python2.7/g' /usr/libexec/urlgrabber-ext-down`

#### ``

#### 2.elastalert相关安装

pip3 install elastalert

或者，您可以克隆ElastAlert存储库以获取最新更改：

git clone <https://github.com/Yelp/elastalert.git>

安装模块：

pip3 install "setuptools>=11.3"

python3 setup.py install

#### 3.配置使用：

##### `修改相关配置`

##### `cp config.yaml.example config.yaml`

`*es_host: xxx.xx.xxx.xx*`

`*es_port: 9200*`

`*es_username: elastic*`
`*es_password: xxxxxxx*`

##### 配置rules规则

`mkdir rules`

新增配置文件xxx.yaml

*可参考*

```
[example_rules]# tree
├── example_cardinality.yaml
├── example_change.yaml
├── example_frequency.yaml
├── example_new_term.yaml
├── example_opsgenie_frequency.yaml
├── example_percentage_match.yaml
├── example_single_metric_agg.yaml
├── example_spike.yaml
└── jira_acct.txt
```

elastalert-create-index 【创建初始化索引】

### 告警规则配置

#### 1.ElastAlert包含几种具有通用监视范例的规则类型：

- 匹配Y时间中至少有X个事件的地方”（`frequency`类型）
- 当事件发生率增加或减少时匹配”（`spike`类型
- 在Y时间内少于X个事件时进行匹配”（`flatline`类型）
- 当某个字段与黑名单/白名单匹配时匹配”（`blacklist`并`whitelist`输入）
- 匹配任何与给定过滤器匹配的事件”（`any`类型）
- 当字段在一段时间内具有两个不同的值时进行匹配”（`change`类型）
- 当字段中出现从未见过的术语时进行匹配”（`new_term`类型）
- 当字段的唯一值数量大于或小于阈值（`cardinality`类型）时匹配

#### 2.常用规则配置

【邮件告警】

**cat rules/asterix_nginxstatus_email.yaml**

es_host: 10.48.5.244
es_port: 9200
name: nginx状态值告警email

【企业微信消息通知】

**cat rules/asterix_nginxstatus_wechat.yaml**

es_host: 10.48.5.244
es_port: 9200
name: nginx状态值告警wechat

**mkdir /elastalert/elastalert_modules**

**cat /elastalert/elastalert_modules/wechat_qiye_alert.py**

**可参考**<https://github.com/anjia0532/elastalert-wechat-plugin>

```
#! /usr/bin/env python
# -*- coding: utf-8 -*-
import json
import datetime
from elastalert.alerts import Alerter, BasicMatchString
from requests.exceptions import RequestException
from elastalert.util import elastalert_logger,EAException #[感谢minminmsn分享](https://github.com/anjia0532/elastalert-wechat-plugin/issues/2#issuecomment-311014492)
import requests

'''
#################################################################
# 微信企业号推送消息                                              #
'''
class WeChatAlerter(Alerter):

#企业号id，secret，应用id必填

required_options = frozenset(['wechat_corp_id','wechat_secret','wechat_agent_id'])

def __init__(self, *args):
super(WeChatAlerter, self).__init__(*args)
self.corp_id = self.rule.get('wechat_corp_id', '')     #企业号id
self.secret = self.rule.get('wechat_secret', '')       #secret
self.agent_id = self.rule.get('wechat_agent_id', '')   #应用id

self.party_id = self.rule.get('wechat_party_id')       #部门id
self.user_id = self.rule.get('wechat_user_id', '')     #用户id，多人用 | 分割，全部用 @all
self.tag_id = self.rule.get('wechat_tag_id', '')       #标签id
self.access_token = ''                                 #微信身份令牌
self.expires_in=datetime.datetime.now() - datetime.timedelta(seconds=60)

def create_default_title(self, matches):
subject = 'ElastAlert: %s' % (self.rule['name'])
return subject

def alert(self, matches):

if not self.party_id and not self.user_id and not self.tag_id:
elastalert_logger.warn("All touser & toparty & totag invalid")

# 参考elastalert的写法
# https://github.com/Yelp/elastalert/blob/master/elastalert/alerts.py#L236-L243
body = self.create_alert_body(matches)

#matches 是json格式
#self.create_alert_body(matches)是String格式,详见 [create_alert_body 函数](https://github.com/Yelp/elastalert/blob/master/elastalert/alerts.py)

# 微信企业号获取Token文档
# http://qydev.weixin.qq.com/wiki/index.php?title=AccessToken
self.get_token()

self.senddata(body)

elastalert_logger.info("send message to %s" % (self.corp_id))

def get_token(self):

#获取token是有次数限制的,本想本地缓存过期时间和token，但是elastalert每次调用都是一次性的，不能全局缓存
if self.expires_in >= datetime.datetime.now() and self.access_token:
return self.access_token

#构建获取token的url
get_token_url = 'https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=%s&corpsecret=%s' %(self.corp_id,self.secret)

try:
response = requests.get(get_token_url)
response.raise_for_status()
except RequestException as e:
raise EAException("get access_token failed , stacktrace:%s" % e)
#sys.exit("get access_token failed, system exit")

token_json = response.json()

if 'access_token' not in token_json :
raise EAException("get access_token failed , , the response is :%s" % response.text())
#sys.exit("get access_token failed, system exit")

#获取access_token和expires_in
self.access_token = token_json['access_token']
self.expires_in = datetime.datetime.now() + datetime.timedelta(seconds=token_json['expires_in'])

return self.access_token

def senddata(self, content):

#如果需要原始json，需要传入matches

# http://qydev.weixin.qq.com/wiki/index.php?title=%E6%B6%88%E6%81%AF%E7%B1%BB%E5%9E%8B%E5%8F%8A%E6%95%B0%E6%8D%AE%E6%A0%BC%E5%BC%8F
# 微信企业号有字符长度限制（2048），超长自动截断

# 参考 http://blog.csdn.net/handsomekang/article/details/9397025
#len utf8 3字节，gbk2 字节，ascii 1字节
if len(content) > 2048:
content = content[:2045] + "..."

# 微信发送消息文档
# http://qydev.weixin.qq.com/wiki/index.php?title=%E6%B6%88%E6%81%AF%E7%B1%BB%E5%9E%8B%E5%8F%8A%E6%95%B0%E6%8D%AE%E6%A0%BC%E5%BC%8F
send_url = 'https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=%s' %( self.access_token)

headers = {'content-type': 'application/json'}

#最新微信企业号调整校验规则，tagid必须是string类型，如果是数字类型会报错，故而使用str()函数进行转换
payload = {
            "touser": self.user_id and str(self.user_id) or '', #用户账户，建议使用tag
            "toparty": self.party_id and str(self.party_id) or '', #部门id，建议使用tag
            "totag": self.tag_id and str(self.tag_id) or '', #tag可以很灵活的控制发送群体细粒度。比较理想的推送应该是，在heartbeat或者其他elastic工具自定义字段，添加标签id。这边根据自定义的标签id，进行推送
            'msgtype': "text",
            "agentid": self.agent_id,
            "text":{
                "content": content
},
            "safe":"0"
}

# set https proxy, if it was provided
# 如果需要设置代理，可修改此参数并传入requests
# proxies = {'https': self.pagerduty_proxy} if self.pagerduty_proxy else None
try:
response = requests.post(send_url, data=json.dumps(payload), headers=headers)
response.raise_for_status()
except RequestException as e:
raise EAException("send message has error: %s" % e)

elastalert_logger.info("send msg and response: %s" % response.text)


def get_info(self):
return {'type': 'WeChatAlerter'}
```