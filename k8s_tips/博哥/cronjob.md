###### cronjob

上面的job是一次性任务，那我们需要定时循环来执行一个任务可以嘛？答案肯定是可以的，就像我们在linux系统上面用crontab一样，在K8s上用cronjob的另一个好处就是它是分布式的，执行的pod可以是在集群中的任意一台NODE上面（这点和cronsun有点类似）

让我们开始实战吧，先准备一下cronjob的yaml配置为my-cronjob.yaml


```
apiVersion: batch/v1beta1     # <---------  当前 CronJob 的 apiVersion
kind: CronJob                 # <---------  当前资源的类型
metadata:
  name: hello
spec:
  schedule: "* * * * *"      # <---------  schedule 指定什么时候运行 Job，其格式与 Linux crontab 一致,这里 * * * * * 的含义是每一分钟启动一次
  jobTemplate:               # <---------  定义 Job 的模板，格式与前面 Job 一致
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: registry.cn-shanghai.aliyuncs.com/acs/busybox:v1.29.2
            command: ["echo","boge like cronjob."]
          restartPolicy: OnFailure

```

```
正常创建后，我们过几分钟来看看运行结果
```

```
# 这里会显示cronjob的综合信息
# kubectl get cronjobs.batch 
NAME    SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
hello   * * * * *   False     0        66s             2m20s

# 可以看到它每隔一分钟就会创建一个pod来执行job任务
# kubectl get pod
NAME                     READY   STATUS              RESTARTS   AGE
hello-1610267460-9b6hp   0/1     Completed           0          2m5s
hello-1610267520-fm427   0/1     Completed           0          65s
hello-1610267580-v8g4h   0/1     ContainerCreating   0          5s

# 测试完成后删掉这个资源
# kubectl delete cronjobs.batch hello 
cronjob.batch "hello" deleted

```

