# deployment

擅用` -h` 帮助参数

*kubectl run -h*



deployment

````
kubectl scale deployment nginx --replicas=2   deployment 扩容
kubectl set image deployments/nginx nginx=nginx:1.21.6 --record   替换镜像
*kubectl rollout history deployment nginx   查看历史版本 

*kubectl rollout undo deployment nginx --to-revision=2  根据版本号来选择要回滚的版本* 


kubectl create deployment nginx --image=nginx --dry-run -o yaml

apiVersion: apps/v1     # <---  apiVersion 是当前配置格式的版本
kind: Deployment     #<--- kind 是要创建的资源类型，这里是 Deployment
metadata:        #<--- metadata 是该资源的元数据，name 是必需的元数据项
  creationTimestamp: null
  labels:
    app: nginx
  name: nginx
spec:        #<---    spec 部分是该 Deployment 的规格说明
  replicas: 1        #<---  replicas 指明副本数量，默认为 1
  selector:
    matchLabels:
      app: nginx
  strategy: {}
  template:        #<---   template 定义 Pod 的模板，这是配置文件的重要部分
    metadata:        #<---     metadata 定义 Pod 的元数据，至少要定义一个 label。label 的 key 和 value 可以任意指定
      creationTimestamp: null
      labels:
        app: nginx
    spec:           #<---  spec 描述 Pod 的规格，此部分定义 Pod 中每一个容器的属性，name 和 image 是必需的
      containers:
      - image: nginx
        name: nginx
        resources: {}
status: {} 



*kubectl expose deployment new-nginx --port=80 --target-port=80 --dry-run=client -o yaml*

expose deployment new-nginx	暴露 Deployment 资源	为 new-nginx 这个 Deployment 创建 Service	自动生成 ClusterIP 类型的 Service
--port=80	Service 对外端口	Service 监听的端口	客户端访问的端口（集群内/外）
--target-port=80	目标容器端口	Pod 实际暴露的端口	必须与容器内应用端口一致
--dry-run=client	客户端预演模式	仅验证配置，不实际执行	生成配置但不提交到 APIServer
-o yaml	输出格式	以 YAML 格式输出	便于保存为配置文件



deployment快速回滚脚本

```
# kubectl rollout history deployment nginx 
deployment.apps/nginx 
REVISION  CHANGE-CAUSE
1         <none>
3         kubectl set image deployments/nginx nginx=nginx:1.21.5 --record=true
4         kubectl set image deployments/nginx nginx=nginx:1.21.6 --record=true

[root@k8s1 ~]# kubectl rollout history deployment nginx |tail -2
4         kubectl set image deployments/nginx nginx=nginx:1.21.6 --record=true

[root@k8s1 ~]# kubectl rollout history deployment nginx |tail -2 |awk '{print $1}'
4
```


````







service

```
kubectl get svc  查看server
kubetcl get svc -o wide  查看svc

kubectl create service clusterip nginx --tcp=80:80 --dry-run=client -o yaml  尝试运行 生成出来的yaml文件 
```



lables

```
kubectl  get pod -l  app=nginx   查看pod 标签为nginx的
```


kubectl create service clusterip nginx --tcp=80:80









禁止pod调度到该节点上

```
kubectl cordon <node name> --delete-emptydir-data --ignore-daemonsets
```



这些应用的配置和当前服务的状态信息都是保存在ETCD中，执行kubectl get pod等操作时API Server会从ETCD中读取这些数据

calico会为每个pod分配一个ip，但要注意这个ip不是固定的，它会随着pod的重启而发生变化



附：Node管理

禁止pod调度到该节点上

 kubectl cordon <node name> --delete-emptydir-data --ignore-daemonsets

驱逐该节点上的所有pod
kubectl drain <node name>
该命令会删除该节点上的所有Pod（DaemonSet除外），在其他node上重新启动它们，通常该节点需要维护时使用该命令。直接使用该命令会自动调用kubectl cordon <node>命令。当该节点维护完成，启动了kubelet后，再使用kubectl uncordon <node>即可将该节点添加到kubernetes集群中。





kubectl patch services nginx -p'{"spec":{"selector":{"app": "nginxaaa"}}}   批量修改services的标签 





kubectl create configmap localconfig-file --from-file=localconfig-test=localconfig-test.conf --from-file=localconfig-produce=localconfig-produce.conf



kubectl create secret generic mysecret --from-literal=mysql-root-password='BogeMysqlPassword' --from-literal=redis-root-password='BogeRedisPassword' --from-file=my_id_rsa=/root/.ssh/id_rsa --from-file=my_id_rsa_pub=/root/.ssh/id_rsa.pub