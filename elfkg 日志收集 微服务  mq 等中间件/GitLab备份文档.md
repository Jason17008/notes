**方法一：gitlab自身备份**

**参考网址：https://www.cnblogs.com/ssgeek/p/9392104.html**

1. **进入到gitlab所运行的服务器上，备份时需要保持gitlab处于正常运行状态，在服务器上执行gitlab-rake gitlab:backup:create命令进行备份**
2. **命令执行完成之后会在/var/opt/gitlab/backups/下创建一个备份的****tar****包**

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329182045-6c93103f-c6e1-49d9-afc5-4574017bca2d.png)

**这个压缩包就是Gitlab整个的完整部分, 其中开头的1632394454_2021_09_23_10.1.7是备份创建的日期**

**下载方法一：**

1.使用sftp登录

使用get命令下载到本地，或者移动硬盘

**下载方法二：**

1.**当****tar****包过大超过4G无法sz下拉时，执行命令**

sudo cat /var/opt/gitlab/backups/1632394454_2021_09_23_10.1.7_gitlab_backup.tar | sudo split -b 3G - /var/opt/gitlab/backups/1632394454_2021_09_23_10.1.7_gitlab_backup.tar

**此命令是用于将过大的****tar****包分割为每个小的3G的文件**

2.**分割完成后**

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329182050-d6fcf7b2-8314-4601-acc6-5691727640c5.png)

3.**将所有分割的文件sz下载到本地**

4.**打开****cmd****，****cd****至需要备份的目录下然后执行以下命令**

**命令模板：copy /B xxx.taraa+xxx.tarab+xxx.tarac xxx.tar**

copy /B 1632394454_2021_09_23_10.1.7_gitlab_backup.taraa+1632394454_2021_09_23_10.1.7_gitlab_backup.tarab+1632394454_2021_09_23_10.1.7_gitlab_backup.tarac+1632394454_2021_09_23_10.1.7_gitlab_backup.tarad+1632394454_2021_09_23_10.1.7_gitlab_backup.tarae+1632394454_2021_09_23_10.1.7_gitlab_backup.taraf+1632394454_2021_09_23_10.1.7_gitlab_backup.tarag+1632394454_2021_09_23_10.1.7_gitlab_backup.tarah+1632394454_2021_09_23_10.1.7_gitlab_backup.tarai+1632394454_2021_09_23_10.1.7_gitlab_backup.taraj+1632394454_2021_09_23_10.1.7_gitlab_backup.tarak+1632394454_2021_09_23_10.1.7_gitlab_backup.taral+1632394454_2021_09_23_10.1.7_gitlab_backup.taram 1632394454_2021_09_23_10.1.7_gitlab_backup.tar

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329182056-87592f56-9814-4d95-9803-38e531e391f3.png)

5.**完成之后会将所有的分割的文件组合成****tar****包**

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329182309-05c320e5-dd91-41dd-9b9e-224af3137e66.png)

**第二种方法：跑脚本(目前只支持windows版本)**

注意：此脚本备份比较费gitlab资源，服务器配置较低时容易把内存跑满

1. 脚本名为：gitlab_windows.py
2. 脚本参数详解：

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329182147-e9ab9699-f20d-46d8-a70e-c303c1dfe478.png)

--tokenString:gitlab账户的Private token

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329183068-ce67766f-c9e8-495f-9fd1-983ae781de6b.png)

--domain:域名或者ip地址

--path:windows的盘路径，例如：C盘是’C:\\’，其中因为Windows的路径为\，所以传值时要多带一个\转义

--title:备份文件所在目录名，无需提前创建，脚本可以创建

1. 脚本为python脚本，跑脚本之前需要windows中安装python环境
2. Python环境安装完成之后需要安装requests包，OS包，re包
3. 环境准备好了之后执行脚本命令：

python gitlab_windows.py --tokenString xxxx --domain xxxx:12000 --path 'C:\\' --title mzGitLab

1. 此脚本备份时只会备份代码，包括分支的代码

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1731329183095-abe0dd0c-475c-42d9-8dbb-b3703f032487.png)

其备份结构为：

Group

|

|-->project

| |

| |-->master分支的代码

| |

| |-->branche

| | |

| | |-->master分支代码

| | |

| | |-->其他分支代码