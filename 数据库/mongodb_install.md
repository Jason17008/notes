****

****

****

**MongoDB**

**安装部署说明书**

****

[**1引言**](https://www.yuque.com/dongqaq/kmhwkg/epg31bor7o03u12a#_Toc219274036)

[1.1编写目的](https://www.yuque.com/dongqaq/kmhwkg/epg31bor7o03u12a#_Toc219274037)

[1.2背景](https://www.yuque.com/dongqaq/kmhwkg/epg31bor7o03u12a#_Toc219274038)

[1.3定义](https://www.yuque.com/dongqaq/kmhwkg/epg31bor7o03u12a#_Toc219274039)

[1.4参考资料](https://www.yuque.com/dongqaq/kmhwkg/epg31bor7o03u12a#_Toc219274040)

[**2系统配置**](https://www.yuque.com/dongqaq/kmhwkg/epg31bor7o03u12a#_Toc219274041)

[2.1运行环境](https://www.yuque.com/dongqaq/kmhwkg/epg31bor7o03u12a#_Toc219274042)

[2.2系统安装部署图](https://www.yuque.com/dongqaq/kmhwkg/epg31bor7o03u12a#_Toc219274043)

[2.3系统硬件配置](https://www.yuque.com/dongqaq/kmhwkg/epg31bor7o03u12a#_Toc219274044)

[2.4系统应用服务器软件安装与配置](https://www.yuque.com/dongqaq/kmhwkg/epg31bor7o03u12a#_Toc219274045)

[**3程序部署**](https://www.yuque.com/dongqaq/kmhwkg/epg31bor7o03u12a#_Toc219274046)

[3.1应用程序部署](https://www.yuque.com/dongqaq/kmhwkg/epg31bor7o03u12a#_Toc219274047)

[*3.1.1参数配置*](https://www.yuque.com/dongqaq/kmhwkg/epg31bor7o03u12a#_Toc219274048)

[*3.1.2编译*](https://www.yuque.com/dongqaq/kmhwkg/epg31bor7o03u12a#_Toc219274049)

[*3.1.3打包*](https://www.yuque.com/dongqaq/kmhwkg/epg31bor7o03u12a#_Toc219274050)

[3.2服务器参数设置](https://www.yuque.com/dongqaq/kmhwkg/epg31bor7o03u12a#_Toc219274051)

[**4运行和停止**](https://www.yuque.com/dongqaq/kmhwkg/epg31bor7o03u12a#_Toc219274052)

# 1 引言

## 1.1 编写目的

安装MongoDB数据库留档

## 1.2 背景

搭建一套全新的测试环境

## 1.3 定义

无

## 1.4 参考资料

MongoDB 官方文档

# 2 系统配置

## 2.1 **介质装备**

MongoDB介质下载地址（下载4.0+的版本）：

https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-4.0.10.tgz

## 2.2 运行环境

Os:Linux 64位

版本：centos7.0+，RedHat7+（如果操作系统不匹配，请到MongoDB官方下载对应的版本 ，地址：<https://www.mongodb.com/download-center/community>）

最小集群需用到三台设备，以公司环境为例

192.168.1.164  从节点

192.168.1.165 主节点

192.168.1.179 仲裁节点

副本集名称：mongodb_cluster

## 2.3 **网络环境**

需要安装MongoDB的三台设备需开发网络端口 27017（如果是其他端口，根据实际情况开通）

# 3 **操作步骤**

以公司环境将MongoDB安装到 /opt 下为例

将要安装的MongoDB介质包上传到 设备164,165,179 的/opt 目录下

## 3.1 **减压文件和创建目录**

在164,165,179 下执行

cd /opt

tar –xzvf mongodb-linux-x86_64-rhel70-4.0.10.tgz

mv mongodb-linux-x86_64-rhel70-4.0.10 mongodb4

cd mongodb4

mkdir data

mkdir conf

mkdir log

## 3.2 **创建配置文件**

同样在164,165,179三台设备执行以下操作

cd /opt/mongodb4/conf

touch mongodb.conf

将以下内容写入mongodb.conf，以下加粗本部请根据具体按照目录修改，“#”注释部分在创建用户后才能开启，后面有描述

systemLog:

destination: file

path: **"/opt/mongodb4/log/mongod.log"**

logAppend: true

storage:

dbPath: **"/opt/mongodb4/data"**

journal:

enabled: true

processManagement:

fork: true

pidFilePath: **"/opt/mongodb4/mongod.pid"**

net:

bindIp: 0.0.0.0

port: 27017

\#security:

\#  keyFile: **"/opt/mongodb4/conf/access.key"**

\#  authorization: enabled

\#setParameter:

\#  authenticationMechanisms: SCRAM-SHA-1

replication:

oplogSizeMB: 500

replSetName: mongodb_cluster

## 3.3 **启动数据库**

同样在164,165,179 三台设备下执行下面命令

cd /opt/mongodb4/bin

./mongod –f /opt/mongodb4/conf/mongodb.conf

## 3.4 **配置集群**

进入任意一台机器，以179 为例，执行以下操作

cd /opt/mongodb4/bin

./mongo

cfg={ _id:"mongodb_cluster", members:[ {_id:0,host:'192.168.1.165:27017',priority:2}, {_id:1,host:'192.168.1.164:27017',priority:1}, 

{_id:2,host:'192.168.1.179:27017',arbiterOnly:true}] };

rs.initiate(cfg)

rs.isMaster() #查看那台设备是主节点,如果集群创建成功会看到下面内容，主节点为165，由于同步需要一定时间，这里可能需要等待大约20-30秒

rs.status() #查看集群状态

## 3.5 **创建用户**

由于主节点是165，这里需要切换到165服务器上，执行以下操作

cd /opt/mongodb4/bin

./mongo

use admin

\#创建数据库管理员

db.createUser({

user:"root",

pwd:"root",

roles:[{role:"readWriteAnyDatabase",db:"admin"},{role:"dbAdminAnyDatabase",db:"admin"},{role:"userAdminAnyDatabase",db:"admin"}]

});

\#创建集群管理员

db.createUser({

user:"suroot",

pwd:"suroot",

roles:[{role:"clusterAdmin",db:"admin"},{role:"clusterManager",db:"admin"},{role:"clusterMonitor",db:"admin"}]

});

\#创建cmdb用户

use cmdb;

db.createUser({user: "cmdb", pwd: "cmdb", roles: [{role:"readWrite",db:"cmdb"},{role:"dbAdmin",db:"cmdb"},{role:"userAdmin",db:"cmdb"}]});

\#查看创建的用户是否成功

use admin;

db.system.users.find(); #如果在从节点上查看，需要登录控制台后执行rs.slaveOk()命令

## 3.6 **开启用户认证**

**用户添加完成后需要关闭所有节点****(****先关闭仲裁和从节点****, ****再关闭主节点****, ****避免主节点切换****)**

按照关闭数据库先后步骤，登录到对应机器的MongoDB控制台执行以下命令

cd /opt/mongodb4/bin

./mongo

use admin

db.shutdownServer();

生成keyFile,keyFile的用途是作为所有mongod后台进程允许加入集群的凭证, 所有集群中的节点共用一个keyFile

在任意一个节点，以164为例，执行以下命令

openssl rand -base64 756 > /opt/mongodb4/conf/access.key

chmod 400 /opt/mongodb4/conf/access.key

scp /opt/mongodb4/conf/access.key [root@192.168.1.165:/opt/mongodb4/conf](mailto:root@192.168.1.165:/opt/mongodb4/conf)

scp /opt/mongodb4/conf/access.key [root@192.168.1.179:/opt/mongodb4/conf](mailto:root@192.168.1.179:/opt/mongodb4/conf)

取消三个节点/opt/mongodb4/conf/mongodb.conf 下security的注释

systemLog:

destination: file

path: "/opt/mongodb4/log/mongod.log"

logAppend: true

storage:

dbPath: "/opt/mongodb4/data"

journal:

enabled: true

processManagement:

fork: true

pidFilePath: "/opt/mongodb4/mongod.pid"

net:

bindIp: 0.0.0.0

port: 27017

**security:**

**keyFile: "/opt/mongodb4/conf/access.key"**

**authorization: enabled**

**setParameter:**

**authenticationMechanisms: SCRAM-SHA-1**

replication:

oplogSizeMB: 500

replSetName: mongodb_cluster

## 3.7 **重新启动数据库**

依次启动主节点, 从节点和仲裁节点

cd /opt/mongodb4/bin

./mongod –f /opt/mongodb4/conf/mongodb.conf

## 3.8 **使用认证用户登录**

选择主节点或者从节点（如果通过从节点查询数据登录MongoDB的控制台后必须先执行rs.slaveOK()）

以从节点164位例

综上，MongoDB副本集搭建完毕。

# mongo 使用

mongo 登录 

mongodb查询

mongo

use script 

db.auth("用户"，“密码”)

show collections  查看集合 

db.<collection_name>.find().pretty()

1. **启动Mongo Shell**：

打开终端窗口，输入mongo命令启动Mongo Shell。如果你已经设置了MongoDB的认证模式，需要提供用户名、密码和认证数据库进行连接。

1. **列出所有数据库**：

在Mongo Shell中，输入show dbs命令来列出当前MongoDB中所有的数据库。

1. **选择数据库**：

使用use <database_name>命令选择你要查询的数据库。

1. **列出集合（表）**：

在选定的数据库中，输入show collections命令来列出所有集合。

1. **查询集合中的数据**：

使用db.<collection_name>.find().pretty()命令来查询集合中的所有数据，并以易读的格式显示。例如，如果你的集合名为users，可以输入db.users.find().pretty()来查询数据。