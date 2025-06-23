<https://github.com/tech-shrimp/docker_image_pusher>

作者github地址 

笔记从博哥爱运维转载    命名作者出处 

登录阿里云容器镜像服务
<https://cr.console.aliyun.com/>
启用个人实例，创建一个命名空间（**ALIYUN_NAME_SPACE**） [![img](https://github.com/bogeit/docker_image_pusher/raw/main/doc/%E5%91%BD%E5%90%8D%E7%A9%BA%E9%97%B4.png)](https://github.com/bogeit/docker_image_pusher/blob/main/doc/%E5%91%BD%E5%90%8D%E7%A9%BA%E9%97%B4.png)

```
admin_dong
```

访问凭证–>获取环境变量
用户名（**ALIYUN_REGISTRY_USER**)   

```
admin_zed
```

密码（**ALIYUN_REGISTRY_PASSWORD**)

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1718250857617-1be4c19f-53c6-4827-8acb-2a526a721d9f.png)
仓库地址（**ALIYUN_REGISTRY**） 

```
registry.cn-shanghai.aliyuncs.com
```

这是4个变量要在github里面设置下变量  

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1718250989712-2efc6f75-2f06-4a2d-880d-12e7b714390f.png)

设置好如下  

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1718256977979-377b4464-5bd4-440e-a247-b5f630ef001f.png)