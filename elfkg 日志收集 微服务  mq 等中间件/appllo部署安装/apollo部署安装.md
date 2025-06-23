apollo部署安装

## 一.部署安装

### （一）常用安装方式

1.Quick Start 快速安装包启动，https://github.com/ctripcorp/apollo/wiki/Quick-Start
2.Apollo Quick Start Docker部署
3.Apollo 分布式部署 

[https://github.com/ctripcorp/apollo/wiki/Apollo-Quick-Start-Docker%E9%83%A8%E7%BD%B2](https://github.com/ctripcorp/apollo/wiki/Apollo-Quick-Start-Docker部署)

[https://github.com/ctripcorp/apollo/wiki/%E5%88%86%E5%B8%83%E5%BC%8F%E9%83%A8%E7%BD%B2%E6%8C%87%E5%8D%97](https://github.com/ctripcorp/apollo/wiki/分布式部署指南)
（由于需要对其进行二次开发配置和集群部署，所以选择分布式部署模式。并保留dockerfile配置）

### （二）安装参考文档

目前采用apollo的 Kubernetes部署方式

详情可参考：git@172.16.15.59:k8s/jdocloud-configservice.git

#### （一）服务地址

##### 1.portal服务：https://cfg-manager.aijidou.com/

##### 2. configservice端地址：

##### dev.meta=[https://cfg-dev.aijidou.com](https://cfg-dev.aijidou.com/) test.meta=[https://cfg-test.aijidou.com](https://cfg-test.aijidou.com/) approval.meta=[https://cfg-approval.aijidou.com](https://cfg-approval.aijidou.com/) live.meta=[https://cfg-live.aijidou.com](https://cfg-live.aijidou.com/)

#### 3.apollo.portal.meta.servers

"DEV":"[https://cfg-dev.aijidou.com](https://cfg-dev.aijidou.com/)",

"TEST":"[https://cfg-test.aijidou.com](https://cfg-test.aijidou.com/)",

"APPROVAL":"[https://cfg-approval.aijidou.com](https://cfg-approval.aijidou.com/)",

"LIVE":"[https://cfg-live.aijidou.com](https://cfg-live.aijidou.com/)" 