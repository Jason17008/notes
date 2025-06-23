https://blog.csdn.net/weixin_46887489/article/details/134817519?spm=1001.2014.3001.5502



```
# 我们这里在10.0.1.201上安装（在生产中，大家要提供作好NFS-SERVER环境的规划）
# yum -y install nfs-utils
# ubuntu安装NFS服务端
# apt-get install nfs-kernel-server -y


# 创建NFS挂载目录
# mkdir /nfs_dir
# chown nobody.nogroup /nfs_dir

# 修改NFS-SERVER配置
# echo '/nfs_dir *(rw,sync,no_root_squash)' > /etc/exports

# 重启服务
# systemctl restart rpcbind.service
# systemctl restart nfs-kernel-server.service 
# systemctl restart nfs-utils.service 
# systemctl restart nfs-server.service 

# 增加NFS-SERVER开机自启动
# systemctl enable nfs-server.service 
Created symlink from /etc/systemd/system/multi-user.target.wants/nfs-server.service to /usr/lib/systemd/system/nfs-server.service.

# 验证NFS-SERVER是否能正常访问
## 注：如果查看不到目录，可以到另一机器上挂载试试  
## root@node-2:~# mount.nfs 10.0.1.201:/nfs_dir /mnt/
# showmount -e 10.0.1.201                 
Export list for 10.0.1.201:
/nfs_dir *

```





# 注意所有的节点 都要下载nfs的包 拥有mount.nfs挂载的能力