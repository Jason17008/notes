\# centos安装 xfs_undelete
yum install xfsprogs
\# 恢复删除的文件到当前目录
xfs_undelete /dev/[your_xfs_partition]


\# centos安装 scalpel
yum install scalpel
\# 恢复删除的文件到当前目录
scalpel /dev/[your_partition]



\* y 0 *

=========================================

\# centos 安装 teskdisk
yum install -y testdisk
\# 使用testdisk恢复被删除的文件




https://blog.csdn.net/qq_27546717/article/details/122264334
https://yuanzhuo.bnu.edu.cn/article/658?eqid=82734aa500193675000000036490370d