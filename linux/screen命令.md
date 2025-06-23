# screen命令

查看当前正在运行的screen有哪些

[root@oldboy ~]# screen -list

There is a screen on:

​    22058.sleep    (Detached)

1 Socket in /var/run/screen/S-root.

\#6.此时需要进入昨晚的会话，进入正在运行的screen

[root@oldboy ~]# screen -r sleep

[root@oldboy ~]# screen -r 22058

常用screen参数

screen -S yourname   #新建一个叫yourname的session

screen -ls           #列出当前所有的session

screen -r yourname   #回到yourname这个session

screen -d yourname   #远程detach某个session

screen -d -r yourname #结束当前session并回到yourname这个session

重点总结：

\#1.创建screen 创建 

screen 或 screnn -S 窗口名称

\#2.退出窗口

ctrl+a+d 

\#3.显示当前所有screen窗口

screen -ls

\#4.恢复,重新进入

screnn -r id 

# 

# 