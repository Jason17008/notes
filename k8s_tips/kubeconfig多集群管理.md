获取所有集群的kubeconfig 文件

创建一个新的目录 

k8sconfige 

cp /root/.kube/config .

scp  /root/.kube/config    .

将所有的目录  

这个时候 在1台主机上 通过kubetctl 然后指定不通的config文件 可以查看资源 

如果报错x509   那么就是config文件里面的server 不对 可以查看修改下 



合并config文件 

```plain
配置1的前面  
从apiversion 到name
然后修改name

然后配置2的
-culster
name 复制到这个文件中 
name修改名字 

然后复制安全上下文
修改里面的cluster  和user name 


然后复制confige
也是修改里面对应的名字 
```

合并之后的话  可以通过

kubectl  --kubeconfig=config12 config  get-clusters  可以查看自己可以对那个集群做管理 

kubectl --kubeconfig=config12  confige  get-context  可以查看自己当前在那个集群的上下文 

kubectl --kubeconfig=config12  confige  use-context  上下名字   可以切换上下文 





# 自动合并k8s kubeconfig文件  前提要修改confige文件

server的地址修改  

name 名字修改

cluster  user  name   都修改

current-contex  都修改



所有的配置文件都修改之后

kubeconfig=./confige :/confige2 kubectl confige view --flatten >./configeX





# kubectx 上下文切换

github 找到   二进制下载

chmod +x    移动目录到/usr/local/bin

然后把生成的出来的配置文件  放到/root/.kube/config



这个实际上使用没有kubeecm可以 