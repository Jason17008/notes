calico-node无法正常运行，报错如下：
calico/node is not ready: BIRD is not ready: BGP not established with x.x.x.x,y.y.y.y...

问题原因是calico node名称冲突

扩容工具扩容调用API扩容机器，会给扩容的机器以AWS-na-k8s-temp[1-9]来命名，集群上存在之前扩容的一台机器名称为aws-na-k8s-temp1，昨晚扩容了三台机器，名称为aws-na-k8s-temp1、aws-na-k8s-temp2、aws-na-k8s-temp3

然后就是这两台同样主机名（aws-na-k8s-temp1）的机器，在calico里面注册节点名称时就会产生冲突 ，导致冲突节点只能有一个注册进来


## 解决问题时相关命令记录
# 删除冲突的已注册calico节点
calicoctl delete node aws-na-k8s-temp1

# 给冲突机器重命名下hostname
hostnamectl set-hostname ip-172-31-7-227

# 将新名称写入calico的节点名称配置里面（注意不能有\n换行符）
echo -n ip-172-31-7-227 > /var/lib/calico/nodename

# 然后删除问题的calico-node使其重启
kubectl -n kube-system delete pod calico-node-xf99f

# 观察是否正常
# calicoctl get node
NAME               
aws-na-k8s-temp2   
aws-na-k8s-temp3   
ip-172-31-1-50     
ip-172-31-2-247    
ip-172-31-7-227

# calicoctl node status
Calico process is running.

IPv4 BGP status
+--------------+-------------------+-------+----------+-------------+
| PEER ADDRESS |     PEER TYPE     | STATE |  SINCE   |    INFO     |
+--------------+-------------------+-------+----------+-------------+
| 172.31.8.108 | node-to-node mesh | up    | 13:00:30 | Established |
| 172.31.3.33  | node-to-node mesh | up    | 13:08:09 | Established |
| 172.31.2.247 | node-to-node mesh | up    | 02:40:43 | Established |
| 172.31.7.227 | node-to-node mesh | up    | 02:40:49 | Established |
+--------------+-------------------+-------+----------+-------------+

IPv6 BGP status
No IPv6 peers found.

# 后续扩容改进操作
扩容好的机器要记得把hostname改成唯一的名称（相关扩容脚本已更新），记得操作前先把节点驱逐打污点：
kubectl drain 172.31.3.33 --delete-local-data --ignore-daemonsets