# 

**什么是运行级别**
Linux运行级别就是Linux系统启动时处于不同状态标识的集合，例如:文本模式、图形模式、重启模式、关机模式都会对应不同的运行级别，这个运行级别对于CeaoS7之前的具体标识体现为0-6之间的数字。

![img](https://cdn.nlark.com/yuque/0/2023/png/35182251/1696984900556-61a76db1-3b3f-45f5-953a-5a788994bde1.png?x-oss-process=image%2Fresize%2Cw_937%2Climit_0)

.查看运行级别：
**如何切换运行级别**
init + 数字
比如： init 6 进入重启
**systemd相关知识**
**systemd优势**
1.Centos7实现开机并行启动，显著提高开机启动速度。
2.自动解决启动间的服务依赖关系。
3.服务的启动配置文件统一语法，管理起来更方便。
4.systemd较好的解决原有模式缺陷，比如原有service不会关闭程序产生的子进程。
5.从 Debian9、Centos7、Ubunut16等系统开始，都开始使用systemd来管理服务。
6.Centos7服务的启动与停止不在使用脚本管理服务，也就是/etc/init.d下不在有脚本。
**systemd相关路径文件**

![img](https://cdn.nlark.com/yuque/0/2023/png/35182251/1696989771565-ac7abefb-1ef2-4c37-b826-2e504b054923.png)

**disable enable的原理：**
enable 就是创建了一个软链接
disable 就是删除了一个软链接

![img](https://cdn.nlark.com/yuque/0/2023/png/35182251/1696991648063-f3ac0f85-9b87-4edb-913b-3a2c9021027d.png)

![img](https://cdn.nlark.com/yuque/0/2023/png/35182251/1696991676629-6cb9989a-c545-452a-81b8-7dccca194873.png?x-oss-process=image%2Fresize%2Cw_937%2Climit_0)

![img](https://cdn.nlark.com/yuque/0/2023/png/35182251/1696994354388-256ad051-343d-4af9-8454-8fcd330ef626.png?x-oss-process=image%2Fresize%2Cw_937%2Climit_0)

**unit 模块常用说明**
常用的

![img](https://cdn.nlark.com/yuque/0/2023/png/35182251/1696994830245-d6c89140-5d68-4d78-ac20-f8d357ab6d1c.png)

更多的：

![img](https://cdn.nlark.com/yuque/0/2023/png/35182251/1696994859891-214df31d-3978-4e9a-a59b-1f054eadb007.png?x-oss-process=image%2Fresize%2Cw_623%2Climit_0)

**service 模块常用说明：**

![img](https://cdn.nlark.com/yuque/0/2023/png/35182251/1696994913120-a7c0f8a2-a484-49c8-bc17-9ee4341d98db.png?x-oss-process=image%2Fresize%2Cw_897%2Climit_0)

对于常见服务推荐使用forking 模式即可。 。
oneshot 适用于一次的服务
**install 模块常用说明**

![img](https://cdn.nlark.com/yuque/0/2023/png/35182251/1696995074109-c4c28908-ff0f-4fe5-a957-d25d3ac60e9c.png)

**nginx 的systemd启动文件解释**

![img](https://cdn.nlark.com/yuque/0/2023/png/35182251/1696995308975-9cf496ce-505c-43b8-98f2-c40d65d0f0b2.png?x-oss-process=image%2Fresize%2Cw_937%2Climit_0)

自定义服务启动文件：

![img](https://cdn.nlark.com/yuque/0/2023/png/35182251/1696995565981-116a2b5b-b07d-4ea2-ae87-869265881ea6.png?x-oss-process=image%2Fresize%2Cw_937%2Climit_0)

**自定义一个nginx脚本**
需要编译安装nginx

vim /usr/lib/systemd/system/nginx.service

[Unit]

Description=The nginx HTTP and reverse proxy server

After=network-online.target remote-fs.target nss-lookup.target

Wants=network-online.target

[Service]

Type=forking

PIDFile=/application/nginx-1.20.1/logs/nginx.pid

ExecStartPre=/usr/bin/rm -f /application/nginx-1.20.1/logs/nginx.pid

ExecStartPre=/application/nginx-1.20.1/sbin/nginx -t

ExecStart=/application/nginx-1.20.1/sbin/nginx

ExecReload=/application/nginx-1.20.1/sbin/nginx -s reload

KillSignal=SIGQUIT

TimeoutStopSec=5

KillMode=process

PrivateTmp=true

[Install]

WantedBy=multi-user.target

# 下面自己操作的 普罗米修斯 纳管

cd /usr/lib/systemd/system

\# 这里注意 拷贝过去的文件结尾一定要是 .service

cp sshd.service prometheus.service

```
[root@harbor softwares]# vim/usr/lib/systemd/system/prometheus.service 
[Unit]
Description=https://prometheus.io
[Service]
ExecStart=/oldboy/softwares/prometheus/prometheus  --config.file /oldboy/softwares/prometheus/prometheus.yml
Restart=on-failure

[Install]
WantedBy=multi-user.target      


把启动命令沾到上面   
```

然后         

systemctl daemon-reload      # 重启systemctl

systemctl start prometheus     # 启动普罗米修斯

systemctl stop prometheus      # 关闭普罗米修斯 