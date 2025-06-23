# 主从架构图

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329499181-b36a6148-84c4-406b-8d40-7195dc3a6682.png)

# 主从搭建

## 安装主节点

1. 本地安装rpm包。

```
rpm -ivh gitlab-jh-15.5.4-jh.0.el7.x86_64.rpm
```

1. 修改配置

```
vim /etc/gitlab/gitlab.rb
修改如下：
external_url 'http://<域名 or IP>'
```

1. 重载Gitlab配置

```
gitlab-ctl reconfigure
```

1. 获取root用户默认密码

```
cat /etc/gitlab/initial_root_password
```

## 添加主节点Lincese

gitlab主从功能只有专业版&旗舰版支持。

使用lincese位置。

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329499192-cbd2a4cf-513f-443d-aba5-ad9977b9032b.png)

## 设置主节点

1. 修改 /etc/gitlab/gitlab.rb ，为主节点定义一个独特的名称：

```
gitlab_rails['geo_node_name'] = 'cn'
```

1. 运行 gitlab-ctl reconfigure ，使上述配置生效。 
2. 指定当前节点为主节点:

```
gitlab-ctl set-geo-primary-node
```

输出：

```
Saving primary Geo node with name cn.alexju.cn and URL https://cn.alexju.cn/ 
... 
https://cn.alexju.cn/ is now the primary Geo node
```

1. 设置PostgreSQL数据库用户gitlab以及复制用户gitlab_replicator的密码并生成MD5 hash值:

```
gitlab-ctl pg-password-md5 gitlab 
# Enter password: 
# Confirm password: 
# a21bac24************2e46e2e2
#
```

编辑 /etc/gitlab/gitlab.rb。"db_password"的value为上一步键入的密码。"sql_user_password"的value为上一步最后输出的hash值。

```
postgresql['sql_user_password'] = 'a21bac24************2e46e2e2' 
gitlab_rails['db_password'] = '*******'
```

1. 默认内置的复制用户gitlab_replicator, 也需要设置密码。

```
gitlab-ctl pg-password-md5 gitlab_replicator 
# Enter password: <your_password_here> 
# Confirm password: <your_password_here> 
# 950233c0dfc2f39c64cf30457c3b7f1e
```

编辑 /etc/gitlab/gitlab.rb ：

```
postgresql['sql_replication_password'] = '950233c0dfc2f39c64cf30457c3b7f1e'
```

1.  配置PostgreSQL监听地址

```
#启用Geo标志 
roles(['geo_primary_role'])
#配置PG监听的公网地址或者VPC内部地址 
postgresql['listen_address'] = '0.0.0.0' 
postgresql['md5_auth_cidr_addresses'] = ['127.0.0.1/32', '主节点IP/32', 
'从节点IP/32'] 
#配置从节点的DB复制槽数量 n
postgresql['max_replication_slots'] = 5 
#临时禁止数据库自动迁移，直到PG完成重启并监听内部地址 
gitlab_rails['auto_migrate'] = false
```

运行 gitlab-ctl reconfigure ,使GitLab配置生效 。

运行 gitlab-ctl restart postgresql ，使PostgreSQL配置生效 。

编辑 /etc/gitlab/gitlab.rb，做如下修改：

```
gitlab_rails['auto_migrate'] = true
```

运行 gitlab-ctl reconfigure ,使GitLab配置生效 。

至此，主节点配置完成，可以在主节点页面查看主节点状态：

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329499204-d3a836c2-c1c0-4569-80f8-ffb315a4e95e.png)

## 安装从节点

步骤与"步骤1.安装主节点"一致

## 设置从节点

直接在root用户下进行下方所有操作

1. 停止 puma 和 sidekiq 服务

```
gitlab-ctl stop puma 
gitlab-ctl stop sidekiq
```

1. 检查与主节点PostgreSQL数据库连通性

```
gitlab-rake gitlab:tcp_check[主节点IP,5432]
```

输出：

```
TCP connection from 43.131.246.172:45696 to 1.13.24.86:5432 succeeded
```

1. 安装 server.crt 

```
mkdir /etc/gitlab/ssl 
scp root@主节点IP:~gitlab-psql/data/server.crt /etc/gitlab/ssl 

install \ 
-D \ 
-o gitlab-psql \ 
-g gitlab-psql \ 
-m 0400 \ 
-T /etc/gitlab/ssl/server.crt ~gitlab-psql/.postgresql/root.crt
```

Ps：证书复制完成后，建议使用md5sum检查两边证书的一致性，注意主从节点的证书位置有区别。

1. 测试数据库TLS加密通信

```
sudo \ 
-u gitlab-psql /opt/gitlab/embedded/bin/psql \ 
--list \ 
-U gitlab_replicator \ 
-d "dbname=gitlabhq_production sslmode=verify-ca" \ 
-W \ 
-h 主节点IP


```

输出：

```
List of databases 
Name | Owner | Encoding | Collate | Ctype | Access privileges 
---------------------+-------------+----------+---------+-------+-----------------------
gitlabhq_production | gitlab | UTF8 | C | C | 
postgres | gitlab-psql | UTF8 | C | C | 
template0 | gitlab-psql | UTF8 | C | C | =c/"gitlab-psql" 
| | | | | "gitlab-psql"=CTc/"gitlab-psql"
template1 | gitlab-psql | UTF8 | C | C | "gitlab-psql"=CTc/"gitlab-psql"+ 
| | | | | =c/"gitlab-psql" 
(4 rows)
```

1. 配置gitlab.rb文件

```
roles(['geo_secondary_role'])
postgresql['listen_address'] = '0.0.0.0' 
postgresql['md5_auth_cidr_addresses'] = ['127.0.0.1/32','主节点IP/32','从节点IP/32'] 
#sql_replication_password是主节点复制用户的hash密码 
postgresql['sql_replication_password'] = '<md5_hash_of_your_password>' 
#sql_user_password是之前主节点数据库用户gitlab的hash密码 
postgresql['sql_user_password'] = 'a21bac24************2e46e2e2' 
#db_password为主节点数据库用户gitlab的明文密码 
gitlab_rails['db_password'] = '********'
```

1. 运行 gitlab-ctl reconfigure ,使GitLab配置生效 。
2. 运行 gitlab-ctl restart postgresql ，使PostgreSQL配置生效 。

## 数据库同步和复制

切记下方步骤在从节点上执行，该步骤会删除从节点所有数据

1. 修改从节点配置

```
cd /var/opt/gitlab/postgresql/data/ 
sed -i 's/verify-full/verify-ca/g' gitlab-geo.conf 
gitlab-ctl restart postgresql 
gitlab-ctl tail postgresql
```

1. 复制数据库

给从节点指定一个独特的名称slot-name, 该名称只允许包含 小写字母、数字和下划线 。运行时最好指定 --backup-timeout ，默认是30mins，避免流复制超时。

```
gitlab-ctl replicate-geo-database --slot-name=us --host=主节点IP --sslmode=verify-ca --backup-timeout=7200
```

输出：

输出中“xxx”格式为需要键入的内容。其中，replicate为固定值，连接gitlab数据库密码为步骤3“设置主节点”中第四小节中设置的密码。

```
No user created projects. Database not active 
WARNING: Make sure this script is run from the secondary server 
*** You are about to delete your local PostgreSQL database, and replicate 
the primary database. *** 
*** The primary geo node is `1.13.24.86` *** 
*** Are you sure you want to continue (replicate/no)? *** 
Confirmation: replicate 
Enter the password for gitlab_replicator@1.13.24.86: 连接gitlab数据库密码
* Executing GitLab backup task to prevent accidental data loss 
* Stopping PostgreSQL and all GitLab services 
* Checking for replication slot us 
* Creating replication slot us 
* Backing up postgresql.conf 
* Moving old data directory to '/var/opt/gitlab/postgresql/data.1620826017' 
* Starting base backup as the replicator user (gitlab_replicator) 
pg_basebackup: initiating base backup, waiting for checkpoint to complete 
pg_basebackup: checkpoint completed 
pg_basebackup: write-ahead log start point: 0/C000028 on timeline 1 
pg_basebackup: starting background WAL receiver 
0/79784 kB (0%), 0/1 tablespace (...lab/postgresql/data/backup_label) 
65879/79784 kB (82%), 0/1 tablespace (...postgresql/data/base/16401/28114) 
79794/79794 kB (100%), 0/1 tablespace (...ostgresql/data/global/pg_control) 
79794/79794 kB (100%), 1/1 tablespace 
pg_basebackup: write-ahead log end point: 0/C000138 
pg_basebackup: waiting for background process to finish streaming ... 
pg_basebackup: syncing data to disk ...
pg_basebackup: base backup completed 
* Restoring postgresql.conf 
* PostgreSQL 12 or newer. Writing settings to postgresql.conf and creating 
standby.signal 
* Setting ownership permissions in PostgreSQL data directory 
* Starting PostgreSQL and all GitLab services
```

执行刷新配置：

```
gitlab-ctl reconfigure
```

## GEO配置

1. 拷贝**secrets**

备份从节点secrets文件:

```
mv /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.`date +%F`
```

复制主节点secrets文件到从节点：

```
scp root@主节点IP:/etc/gitlab/gitlab-secrets.json /etc/gitlab
```

修改权限：

```
chown root:root /etc/gitlab/gitlab-secrets.json 
chmod 0600 /etc/gitlab/gitlab-secrets.json
```

重启从节点：

```
gitlab-ctl reconfigure 
gitlab-ctl restart
```

1. 拷贝SSH主机密钥

备份从节点主机密钥：

```
find /etc/ssh -iname ssh_host_* -exec cp {} {}.backup.`date +%F` \;
```

拷贝主节点主机密钥：

```
scp root@主节点IP:/etc/ssh/ssh_host_*_key* /etc/ssh
```

修改主机密钥权限：

```
chown root:root /etc/ssh/ssh_host_*_key* 
chmod 0600 /etc/ssh/ssh_host_*_key*
```

检查两边主机密钥一致性：

```
for file in /etc/ssh/ssh_host_*_key; do ssh-keygen -lf $file; done
```

输出：

```
256 SHA256:+zS8Eu3XaV/MS3LDNGXtnj4u8xBdIqdhmQjPkO2xg60 /etc/ssh/ssh_host_ecdsa_key.pub (ECDSA) 
256 SHA256:r8hi50aXfS7yl8CuExLYr4DuW7JX20swoDlqPWKwKdo /etc/ssh/ssh_host_ed25519_key.pub (ED25519) 
2048 SHA256:T+QzA8AJqD5UHoVsRIljDTdVy2ooimNWHJjJoue+O+U /etc/ssh/ssh_host_rsa_key.pub (RSA)
```

重新加载OpenSSH：

```
# Debian 或 Ubuntu 
service ssh reload 
# CentOS 
service sshd reload
```

1. 添加从节点

配置gitlab.rb

```
# vim /etc/gitlab/gitlab.rc 添加下方行
gitlab_rails['geo_node_name'] = 'us'
 
gitlab-ctl reconfigure
```

在主节点页面上添加从节点

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329499282-370c5b41-8865-4ef7-85d8-65f7f86a44c4.png)

填写Name和URL，Name是从机 /etc/gitlab/gitlab.rb文件中的gitlab_rails['geo_node_name'] ,URL是 external_url ，必须和配置文件保持一致。

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329499274-164d3a42-20c8-4799-b052-2a8cd70a00e5.png)

在主节点页面上添加完成后，在从节点上运行 gitlab-ctl restart 。

在从节点上检查geo配置：

```
gitlab-rake gitlab:geo:check
```

输出：

检查结果中除“OpenSSH configured to use AuthorizedKeysCommand”为skipped，其他项均为yes。

```
Checking Geo ... 
GitLab Geo secondary database is correctly configured ... yes 
Database replication enabled? ... yes 
Database replication working? ... yes 
GitLab Geo HTTP(S) connectivity ... 
* Can connect to the primary node ... yes 
GitLab Geo is available ... 
GitLab Geo is enabled ... yes 
This machine's Geo node name matches a database record ... yes, found a secondary node named "us" 
HTTP/HTTPS repository cloning is enabled ... yes 
Machine clock is synchronized ... yes 
Git user has default SSH configuration? ... yes 
OpenSSH configured to use AuthorizedKeysCommand ... skipped 
Reason: 
Cannot access OpenSSH configuration file 
Try fixing it: 
This is expected if you are using SELinux. You may want to check 
configuration manually 
For more information see: 
doc/administration/operations/fast_ssh_key_lookup.md 
GitLab configured to disable writing to authorized_keys file ... yes 
GitLab configured to store new projects in hashed storage? ... yes 
All projects are in hashed storage? ... yes 
Checking Geo ... Finished
```

命令行查看同步状态：

```
gitlab-rake geo:status
```

1. 同步authorized_keys

在主节点页面中：

取消选中截图中“使用authorized_keys文件来验证SSH密钥”选项。

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329551256-b094f84b-4aaf-40d9-af24-d33319e1f750.png)

修改ssh配置文件：

在主、从节点均添加如下行

```
# vim /etc/ssh/sshd_config
Match User git
AuthorizedKeysCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-keys-check git %u %k 
AuthorizedKeysCommandUser git 
Match all
```

重启SSH：

```
# Debian 或 Ubuntu 
service ssh reload 
# CentOS 
service sshd reload
```

至此，gitlab主从集群搭建完成。可以登陆主节点或从节点对gitlab进行操作。

# 灾备切换

目前Gitlab不支持自动切换，手动切换步骤如下：

## 尽可能的完成数据复制 

如果从节点仍然可以从主节点复制数据，应尽量根据有计划的步骤完成数据的复制，避免数据损失。 

## 永久禁用主节点 

如果主节点宕机且有数据没来得及复制，这部分数据应该视为永久损失。 

如果你仍然可以ssh到主节点，运行： 

```
gitlab-ctl stop 
systemctl disable gitlab-runsvdir
```

如果已经不能登陆主节点，那么应该尽可能防止主节点的重新上线，包括： 

- 重新配置负载均衡器。 
- 更改DNS记录（例如，将主要DNS记录指向从节点，以停止使用主要节点）。 
- 停止虚拟服务器。 
- 阻止通过防火墙的流量。 
- 从主节点撤销对象存储权限。 
- 物理断开机器连接。 

如果你需要更改DNS, 可以考虑降低TTL, 加快DNS传播生效。 

## 推举从节点

修改从节点配置：

```
vim /etc/gitlab/gitlab.rc

# 删除如下行:
roles(['geo_secondary_role'])
```

这里暂时不要运行 gitlab-ctl reconfigure

强制选举从节点

```
gitlab-ctl geo promote --force
```

使配置生效：

```
gitlab-ctl reconfigure
```

更新主机URL：

```
gitlab-rake geo:update_primary_node_url
```

移除从节点的跟踪数据库：

```
rm -rf /var/opt/gitlab/geo-postgresql
```

## 设置新从节点

使用新的虚拟机重复执行“主从搭建”步骤即可。

# LB方案

## 背景

为了解决用户网络与gitlab网络隔离，需要在gitlab侧修改相关配置。

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329552328-edaa6066-0e2a-4cc2-9ee3-83c933598941.png)

## gitlab配置

由于gitlab中存在两种拉取代码的方式：HTTP、SSH。因此，在LB配置中需要支持这两种方式。

需要提前申请一个域名，此处用“gitlab.example.cn”来代替。

编辑主节点的gitlab.rb：

```
#修改external_url
external_url 'http://gitlab.example.cn'

gitlab-ctl reconfigure
```

此时在gitlab中选择仓库HTTP或SSH克隆时复制到的地址中已经切换为域名。

PS：特殊情况如下：

- 由于SSH端口使用为22，会存在无法使用的情况，因此设置SSH克隆的端口。

编辑主节点的gitlab.rb：

```
#修改如下两项配置
# ssh clone的地址，为上一步使用的域名
gitlab_rails['gitlab_ssh_host'] = 'gitlab.example.cn'
# ssh clone的端口
gitlab_rails['gitlab_shell_ssh_port'] = 2221

gitlab-ctl reconfigure
```

此时在gitlab中选择仓库SSH克隆时复制到的地址中已经切换为域名和端口。

# GITLAB-RUNNER 离线安装和灾备方案

## 1.离线安装基于k8s的runner

**ps****: 默认已经安装好gitlab和k8s,资源下载的步骤在能联网的机器操作**

1.1 下载helm

```
version=v3.1.2
#从华为开源镜像站下载
curl -LO https://repo.huaweicloud.com/helm/${version}/helm-${version}-linux-amd64.tar.gz
tar -zxvf helm-${version}-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
## 添加chart存储库
helm repo add gitlab https://charts.gitlab.io
## 验证源
helm repo list
```

1.2 下载gitlab-runner 镜像,传到本地仓库

```
docker pull registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v15.5.1
docker tag f8a0fdee90a3 192.168.2.160/gitlab-org/gitlab-runner:alpine-v15.5.1
docker push 192.168.2.160/gitlab-org/gitlab-runner:alpine-v15.5.1

#如果本地无法操作，那么就在能操作的地方把镜像制作为tar包，然后导入。
#导出为tar包
docker save -o alpine-v15.5.1.tar  registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v15.5.1
#导入并push
sudo docker import alpine-v15.5.1.tar  192.168.2.160/gitlab-org/gitlab-runner:alpine-v15.5.1
sudo docker push 192.168.2.160/gitlab-org/gitlab-runner:alpine-v15.5.1
```

1.3 下载gitlab-runner，修改镜像为本地镜像拉取

```
#查看可用的gitlab-runner
helm search repo -l gitlab/gitlab-runner
#然后下载gitlab-runner (默认下载最新版本，可用 --version x.x.x 拉取指定版本)
helm pull gitlab/gitlab-runner
tar -zxvf gitlab-runner-0.46.1.tgz
cd gitlab-runner
vi values.yaml
```

1.3.1修改内容为本地镜像拉取

```
image:
  registry: 192.168.2.160
  image: gitlab-org/gitlab-runner
  tag: alpine-v15.5.1
```

 1.4 在k8s创建namespace

```
kubectl create namespace gitlab-runner
```

1.5 启动gitlab-runner

```
#重新打包生成chart   gitlab-runner-0.46.1.tgz
helm package .
helm install gitlab-runner \
  --set gitlabUrl=http://10.1.4.214/ \
  --set runnerRegistrationToken="G8qV_e_a-LBnyxsbwaaX" \
  --set rbac.create=true \
  --set privileged=true \
  --set runners.tags=k8s-runner \
  --set runners.runUntagged=true \
  --namespace gitlab-runner \
  -f values.yaml \
  gitlab-runner-0.46.1.tgz
```

gitlabUrl 为gitlab的主机（或域名）地址

runnerRegistrationToken 到gitlab的runner里面copy出来,如下图

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329551233-c7b93a46-c514-46f7-88b0-fc1501067264.png)

1.6 配置缓存

```
#找到runner得configmap
kubectl get cm -n gitlab-runner
#修改对应的configmap
kubectl edit cm gitlab-runner -n gitlab-runner
```

在entrypoint字段中找到Start the runner字段，在该字段上面添加以下内容并保存：

```
cat >>/home/gitlab-runner/.gitlab-runner/config.toml <<EOF
    [runners.docker]
    helper_image= "192.168.2.160/security-products/gitlab-runner-helper:x86_64-7178588d"
    [[runners.kubernetes.volumes.host_path]]
    name = "docker"
    mount_path = "/var/run/docker.sock"
    read_only = true
    host_path = "/var/run/docker.sock"
    [[runners.kubernetes.volumes.host_path]]
    name = "cache"
    mount_path = "/cache"
    read_only = false
    host_path = "/home/devops/data"
    EOF
```

然后重启runner

```
kubectl delete pod gitlab-runner-594f45f6bf-jql8w -n gitlab-runner
```

### 1.1 gitlab-runner离线安装

在可以链接公网的机器下载 gitlab-runner-helper

```
docker pull registry.gitlab.com/gitlab-org/gitlab-runner/gitlab-runner-helper:x86_64-7178588d
docker save -o x86_64-7178588d.tar  registry.gitlab.com/gitlab-org/gitlab-runner/gitlab-runner-helper:x86_64-7178588d
```

 然后load到 对应的k8s节点(切记是load，而不是import)

```
docker load < x86_64-7178588d.tar
```

## 2.离线安装基于vm的runner

```
# Download the binary for your system
sudo curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64

# Give it permission to execute
sudo chmod +x /usr/local/bin/gitlab-runner

# Create a GitLab Runner user
sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash

# Install and run as a service
sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
sudo gitlab-runner start

#注册runner的命令
sudo gitlab-runner register --url http://10.1.4.214/ --registration-token G8qV_e_a-LBnyxsbwaaX
```

在页面配置该runner的 tag：checkout-tags

在页面配置gitlab ssh 凭证，用于免密拉去代码

## 3.灾备方案

### 3.1 基于k8s的runner灾备

```
#查询全部，可以看到失败的服务
helm -n gitlab-runner ls -a
#删除失败的安装
helm -n gitlab-runner delete gitlab-runner
#查询deployment
kubectl get deployment -n gitlab-runner

#回到以前安装gitlab-runner的地方，修改灾备后的url即可
helm install gitlab-runner \
  --set gitlabUrl=http://灾备后的地址/ \
  --set runnerRegistrationToken="G8qV_e_a-LBnyxsbwaaX" \
  --set rbac.create=true \
  --set privileged=true \
  --set runners.tags=k8s-runner \
  --set runners.runUntagged=true \
  --namespace gitlab-runner \
  -f values.yaml \
  gitlab-runner-0.46.1.tgz
```

### 3.2 基于vm的runner灾备

```
#到vm上
ps -ef | grep gitlab-runner

kill -9  30432

#启动runner 替换地址
gitlab-runner register --url http://灾备后地址/ --registration-token G8qV_e_a-LBnyxsbwaaX
```

然后一直回车，一直到Enter an executor: docker-ssh+machine, docker, docker-ssh, shell, docker+machine, instance, kubernetes, custom, parallels, ssh, virtualbox:

填写: shell

如下图所示：

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329551216-16ec52fb-bf40-44f4-9c6a-27c3827fbd89.png)

然后到页面上找到对应runner,点击修改填入tag: checkout-tags

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329551203-8f99e039-4ec3-4e89-8e5f-3534021a9d8a.png)

# 开启GEO的Gitlab升级

## 确认升级路径

根据附录2中链接，确定由当前版本Gitlab升级到目标Gitlab的升级路径。当前章节演示的版本为极狐gitlab-15.5.4，目标版本为极狐gitlab-16.3.5。由附录二可得，极狐Gitlab-15.5.4升级到极狐Gitlab-16.3.5的升级路径如下图。

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329552173-3a1cc59e-2cbb-43e6-b9db-dd78156ba30b.png)

## 下载极狐Gitlab

使用附录三的链接，下载升级路径中对应版本的极狐Gitlab的RPM包。当前章节演示需要下载极狐Gitlab-15.11.13，极狐Gitlab-16.1.5，极狐Gitlab-16.3.5。下载的文件如下图。

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329552169-97919586-8a96-4967-9111-be392fbe797d.png)

本章节使用的升级方法不包含极狐Gitlab的数据备份。因此在操作之前请做好主机快照。

## 升级前检查极狐Gitlab状态

- 登录到极狐Gitlab首页，进入管理员菜单。

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329552169-60bb5ac7-f983-49de-863d-37fae0c60c0d.png)

- 进入监控--后台迁移菜单，确保后台迁移菜单中“队列中”以及“正在完成”的数据为“0”。

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329552206-3637cf51-b60e-4bda-972b-1f9479efa606.png)

## 暂停GEO配置

在极狐Gitlab的从节点上执行GEO暂停命令。

```
sudo gitlab-ctl geo-replication-pause
```

## 升级极狐Gitlab

- 因为本章节实验是在主机快照完成之后进行的，因此在升级之前，创建跳过备份的文件。

```
sudo touch /etc/gitlab/skip-auto-backup
```

- 在极狐Gitlab的主节点上，执行升级命令将极狐Gitlab升级到路径的第一个节点。

```
sudo rpm -Uvh /home/devops/gitlab-jh-15.11.13-jh.0.el7.x86_64.rpm
```

升级完成后，进入极狐Gitlab页面，进行步骤三(升级前检查极狐Gitlab状态)，确保后台迁移菜单中的任务均为“0”。

根据升级路径，重复执行上述 rpm命令以及确认后台迁移任务。直到将极狐Gitlab升级到目标版本。至此，极狐Gitlab主节点升级完成。

- 在极狐Gitlab的从节点上，执行升级命令将极狐Gitlab升级到路径的第一个节点。

```
sudo rpm -Uvh /home/devops/gitlab-jh-15.11.13-jh.0.el7.x86_64.rpm
```

升级完成后，进入极狐Gitlab页面，进行步骤三(升级前检查极狐Gitlab状态)，确保后台迁移菜单中的任务均为“0”。

根据升级路径，重复执行上述 rpm命令以及确认后台迁移任务。直到将极狐Gitlab升级到目标版本。至此，极狐Gitlab从节点升级完成。

## 恢复GEO配置

在极狐Gitlab的从节点上执行GEO暂停命令。

```
sudo gitlab-ctl geo-replication-resume
```

## 验证极狐Gitlab菜单切换功能

登录极狐Gitlab页面，取消勾选新版导航栏，等待刷新后切换至旧版导航栏。

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329552655-6e0daaee-eae8-41d6-bad3-1ed955232564.png)

勾选新版导航栏，等待刷新后切换至新版导航栏。

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329552938-67bfdfba-b3bd-46dc-8fc8-9a17e99a6f66.png)

# 问题清单

## 主从配置完成后，从节点健康状态未知

问题可能出现在“主从搭建-步骤7-GEO配置”中，当按照文档配置完成GEO后，在主节点GEO页面查看从节点状态时，从节点健康状态一直为未知，可能原因为gitlab内部同步较慢，需要5-10分钟时间后，从节点健康状态变为正常。

## 主从搭建完成后，登陆从节点时跳转至主节点

原因是在主节点中设置了固定的访问URL，从节点同步了主节点的数据库，导致访问从节点时跳转至主节点中设置的固定URL。

设置位置如下：

切记，如无特殊需要，不要设置该字段

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329552937-9dcd6265-3232-4cb9-a993-2ce07dff47c8.png)

## 灾备切换完成后，访问新主节点，页面回切换至旧主节点

该问题与问题2的原因一致。为了不影响新主节点登陆，需要在新主节点做如下操作：

```
gitlab-psql

update  application_settings set home_page_url=' ' where id=1;
```

# 附录

## Gitlab EE 下载地址

https://packages.gitlab.com/gitlab/gitlab-ee

## 

## 极狐Gitlab升级路径查看地址

https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/?distro=centos

## 极狐Gitlab下载地址

https://packages.gitlab.cn/#browse/browse:el