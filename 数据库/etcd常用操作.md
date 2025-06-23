etcd





```
由于我们ETCD集群启用了TLS双向认证，故在etcdctl连接ETCD时需要指定--cacert、--ccert、–key以指定连接凭据，这个比较麻烦，建议将下面的变量添加到/etc/profile中，这样就可以直接执行etcdctl命令了

# 仅root用户
cat>>.bash_profile<<EOF
export ETCDCTL_DIAL_TIMEOUT=3s
export ETCDCTL_CACERT=/etc/etcd/ca.crt
export ETCDCTL_CERT=/etc/etcd/client.crt
export ETCDCTL_KEY=/etc/etcd/client.key
EOF

# 所有用户
cat>>profile<<EOF
export ETCDCTL_DIAL_TIMEOUT=3s
export ETCDCTL_CACERT=/etc/etcd/ca.crt
export ETCDCTL_CERT=/etc/etcd/client.crt
export ETCDCTL_KEY=/etc/etcd/client.key
EOF

# 对当前终端立即生效
. .bash_profile
. /etc/profile

# 测试
etcdctl endpoint --cluster=true health -w table
+----------------------------+--------+-------------+-------+
|          ENDPOINT          | HEALTH |    TOOK     | ERROR |
+----------------------------+--------+-------------+-------+
| https://172.16.15.170:2379 |   true | 27.191952ms |       |
| https://172.16.15.171:2379 |   true | 34.436953ms |       |
| https://172.16.15.172:2379 |   true | 36.394256ms |       |
+----------------------------+--------+-------------+-------+


集群操作
# 获取当前端点的哈希值
etcdctl endpoint hashkv
# 获取集群所有端点的哈希值
etcdctl endpoint hashkv --cluster=true
# 更换输出的样式，支持这些格式 fields, json, protobuf, simple, table
etcdctl endpoint hashkv --cluster=true -w table
# 获取端点状态
etcdctl endpoint status
# 获取集群端点状态
etcdctl endpoint --cluster=true status
# 获取当前端点的心跳
etcdctl endpoint health -w table
# 获取集群所有节点的心跳
etcdctl endpoint health --cluster=true -w table




Key操作
# 创建一个key
etcdctl put name kevinzhu
# 读取指定key里面的value
etcdctl get name
# 为key配置键过期时间
# 1. 先创建一个lease
etcdctl lease grant 30
lease 35027bc8b35ddcfb granted with TTL(30s)
# 这里创建了一个30秒存活的
# 2. 然后为key关联上这个lease
etcdctl put name kevinzhu --lease=35027bc8b35ddcfb


账户、角色、认证
# 创建用户，会要求输入密码
etcdctl user add root
# 删除用户
etcdctl user delete root
# 获取用户详情
etcdctl user get root
# 为用户关联角色
etcdctl user grant-role root root
# 移出账户关联的角色
etcdctl user revoke-role root root
# 列出所有用户
etcdctl user list
# 重置用户密码
etcdctl user passwd root


# 打开用户名密码认证的开关，打开后连接时不仅需要进行TLS的认证还需要检查用户名和密码
etcdctl auth enable
# 禁用用户名和密码认证，关闭这个需要先认证通过
etcdctl auth disable


快照操作
# 生成快照
etcdctl snapshot save xxxxxx.db
# 恢复快照
etcdctl snapshot restore xxxxx.db
# 查看快照状态
etcdctl snapshot status xxxxxx.db
```