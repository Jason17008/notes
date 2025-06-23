https://blog.csdn.net/weixin_46887489/article/details/135004432?spm=1001.2014.3001.5502





```
# 用任何你熟悉的开发语言，创建一个可执行的文件，可以是二进制文件，也可以是脚本
# 注意可执行文件的名称前面要以 "kubectl-"  开头，例如："kubectl-hello"
cat ./kubectl-hello
#!/bin/bash

echo "hello world"

# 给文件添加可执行权限
chmod +x ./kubectl-hello

# 移动文件到系统默认的可执行目录 PATH
sudo mv ./kubectl-hello /usr/local/bin

# 这样我们就安装好了一个 kubectl 插件.
# 查看可用的所有插件`kubectl`，我们可以使用`kubectl plugin list`子命令：
kubectl plugin list

# 执行相应的插件
kubectl hello

"hello world"

```





```
# 要卸载一个插件，我们只需要直接删除这个可执行文件即可
sudo rm /usr/local/bin/kubectl-hello

```



手写一个k8s节点事件查看的插件：

```
# cat ./kubectl-nodeck 
#!/bin/bash

check_k8s_resource(){
for ip in `kubectl get node|grep -wv SchedulingDisabled|awk 'NR!=1{print $1}'`;do echo "============================ [ $ip ] ============================";kubectl describe node $ip|tail -7;done
}

check_k8s_resource

# chmod +x ./kubectl-nodeck 
# mv ./kubectl-nodeck /usr/local/bin/
# kubectl plugin list
The following compatible plugins are available:

/usr/local/bin/kubectl-nodeck

# kubectl nodeck
============================ [ 10.0.0.224 ] ============================
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests     Limits
  --------           --------     ------
  cpu                562m (7%)    420m (5%)
  memory             966Mi (12%)  1186Mi (15%)
  ephemeral-storage  0 (0%)       0 (0%)
Events:              <none>
......省略

```

# 一个开源的kubectl插件管理工具

https://krew.sigs.k8s.io/