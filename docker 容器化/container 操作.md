镜像导入/导出操作
注意 k8s 只会使用 k8s.io namespace 中镜像。

使用Containerd时，需要往 k8s.io 导入镜像，containerd worker 终于能正常被调度了

为支持多租户隔离，containerd 有 namespace 概念，不同 namespace 下的 image、container 均不同，直接使用 ctr 操作时，会使用 default namespace



```
# ctr namespace ls
NAME   LABELS 
k8s.io

# containerd需要指定命令空间导入镜像
# docker pull nginx:1.21.6 && docker save nginx:1.21.6 > nginx-1.21.6.tar

# ctr -n k8s.io images import nginx-1.21.6.tar



```

containerd导出镜像，然后通过docker导入也是可以的

```
# 先查询要导出的镜像名称全名
# ctr -n k8s.io images ls|grep nginx
docker.io/library/nginx:1.21.6                                                                                                   application/vnd.docker.distribution.manifest.list.v2+json sha256:2bcabc23b45489fb0885d69a06ba1d648aeda973fae7bb981bafbb884165e514 54.1 MiB  linux/386,linux/amd64,linux/arm/v5,linux/arm/v7,linux/arm64/v8,linux/mips64le,linux/ppc64le,linux/s390x io.cri-containerd.image=managed 
docker.io/library/nginx@sha256:2bcabc23b45489fb0885d69a06ba1d648aeda973fae7bb981bafbb884165e514                                  application/vnd.docker.distribution.manifest.list.v2+json sha256:2bcabc23b45489fb0885d69a06ba1d648aeda973fae7bb981bafbb884165e514 54.1 MiB  linux/386,linux/amd64,linux/arm/v5,linux/arm/v7,linux/arm64/v8,linux/mips64le,linux/ppc64le,linux/s390x io.cri-containerd.image=managed 

# 通过ctr导出
# ctr -n k8s.io images export nginx-1.21.6.tar  docker.io/library/nginx:1.21.6
# ll -h nginx-1.21.6.tar 
-rw-r--r-- 1 root root 55M Oct 18 11:51 nginx-1.21.6.tar


# 然后用docker导入
# docker images|grep nginx
# docker load -i nginx-1.21.6.tar
ad6562704f37: Loading layer [==================================================>]  31.38MB/31.38MB
58354abe5f0e: Loading layer [==================================================>]  25.35MB/25.35MB
53ae81198b64: Loading layer [==================================================>]     601B/601B
57d3fc88cb3f: Loading layer [==================================================>]     893B/893B
747b7a567071: Loading layer [==================================================>]     667B/667B
33e3df466e11: Loading layer [==================================================>]  1.396kB/1.396kB
Loaded image: nginx:1.21.6

# docker images|grep nginx       
nginx                                                1.21.6    0e901e68141f   16 months ago   142MB

# docker rmi nginx:1.21.6
Untagged: nginx:1.21.6
Deleted: sha256:0e901e68141fd02f237cf63eb842529f8a9500636a9419e3cf4fb986b8fe3d5d
Deleted: sha256:1e877fb1acf761377390ab38bbad050a1d5296f1b4f51878c2695d4ecdb98c62
Deleted: sha256:834e54d50f731515065370d1c15f0ed47d2f7b6a7b0452646db80f14ace9b8de
Deleted: sha256:d28ca7ee17ff94497071d5c075b4099a4f2c950a3471fc49bdf9876227970b24
Deleted: sha256:096f97ba95539883af393732efac02acdd0e2ae587a5479d97065b64b4eded8c
Deleted: sha256:de7e3b2a7430261fde88313fbf784a63c2229ce369b9116053786845c39058d5
Deleted: sha256:ad6562704f3759fb50f0d3de5f80a38f65a85e709b77fd24491253990f30b6be

```

##### Containerd结合docker一起使用的生产案例：

利用docker in docker (简称dind)，实际在CRI为Containerd的情况下，还能利用docker 实现打包镜像等功能

```
# only have docker client ,use dind can be use normal
dindSvc=$(kubectl -n kube-system get svc dind |awk 'NR==2{print $3}')
export DOCKER_HOST="tcp://${dindSvc}:2375/"
export DOCKER_DRIVER=overlay2
export DOCKER_TLS_CERTDIR=""

```

