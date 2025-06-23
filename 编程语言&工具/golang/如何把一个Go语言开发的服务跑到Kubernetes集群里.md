### 准备镜像

1. 准备一台装好了Docker的Linux主机
2. 安装go编译器

```
#帽子系列
 yum install golang -y
```

1. 一个Gin的示例项目，创建`main.go`

```
package main
 
 import (
     "fmt"
     "github.com/gin-gonic/gin"
     "io"
     "net/http"
     "os"
 )
 
 func main()  {
     //日志输出配置，容器方式运行，打控制台
     gin.DefaultWriter = io.MultiWriter(os.Stdout)
 
     r := gin.New()
 
     //定义日志输出格式
     r.Use(gin.LoggerWithFormatter(func(params gin.LogFormatterParams) string {
         return fmt.Sprintf("{\"@timestamp\": \"%s\", \"remote_addr\": \"%s\", \"method\": \"%s\", \"path\": \"%s\", \"protocol\": \"%s\", \"status\": \"%d\", \"time\": \"%s\", \"emsg\": \"%s\", \"body_size\": \"%d\", \"ua\": \"%s\"}\n",
             //ISO8601
             params.TimeStamp.Format("2006-01-02T15:04:05+08"),
             params.ClientIP,
             params.Method,
             params.Path,
             params.Request.Proto,
             params.StatusCode,
             params.Latency,
             params.ErrorMessage,
             params.BodySize,
             params.Request.UserAgent(),
         )
     }))
 
     //测试日志输出
     r.GET("/log", func(c *gin.Context) {
         c.JSON(http.StatusOK, gin.H{
             "status": "200",
         })
     })
 
     r.Run(":8080")
 }
```

处理、安装依赖包，执行这个命令

```
#如果代码里没有go.mod这个文件，使用gomod模式则需要执行这个命令
 go mod init main.go
```

编译

 go build main.go

1. 准备Dockerfile，所有的go语言实现的模块都可以套用该模板，该文件命名必须为`Dockerfile`，将其放到编译好的二进制文件的位置(也就是main那里)

```
#注意我这里构建镜像的主机是centos7 amd64的，代码将来运行的环境也是centos7 amd64
 #如果有其它os或体系架构，你需要制作一个通用的底层镜像
 FROM hub-sh.aixxxx.com/base/centos:7
 #RUN yum install epel-release -y&&\
 #    yum makecache && \
 #    yum install golang -y &&\
 #    go version
 # ENV用于注入一些环境变量信息，这里的值可以在Kubernetes中被env关键字覆盖
 ENV GIN_MODE=release
 ADD main /usr/local/bin/app
 EXPOSE 8080:8080
 CMD ["app"]
```

1. 编译、推送镜像到仓库

```
# 编译镜像
 docker build -t hub-sh.aixxxx.com/{your_project}/xxxxxx:v1.0.0 .
 # 推送到仓库
 docker push hub-sh.aixxxx.com/{your_project}/xxxxxx:v1.0.0
```

### 部署无状态应用

你需要有一个可以做实验的Kubernetes集群

1. 我们以经典的Deployment为例，创建service.yaml这个文件

```
---
 apiVersion: v1
 kind: Service
 metadata:
   name: goservice
 spec:
   type: NodePort
   ports:
     - name: http
       port: 8080
       targetPort: 8080
   selector:
     app: goservice
 
 ---
 apiVersion: apps/v1
 kind: Deployment
 metadata:
   name: goservice
 spec:
   # 副本数量
   replicas: 2
   # 升级策略
   strategy:
     rollingUpdate:
       # 最大允许不可用数量
       maxUnavailable: 25%
       # 最大激增
       maxSurge: 25%
   selector:
     matchLabels:
       app: goservice
   template:
     metadata:
       labels:
         app: goservice
     spec:
     # 容器时区如果不对的话请挂载宿主机这个文件到容器内部
       volumes:
         - name: local-time
           hostPath:
             path: /etc/localtime
       containers:
         - name: goservice
           # 根据自己的镜像位置修改
           image: hub-sh.aixxxx.com/kevinzhu/goservice:v1.0.0
           # CST
           volumeMounts:
             - mountPath: /etc/localtime
               name: local-time
           ports:
             - containerPort: 8080
               protocol: TCP
           env:
             # 生产环境请使用release
             - name: GIN_MODE
               value: debug
             - name: PROFILES
               value: "test"
           # 资源限制
           resources:
             limits:
               cpu: 1000m
               memory: 2Gi
             requests:
               cpu: 800m
               memory: 1Gi
           # ready探针，流量是否可以进去
           readinessProbe:
             tcpSocket:
               port: 8080
             periodSeconds: 20
             initialDelaySeconds: 30
           # 可用性探针
           livenessProbe:
             tcpSocket:
               port: 8080
             periodSeconds: 35
             initialDelaySeconds: 40
       restartPolicy: Always
       imagePullSecrets:
         - name: default-secret
```

部署到集群

1.  kubectl apply -f service.yaml
2. 获取部署状态

```
# 获取Pod
 kubectl get po
 # 获取svc，拿到nodeport方式访问服务的入口
 kubectl get svc/goservice -o wide
```