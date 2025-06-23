# 修改eth0

/etc/default/grub

GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"

sudo update-grub

重启即可发生变化  

# 配置ip

sudo nano /etc/netplan/01-netcfg.yaml

```
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

sudo netplan apply

# 换源

### ubuntu 20.04 LTS (focal)

```
deb https://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse

# deb https://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
# deb-src https://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse

```

综合脚本 要用bash运行

修改网卡名  跟改ip 都会导致 当前终端登录不上  

```
#!/bin/bash
set -e

# 用户可修改配置区域
STATIC_IP="192.168.1.100/24"
GATEWAY="192.168.1.1"
DNS_SERVERS=("8.8.8.8" "8.8.4.4")
MIRROR_URL="https://mirrors.aliyun.com/ubuntu/"

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

show_header() {
    clear
    echo -e "${GREEN}"
    echo "███████╗ ██████╗  ██████╗██████╗ "
    echo "██╔════╝██╔═══██╗██╔════╝╚════██╗"
    echo "█████╗  ██║   ██║██║      █████╔╝"
    echo "██╔══╝  ██║   ██║██║     ██╔═══╝ "
    echo "██║     ╚██████╔╝╚██████╗███████╗"
    echo "╚═╝      ╚═════╝  ╚═════╝╚══════╝"
    echo -e "${RESET}"
}

step_exec() {
    echo -e "${BLUE}[INFO]${RESET} 执行步骤: $1..."
    eval "$2"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${RESET} $1 完成"
    else
        echo -e "${RED}[ERROR]${RESET} $1 失败"
        exit 1
    fi
}

# 显示引导界面
show_header

# 1. 备份关键文件
step_exec "备份系统配置" '
sudo cp /etc/default/grub /etc/default/grub.bak;
sudo cp -r /etc/netplan /etc/netplan.bak;
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
'

# 2. 禁用一致性网络命名
step_exec "配置GRUB参数" '
sudo sed -i "/^GRUB_CMDLINE_LINUX=/s/\"$/ net.ifnames=0 biosdevname=0\"/" /etc/default/grub;
sudo update-grub
'

# 3. 生成持久化网卡命名规则
step_exec "生成UDEV规则" '
rules_file="/etc/udev/rules.d/70-persistent-net.rules";
sudo rm -f ${rules_file};
interfaces=($(ls /sys/class/net | grep -v lo | sort -V));
for idx in "${!interfaces[@]}"; do
    iface="${interfaces[$idx]}";
    mac=$(cat /sys/class/net/${iface}/address);
    echo "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"${mac}\", NAME=\"eth${idx}\"";
done | sudo tee ${rules_file} >/dev/null
'

# 4. 配置静态IP地址
step_exec "配置网络参数" '
netplan_file=$(ls /etc/netplan/*.yaml | head -n1);
sudo cp ${netplan_file} ${netplan_file}.orig;
sudo sed -i "s/en[a-z0-9]*/eth0/g" ${netplan_file};
sudo tee ${netplan_file} <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses: [${STATIC_IP}]
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
          addresses: [$(IFS=,; echo "${DNS_SERVERS[*]}")]
EOF
'

# 5. 更换阿里云镜像源
step_exec "配置软件源" '
ubuntu_codename=$(lsb_release -cs);
sudo tee /etc/apt/sources.list <<EOF
deb ${MIRROR_URL} ${ubuntu_codename} main restricted universe multiverse
deb-src ${MIRROR_URL} ${ubuntu_codename} main restricted universe multiverse

deb ${MIRROR_URL} ${ubuntu_codename}-security main restricted universe multiverse
deb-src ${MIRROR_URL} ${ubuntu_codename}-security main restricted universe multiverse

deb ${MIRROR_URL} ${ubuntu_codename}-updates main restricted universe multiverse
deb-src ${MIRROR_URL} ${ubuntu_codename}-updates main restricted universe multiverse

deb ${MIRROR_URL} ${ubuntu_codename}-backports main restricted universe multiverse
deb-src ${MIRROR_URL} ${ubuntu_codename}-backports main restricted universe multiverse
EOF
'

# 6. 应用所有配置
step_exec "应用网络配置" 'sudo netplan apply'
step_exec "更新软件缓存" 'sudo apt update'

echo -e "\n${YELLOW}*****************************************"
echo "初始化完成，请执行以下命令重启系统："
echo -e "${GREEN}sudo reboot${RESET}"
echo -e "${YELLOW}*****************************************${RESET}"
```

d