## 10.JDK部署

```
JDK下载地址:
	https://www.oracle.com/java/technologies/javase/javase-jdk8-downloads.html
	
[root@elk101.oldboyedu.com ~]# ll
总用量 141540
-rw-r--r--. 1 root root 144935989 5月  16 11:54 jdk-8u291-linux-x64.tar.gz
[root@elk101.oldboyedu.com ~]# 
[root@elk101.oldboyedu.com ~]# tar zxf jdk-8u291-linux-x64.tar.gz -C /oldboy/softwares/
[root@elk101.oldboyedu.com ~]#
[root@elk101.oldboyedu.com ~]# cd /oldboy/softwares/
[root@elk101.oldboyedu.com /oldboy/softwares]# 
[root@elk101.oldboyedu.com /oldboy/softwares]# ll
总用量 0
drwxr-xr-x. 8 10143 10143 273 4月   8 03:26 jdk1.8.0_291
[root@elk101.oldboyedu.com /oldboy/softwares]# 
[root@elk101.oldboyedu.com /oldboy/softwares]# ln -sv jdk1.8.0_291 jdk
"jdk" -> "jdk1.8.0_291"
[root@elk101.oldboyedu.com /oldboy/softwares]# 
[root@elk101.oldboyedu.com /oldboy/softwares]# ll
总用量 0
lrwxrwxrwx. 1 root  root   12 5月  16 11:56 jdk -> jdk1.8.0_291
drwxr-xr-x. 8 10143 10143 273 4月   8 03:26 jdk1.8.0_291
[root@elk101.oldboyedu.com /oldboy/softwares]# 
[root@elk101.oldboyedu.com /oldboy/softwares]# vim /etc/profile.d/jdk.sh 
[root@elk101.oldboyedu.com /oldboy/softwares]# 
[root@elk101.oldboyedu.com /oldboy/softwares]# cat /etc/profile.d/jdk.sh 
#!/bin/bash

export JAVA_HOME=/oldboy/softwares/jdk
export PATH=$PATH:$JAVA_HOME/bin
[root@elk101.oldboyedu.com /oldboy/softwares]# 
[root@elk101.oldboyedu.com /oldboy/softwares]# source /etc/profile.d/jdk.sh 
[root@elk101.oldboyedu.com /oldboy/softwares]# 
[root@elk101.oldboyedu.com /oldboy/softwares]# java -version
java version "1.8.0_291"
Java(TM) SE Runtime Environment (build 1.8.0_291-b10)
Java HotSpot(TM) 64-Bit Server VM (build 25.291-b10, mixed mode)
[root@elk101.oldboyedu.com /oldboy/softwares]#
```