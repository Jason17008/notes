<https://cloud.tencent.com/developer/article/2450486>



# 参考文档

<https://cloud.tencent.com/developer/article/2450486>    kms搭建文档 

<https://blog.csdn.net/yeidc_net/article/details/131314893>  win激活报错处理方法 

<http://wind4.github.io/vlmcsd/>           win10密钥选择     本次我们选择的密钥  为  W269N-WFGWX-YVC9B-4J6C9-T83GX

<https://blog.csdn.net/weixin_45694548/article/details/122374458>  域控下发  

<https://blog.csdn.net/SouthWind0/article/details/80412890>    域控设备上共享文件夹 

<https://blog.csdn.net/shang_cm/article/details/103353526>  bat中提取为管理员权限





| Windows 10 Professional | W269N-WFGWX-YVC9B-4J6C9-T83GX |
| ----------------------- | ----------------------------- |
|                         |                               |

然后在windows电脑上 

![img](https://cdn.nlark.com/yuque/0/2025/png/35538885/1736586943804-167da555-1eac-4cf2-a218-448d3ddf97a6.png)

```
slmgr.vbs -skms kms.kuretru.com     #设置KMS服务器地址
slmgr.vbs -ato                      #立即尝试激活
```

W269N-WFGWX-YVC9B-4J6C9-T83GX

C:\Windows\system32>slmgr.vbs -upk

C:\Windows\system32>slmgr.vbs -ipk  W269N-WFGWX-YVC9B-4J6C9-T83GX

C:\Windows\system32>slmgr.vbs -skms   172.16.15.15

C:\Windows\system32>slmgr.vbs -ato  







# 脚本逻辑

1.检查是否管理员权限

2.查询操作系统是否符合（不符合退出） 

3.是否激活（激活退出程序）

4.安装密钥

5.设置服务器 激活 

6.定时任务 181天之后 在激活 





# ad域名共享文件夹创建

1.ad设备上创建文件夹

2.右击文件夹属性 设置为共享 如图下操作 设置用户everyone每个人  权限都为读写  点击共享 