参考资料

- [GitLab最新版下载安装_GitLab中文免费版-极狐GitLab中文官方网站](https://gitlab.cn/install)
- [技术文章 | 更顺畅的极狐GitLab安装升级体验来了，赶快尝鲜吧！](https://mp.weixin.qq.com/s/-quEZ4ua_In5sQbgRmiCDA)

# 1.环境资源

| **用户规模**  | 0~500                                    | 500~1000               |
| --------- | ---------------------------------------- | ---------------------- |
| **操作系统**  | Ubuntu 18.04/20.04 ; CentOS 7/8 ; Debian 9/10/11 ; AlmaLinux 8 / RHEL |                        |
| **节点数量**  | GitLab-Server * 1 ; GitLab-Runner * N (N>=0) |                        |
| **浏览器支持** | Mozilla FireFox ; Google Chrome ; Chromium ; MicroSoft Edge ; Apple Safari |                        |
| CPU（核）    | 8C+                                      | 16C+                   |
| 内存（GB）    | 8G+                                      | 16G+                   |
| 磁盘（GB）    | 500G 或 按需 ; SSD（不可使用NFS）                 | 1T 或 按需 ; SSD（不可使用NFS） |

# 2.在线安装

### 2.1 安装最新版本

访问官方网站，通过官方Linux安装包方式安装：

<https://gitlab.cn/install/>

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329299451-823a29be-0392-4207-91fd-7fc0e5cca836.png)

### 2.2 安装指定版本

1. 安装依赖、配置极狐GitLab 软件源镜像步骤同上，直到执行安装命令之前停止。

```
# 暂不执行
sudo EXTERNAL_URL="https://gitlab.example.com" apt-get install gitlab-jh
```

1. 查询极狐GitLab版本号。

```
# Ubuntu
sudo apt policy gitlab-jh 
## 或者
sudo apt madison gitlab-jh 

# RHEL/CentOS 7
sudo yum list --showduplicates gitlab-jh 
# RHEL/CentOS 8/AlmaLinux 8
sudo dnf list --showduplicates gitlab-jh
```

找到指定的版本号并复制，如`15.5.2-jh.0`。

1. 安装指定版本极狐GitLab。

```
# Ubuntu
sudo EXTERNAL_URL="https://gitlab.example.com" apt install gitlab-jh=<gitlab-jh版本号，如15.5.2-jh.0>
# RHEL/CentOS  7
sudo EXTERNAL_URL="https://gitlab.example.com" yum install gitlab-jh-<gitlab-jh版本号>
# RHEL/CentOS/AlmaLinux 8
sudo EXTERNAL_URL="https://gitlab.example.com" dnf install gitlab-jh-<gitlab-jh版本号>
```

注意`EXTERNAL_URL`是需要给极狐GitLab设置的域名，需确保对该域名设置了正确的DNS。对于 https 站点，极狐GitLab 将使用 Let's Encrypt 自动请求 SSL 证书，这需要有效的主机名和入站 HTTP 访问。也可以使用自己的证书或仅使用 http://（不带s）。

1. 默认配置下需确保22、80、443端口可对外提供访问

# 3. 离线安装

1. 从官方仓库下载指定版本的Linux安装包到本地，并传入离线环境中。

<https://packages.gitlab.cn/#browse/browse>

如：

- CentOS 7：<https://packages.gitlab.cn/#browse/browse:el:7>
- CentOS 8：<https://packages.gitlab.cn/#browse/browse:el:8>
- Ubuntu 18.04：<https://packages.gitlab.cn/#browse/browse:ubuntu-bionic:packages>
- Ubuntu 20.04：<https://packages.gitlab.cn/#browse/browse:ubuntu-focal:packages>
- Debian 9：<https://packages.gitlab.cn/#browse/browse:debian-stretch:packages>

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329299299-8d73e0a1-47ec-4d9d-b467-b7e5c2dd08bc.png)

1. 安装极狐GitLab。

\# Ubuntu / Debian dpkg -i <gitlab离线安装包，如gitlab-jh_15.1.0-jh.0_amd64>.deb # CentOS 7/8 rpm -ivh <gitlab离线安装包>.rpm

1. 默认配置下需确保22、80、443端口可对外提供访问。

# 4.初始密码

安装完成后，极狐GitLab将随机生成一个密码并存储在`/etc/gitlab/initial_root_password`文件中(出于安全原因，24 小时后会自动删除），使用`cat /etc/gitlab/initial_root_password`命令获取`root`用户的初始密码。

# **5.修改访问地址**

若在首次安装时，没有添加自定义的EXTERNAL_URL环境变量，如sudo EXTERNAL_URL="https://gitlab.example.com" apt install gitlab-jh，极狐GitLab默认的EXTERNAL_URL是https://gitlab.example.com，可根据实际需要进行修改：

```
vi /etc/gitlab/gitlab.rb
# 修改 external_url 'http://<域名 or IP>'
gitlab-ctl reconfigure
```

# 6.上传许可证

1. root/管理员账号登录极狐GitLab。
2. 参照下图上传许可证。

![img](https://cdn.nlark.com/yuque/0/2024/jpeg/35538885/1731329299278-9f219f8f-5b85-4551-86bb-331c089fb4cb.jpeg)