博哥安装的 

视频安装 因为 记得nat模式 然后安装完成之后

切换root 模式

sudo su -

apt update

然后下载vim 然后下载

apt -y install openssh-server

Vim /etc/ssh/sshd_config 

修改

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1725792327310-0ed0ecea-e5f4-48df-a1de-f0f6f50bf114.png)

改成yes

然后重启

Systemctl restart sshd

Passwd 修改 密码 xshell 连接 

lsb_release -a

查看那个版本 

```
Distributor ID:        Ubuntu
Description:        Ubuntu 22.04.4 LTS
Release:        22.04
Codename:        jammy
```

https://developer.aliyun.com/mirror/ubuntu?spm=a2c6h.13651102.0.0.3e221b11lDwIuN

查看这个地址 找到 jammy如何替换源 

要添加这些源，请按照以下步骤操作：

1. 打开终端。
2. 使用文本编辑器编辑 `/etc/apt/sources.list` 文件或创建一个新的 `.list` 文件在 `/etc/apt/sources.list.d/` 目录下。例如，您可以使用 `nano` 编辑器（如果已安装）来编辑 `/etc/apt/sources.list` 文件：

```
sudo vim /etc/apt/sources.list
```

1. 或者，在 `/etc/apt/sources.list.d/` 目录下创建一个新文件：

```
sudo vim /etc/apt/sources.list.d/aliyun.list
```

1. 将您提供的 `deb` 和 `deb-src` 行粘贴到文件中。确保每行都正确无误，并且没有多余的空格或格式错误。
2. 保存并关闭文件。如果您使用的是 `nano`，可以通过按 `Ctrl+O` 保存更改，然后按 `Enter` 确认文件名，最后按 `Ctrl+X` 退出。
3. 更新您的软件包列表。在终端中运行以下命令来确保系统知道新的软件源：

```
sudo apt update
```

1. 现在，您可以使用新的软件源来安装软件包了。例如，要安装一个软件包，可以使用：

请确保在编辑文件时保持谨慎，因为错误的源或格式可能会导致软件包管理问题。如果您不确定，可以先备份 `/etc/apt/sources.list` 文件。