#!/bin/bash

# ===========初始化Linux Shell 自动化脚本========================

# ===========1、配置网络静态IP Shell 自动化脚本=======================

echo "===============正在配置网络静态IP================="

# ---------------------获取系统类型--------------------------
centos=$(cat /etc/*rele* | grep "ID" | awk -F "\"" 'NR==1{print $2}')

# -----------------获取网络设备名并用自定义变量 DEV 来接收-------------------
# ip a | grep "BROADCAST" 表示筛选含有 BROADCAST 字段的行
# awk -F ":" 'NR==1{print $2}' 表示以冒号为分隔符，NR==1 表示处理当前的第一行（ NR 是 awk 的内置变量表示行号），打印第 2 个字段
# sed "s/ //g" 表示删除行中的所有空格
DEV=$(ip a | grep "BROADCAST" | awk -F ":" 'NR==1{print $2}' | sed "s/ //g")

# ---------------------------备份网络配置文件-------------------------
cp /etc/sysconfig/network-scripts/ifcfg-"$DEV" /etc/sysconfig/network-scripts/ifcfg-"$DEV".bak

# ---------------------获取网络配置文件名并用自定义变量 netFile 来接收----------------------
netFile="/etc/sysconfig/network-scripts/ifcfg-$DEV"

# ---------------------修改网络配置文件中的 “ONBOOT=no” 为 “ONBOOT=yes”----------------------
ONBOOT=$(cat "$netFile" | grep '^ONBOOT' | awk -F = '{gsub(/"/,"");print $2}')
# 判断网路配置文件中的 ONBOOT=yes 是否存在
# tee -a $LogFile 表示标准输出追加到执行的文件 LogFile 中
if [ "$ONBOOT" != "yes" ];then
    echo "set device onboot to [yes]"
    sed -i "s/^ONBOOT=.*/ONBOOT=yes/g" "$netFile"
fi

# --------------------------启动网络----------------------------
service network start

# --------------------获取动态IP--------------------------------
# -E：使用egrep（支持更多的正则表达式元字符）命令 ；-o：只输出匹配的内容
# [0-9]{1,3} 表示 0-9 的数字出现 1-3 次
IPADDR=$(ip addr show "${DEV}" | grep inet | grep -E -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -1)

# --------------------配置静态IP----------------------------------

# 获取网关（GATEWAY）
# [ ! -n "$GATEWAY" ] 表示 "$GATEWAY" 的字符串长度为 0 则执行 then 后面的语句
GATEWAY=$(route -n | grep '^0.0.0.0' | awk '{print $2}')
if [ ! -n "$GATEWAY" ];then
    echo "No gateway addr,network configuration failed,please check your DECP server is valid or not"
    exit 1
fi

# 获取子网掩码（NETMASK）
NETMASK=$(ifconfig "$DEV" | grep 'netmask' | awk '{sub(/netmask/,"");print $3}')
if [ ! -n "$NETMASK" ];then
    echo "No netmask addr,network configuration failed,please check your DECP server is valid or not"
    exit 1
fi

# 设置域名解析
DNS1=114.114.114.114
DNS2=8.8.8.8

# 如果系统为 centos 且 $netFile 文件存在且为普通文件则执行后面的语句
# [ -n "$centos" ] 表示 "$centos" 的字符串长度不为 0 则执行 then 后面的语句
# [ -f "$netFile" ] 表示 "$netFile" 文件存在且为普通文件则执行后面的语句
if [ -n "$centos" ] && [ -f "$netFile" ];then
    
    echo "File exists"

    # 修改网络配置文件中的 “BOOTPROTO=dhcp” 为 “BOOTPROTO=static”
    BOOTPROTO=$(cat "$netFile" | grep '^BOOTPROTO' | awk -F = '{gsub(/"/,"");print $2}')
    if [ "$BOOTPROTO" != "static" ];then
        echo "The configured network type is [$BOOTPROTO],change to [static]"
        sed -i "s/^BOOTPROTO=.*/BOOTPROTO=static/g" "$netFile"
    fi

    # 设置临时变量 chuanchang
    chuanchang=$( cat "$netFile" | grep "IPADDR" -c )
    # 若 IPADDR 不存在则执行后面的语句
    if [ "$chuanchang" -eq 0 ];then
            cat >> "$netFile" <<EOF
            IPADDR=$IPADDR
            GATEWAY=$GATEWAY
            NERMASK=$NETMASK
            DNS1=$DNS1
            DNS2=$DNS2
EOF
            sed -i s/[[:space:]]//g "$netFile"
    else
            sed -i -e "s/IPADDR=.*$/IPADDR=$IPADDR/g" -e "s/NETMASK=.*$/NETMASK=$NETMASK/g" -e "s/GATEWAY=.*$/GATEWAY=$GATEWAY/g" -e "s/DNS1=.*$/DNS1=$DNS1/g" -e "s/DNS2=.*$/DNS2=$DNS2/g" "$netFile"
    fi
    
    # 查看修改好的网络配置文件
    cat "$netFile"

    # 从键盘读入变量值
    read -p "确认输入的IP、网关、子网掩码、DNS是否正确，正确按y，不确认按n：" para
    case $para in
    [Yy])
        echo "---------------重启网络-----------------"
        service network restart
        echo "--------------查看成功配置静态IP的网络配置文件---------------"
        cat "$netFile"
        ;;
    [Nn])
        echo "退出执行，请重新运行 sh 脚本"
        exit 1
        ;;
    esac        
else
    echo "File does not exist"
    exit 1
fi

# ===================2、安装常用程序==================

echo "==============正在安装常用程序=========================="

# 上传下载工具 系统状态 字符浏览器 下载工具 网络工具 自动补全
yum install -y lrzsz sysstat elinks wget net-tools bash-completion
 
# 查看是否安装成功
rpm -qa lrzsz sysstat elinks wget net-tools bash-completion

# ====================3、关闭防火墙和 selinux==============

echo "===============正在关闭防火墙和 selinux ================="

# 停止并开机禁用防火墙
systemctl stop firewalld
systemctl disable firewalld
 
# 关闭 selinux
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
 
# 查看防火墙状态
echo
echo "-----查看防火墙状态---------"
systemctl status firewalld
 
# 查看 selinux
echo
echo "-----查看 selinux---------"
getenforce

# ======================4、更换 YUM 源=======================

echo "===============正在更换 YUM 源================="

# 备份官方 yum 库
yum -y install wget

if [ -f /etc/yum.repos.d/CentOS-Base.repo ];then
    cd ~ || exit
    mkdir -p tmp/yum.repos.d.bak/
    mv /etc/yum.repos.d/* /root/tmp/yum.repos.d.bak/
    rm -rf /etc/yum.repos.d/*
fi
 
# 远程 yum 配置方法（企业中常用阿里云的yum进行配置）
    # 下载 “阿里巴巴开源镜像站” 官网配置（找到centos对应版本复制代码到命令行中即可）
    # centos 7 的镜像（-O：指定文件和路劲）
    wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
    # epel 7 的镜像
    wget -O /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo
 
# 每次更新完 yum 库都建议去清理下 yum 缓存
yum clean all
 
# 更新 yum 库，缓存软件包信息
yum makecache

# 查看 yum 源是否更换成功
echo "----------查看 yum 源是否更换成功----------"
ls /etc/yum.repos.d/