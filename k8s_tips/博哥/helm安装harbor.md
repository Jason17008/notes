在生产中安装一般有两种方式，一种是用docker-compose启动官方打包好的离线安装包； 二上用helm chart的形式在k8s上来运行harbor，两种方式都可以用，在21年博哥是推荐用docker-compose来部署，随着时间的推移，helm部署在k8s上也越来越稳定，这次我们就用helm3来部署harbor到k8s集群上面。



说明： 这里安装的harbor使用专属命名空间harbor，并采用了独立部署的redis和postgresql，这样方便横向扩展harbor的资源以便达到更好的效果，目前测试helm和docker-compose安装，helm删除镜像需等待2小时后才会被实际GC清理。

注意：离线镜像可以去离线安装包里获取



在二进制部署k8s时的deploy节点上进行操作，这台节点上部署有docker(server+client)，为什么这么做？因为harbor的所有服务离线镜像都打包在一起，并且格式为tar.gz，实测用Containerd客户端工具ctr无法正常导入

```toml
# 下载harbor离线安装包
wget https://github.com/goharbor/harbor/releases/download/v2.10.0/harbor-offline-installer-v2.10.0.tgz

# 解压
tar zxvf harbor-offline-installer-v2.10.0.tgz

# docker 导入所有离线镜像
cd harbor
docker load -i harbor.v2.10.0.tar.gz

# docker 将harbor每个镜像包独立导出，方便给Containerd导入
docker images|grep harbor|awk -F"[/ ]+" '{print "docker save "$1"/"$2":"$3" > "$2"-"$3".tar"}'|bash
# 镜像 过滤出来 带有harbor的  然后 / 分隔符 print docker save   $1 仓库地址（如 harbor.viperliu.com） $2 镜像名称（如 library/gitlab-ce） $3 标签版本（如 13.8.6-ce.1）
#生成格式示例：docker save harbor.viperliu.com/library/gitlab-ce:13.8.6-ce.1 > library-gitlab-ce-13.8.6-ce.1.tar
#将生成的命令通过管道传递给 bash 执行


#离线安装的话需要这一步 
# 将导出的*.tar离线镜像包复制到需要导入的节点上，使用下面命令批量导入离线镜像包 ##这个后面用 
# for image in `ls -1v /tmp/*.tar`;do ctr -n k8s.io images import $image;done 
```



部署NFS存储及StorageClass

https://blog.csdn.net/weixin_46887489/article/details/134817519



部署Ingress-nginx-controller

https://blog.csdn.net/weixin_46887489/article/details/134586363



#### nfs跟 nginx都要搞通  

```toml
kubectl create ns harbor
```





**harbor-postgresql.yaml**

**里面镜像的话  如果拉不下来的话 要手动拉取的** 



```toml
注释的这些安装好在进行操作 
#psql -U harbordata -h 127.0.0.1 -p 5432 registry -c "create database registry;"
#psql -U harbordata -h 127.0.0.1 -p 5432 registry -c "create database clair;"
#psql -U harbordata -h 127.0.0.1 -p 5432 registry -c "create database notary_server;"
#psql -U harbordata -h 127.0.0.1 -p 5432 registry -c "create database notary_signer;"
#psql -U harbordata -h 127.0.0.1 -p 5432 registry -c "create database harbor_core;"
#psql -U harbordata -h 127.0.0.1 -p 5432 registry -c "\l+"


# backup and restore database
# export PGPASSWORD=registryauthdata ; pg_dump -h 127.0.0.1 -U harbordata -c -C registry -f /tmp/registry_$(date +%y%m%d).sql
# export PGPASSWORD=registryauthdata ; psql -U harbordata -h 127.0.0.1 -p 5432 registry < /tmp/registry_$(date +%y%m%d).sql && rm /tmp/registry_$(date +%y%m%d).sql

# remote ip connect:
#  pip3 install pgcli -i https://mirrors.aliyun.com/pypi/simple
#  export PGPASSWORD=registryauthdata ; psql -h 10.0.0.201 -p 28201 postgres -U postgres -c "\l+"

# delete database and create new database
#  psql -U harbordata -h 127.0.0.1 -p 5432 postgres
#  drop database registry;
#  create database registry with owner harbordata;
#  \l+


# pg web admin
# docker run -p 5050:80 -v /mnt/data/pgadmin:/var/lib/pgadmin -e "PGADMIN_DEFAULT_EMAIL=ops@viperliu.com" -e "PGADMIN_DEFAULT_PASSWORD=viperliu@666" -d dpage/pgadmin4


# pvc
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: harbor-postgresql
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: nfs-viperliu

---
apiVersion: v1
kind: Service
metadata:
  name: harbor-postgresql
  labels:
    app: harbor
    tier: postgresql
spec:
  ports:
    - port: 5432
  selector:
    app: harbor
    tier: postgresql

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: harbor-postgresql
  labels:
    app: harbor
    tier: postgresql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: harbor
      tier: postgresql
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: harbor
        tier: postgresql
    spec:
      #nodeSelector:
      #  gee/disk: "500g"
      initContainers:
        - name: "remove-lost-found"
          image: registry.cn-shanghai.aliyuncs.com/acs/busybox:v1.29.2
          imagePullPolicy: "IfNotPresent"
          command:  ["rm", "-fr", "/var/lib/postgresql/data/lost+found"]
          volumeMounts:
            - name: harbor-postgresqldata
              mountPath: /var/lib/postgresql/data
      containers:
        - image: postgres:13.7-bullseye
          name: harbor-postgresql
          lifecycle:
            postStart:
              exec:
                command:
                  - /bin/sh
                  - -c
                  - echo 'leon'
            preStop:
              exec:
                command: ["/bin/sh", "-c", "sleep 5"]
          env:
            - name: POSTGRES_USER
              value: harbordata
            - name: POSTGRES_DB
              value: registry
            - name: POSTGRES_PASSWORD
              value: registryauthdata
            - name: TZ
              value: Asia/Shanghai
          args:
             - -c
             - shared_buffers=256MB
             - -c
             - max_connections=3000
             - -c
             - work_mem=128MB
          ports:
            - containerPort: 5432
              name: postgresql
          livenessProbe:
            exec:
              command:
              - sh
              - -c
              - exec pg_isready -U harbordata -h 127.0.0.1 -p 5432 -d registry
            initialDelaySeconds: 120
            timeoutSeconds: 5
            failureThreshold: 6
          readinessProbe:
            exec:
              command:
              - sh
              - -c
              - exec pg_isready -U harbordata -h 127.0.0.1 -p 5432 -d registry
            initialDelaySeconds: 20
            timeoutSeconds: 3
            periodSeconds: 5
#          resources:
#            requests:
#              cpu: "4"
#              memory: 8Gi
#            limits:
#              cpu: "4"
#              memory: 8Gi
          volumeMounts:
            - name: harbor-postgresqldata
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: harbor-postgresqldata
          persistentVolumeClaim:
            claimName: harbor-postgresql
kubectl -n harbor apply -f harbor-postgresql.yaml 

看看调度到那个节点上了 然后（离线安装这样 不离线安装的话等会）
docker pull postgres:13.7-bullseye
docker save postgres:13.7-bullseye > postgres-13.7-bullseye.tar
scp postgres-13.7-bullseye.tar  到对应的机器 /tmp目录下

进去目录
ctr -n k8s.io image import /tmp/postgres


然后删除pod 会重新拉取镜像

查看日志 查看容器创建成功即可 


然后进去容器里面 

kubectl -n harbor exec -it $(kubectl -n harbor get pod --no-headers |awk '/^harbor-postgresql/{print $1}') -- bash
#第一条执行的时候 应该报错 这个时候容器的时候已经创建好了

#psql -U harbordata -h 127.0.0.1 -p 5432 registry -c "create database registry;"
#psql -U harbordata -h 127.0.0.1 -p 5432 registry -c "create database clair;"
#psql -U harbordata -h 127.0.0.1 -p 5432 registry -c "create database notary_server;"
#psql -U harbordata -h 127.0.0.1 -p 5432 registry -c "create database notary_signer;"
#psql -U harbordata -h 127.0.0.1 -p 5432 registry -c "create database harbor_core;"
#psql -U harbordata -h 127.0.0.1 -p 5432 registry -c "\l+" 
 ## 查看数据库看看都有没有 
```



**harbor-redis.yaml**

**单点的 可以用生产 监控做好 不会驱逐 也能用**

**进阶的话 就opertar  部署redis集群** 

```toml
---
apiVersion: v1
kind: Service
metadata:
  name: redis-harbor
  labels:
    app: redis-harbor
spec:
  ports:
    - port: 6379
      targetPort: 6379
#      nodePort: 26379
  selector:
    app: redis-harbor
    tier: backend
#  type: NodePort

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-harbor
  labels:
    app: redis-harbor
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis-harbor
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: redis-harbor
        tier: backend
    spec:
      containers:
        - image: redis:6.2.7-alpine3.16
          name: redis-harbor
          command:
            - "redis-server"
          args:
            - "--requirepass"
            - "registryauthdata"
          ports:
            - containerPort: 6379
              name: redis-harbor
          livenessProbe:
            exec:
              command:
              - sh
              - -c
              - "redis-cli ping"
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 5
            successThreshold: 1
            failureThreshold: 3
          readinessProbe:
            exec:
              command:
              - sh
              - -c
              - "redis-cli ping"
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 1
            successThreshold: 1
            failureThreshold: 3
      initContainers:
      - command:
        - /bin/sh
        - -c
        - |
          ulimit -n 65536
          mount -o remount rw /sys
          echo never > /sys/kernel/mm/transparent_hugepage/enabled
          mount -o remount rw /proc/sys
          echo 2000 > /proc/sys/net/core/somaxconn
          echo 1 > /proc/sys/vm/overcommit_memory
        image: registry.cn-shanghai.aliyuncs.com/acs/busybox:v1.29.2
        imagePullPolicy: IfNotPresent
        name: init-redis
        resources: {}
        securityContext:
          privileged: true
          procMount: Default
       # 选择打了label的NODE节点运行，暂时先注释掉，要用的时候再打开
       # kubectl label node 10.0.1.5 cb/harbor-redis-ready=true
       # kubectl get node --show-labels
       # kubectl label node 10.0.1.5 cb/harbor-redis-ready-
      #nodeSelector:
      #  cb/harbor-redis-ready: "true"
```

#### redis

```toml
kubectl -n harbor apply -f harbor-redis.yaml

然后看查看到那个机器上
scp镜像过去 
然后ctr 命令导入 
```



```toml
# 下载helm3
wget https://get.helm.sh/helm-v3.13.1-linux-amd64.tar.gz
tar zxvf helm-v3.13.1-linux-amd64.tar.gz && rm -f helm-v3.13.1-linux-amd64.tar.gz
mv linux-amd64/helm /usr/bin/ && rm -rf ./linux-amd64

# 检测helm3
# which helm
/usr/bin/helm

# helm version
version.BuildInfo{Version:"v3.13.1", GitCommit:"3547a4b5bf5edb5478ce352e18858d8a552a4110", GitTreeState:"clean", GoVersion:"go1.20.8"}

# 配置helm命令补齐功能
echo 'source <(helm completion bash)' >> ~/.bashrc && . ~/.bashrc

# 配置harbor的chart仓库（可选，由于海外网络关系，可直接提前下载好离线chart包安装）
helm repo add harbor https://helm.goharbor.io
helm repo update
helm repo ls
```

#### 部署harbor(采用离线chart包的形式)

```toml
# 下载对应harbor版本的chart离线包
https://github.com/goharbor/harbor-helm ##不好拉取
wget https://codeload.github.com/goharbor/harbor-helm/zip/refs/tags/v1.16.2

# 解压chart包
unzip harbor-helm-main.zip && rm -f harbor-helm-main.zip

# 定制配置（具体修改的地方，可以用文本对比工具对比原始的values.yaml和values-v2.10.0.yaml）
cp harbor-helm-main/values.yaml ./values-v2.10.0.yaml

./values-v2.10.0.yaml 参数在下面 

# 安装（可先模拟安装观察下，接上参数  --dry-run --debug）
helm install -n harbor harbor -f values-v2.10.0.yaml ./harbor-helm-main/ --dry-run --debug
helm install -n harbor harbor -f values-v2.10.0.yaml ./harbor-helm-main/

# 查看安装结果
# helm -n harbor ls
NAME    NAMESPACE       REVISION        UPDATED                                 STATUS  CHART            APP VERSION
harbor  harbor          1               2023-11-06 17:12:55.83193902 +0800 CST  deployedharbor-1.13.1    2.9.1


如果没装好的话  要helm卸载
helm -n harbor uninstall harbor
命名空间下那些资源没被卸载好  手动删除下 主要是pv pcv这些 
kubectl -n harbor get pod

看看调度到那个节点 然后将所有镜像都给scp到那个节点上去 for循环导入 
or image in `ls -1v /tmp/*.tar`;do ctr -n k8s.io images import $image;done

# kubectl -n harbor get pod
NAME                                 READY   STATUS    RESTARTS       AGE
harbor-core-86b7cd96cf-n7k6l         1/1     Running   1 (114m ago)   18h
harbor-jobservice-74c9b6c768-bsmfm   1/1     Running   3 (114m ago)   18h
harbor-portal-7fd8b4ff78-56s6g       1/1     Running   1 (114m ago)   18h
harbor-postgresql-5dddfc6b8c-crtlx   1/1     Running   1 (114m ago)   18h
harbor-registry-c59c99ff4-z4dcx      2/2     Running   2 (114m ago)   18h
harbor-trivy-0                       1/1     Running   1 (114m ago)   18h
redis-harbor-6cdbfddfcf-fdbt8        1/1     Running   1 (114m ago)   18h
```

##### values-v2.10.0.yaml

主要

文本对比下 然后都改成自己的 

```toml
expose:
  # Set how to expose the service. Set the type as "ingress", "clusterIP", "nodePort" or "loadBalancer"
  # and fill the information in the corresponding section
  type: ingress
  tls:
    # Enable TLS or not.
    # Delete the "ssl-redirect" annotations in "expose.ingress.annotations" when TLS is disabled and "expose.type" is "ingress"
    # Note: if the "expose.type" is "ingress" and TLS is disabled,
    # the port must be included in the command when pulling/pushing images.
    # Refer to https://github.com/goharbor/harbor/issues/5291 for details.
    enabled: true
    # The source of the tls certificate. Set as "auto", "secret"
    # or "none" and fill the information in the corresponding section
    # 1) auto: generate the tls certificate automatically
    # 2) secret: read the tls certificate from the specified secret.
    # The tls certificate can be generated manually or by cert manager
    # 3) none: configure no tls certificate for the ingress. If the default
    # tls certificate is configured in the ingress controller, choose this option
    certSource: secret
    auto:
      # The common name used to generate the certificate, it's necessary
      # when the type isn't "ingress"
      commonName: ""
    secret:
      # The name of secret which contains keys named:
      # "tls.crt" - the certificate
      # "tls.key" - the private key
      secretName: "viperliu-com-tls"
  ingress:
    hosts:
      core: harbor.viperliu.com
    # set to the type of ingress controller if it has specific requirements.
    # leave as `default` for most ingress controllers.
    # set to `gce` if using the GCE ingress controller
    # set to `ncp` if using the NCP (NSX-T Container Plugin) ingress controller
    # set to `alb` if using the ALB ingress controller
    # set to `f5-bigip` if using the F5 BIG-IP ingress controller
    controller: default
    ## Allow .Capabilities.KubeVersion.Version to be overridden while creating ingress
    kubeVersionOverride: ""
    className: ""
    annotations:
      # note different ingress controllers may require a different ssl-redirect annotation
      # for Envoy, use ingress.kubernetes.io/force-ssl-redirect: "true" and remove the nginx lines below
      ingress.kubernetes.io/ssl-redirect: "true"
      ingress.kubernetes.io/proxy-body-size: "0"
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/proxy-body-size: "0"
    harbor:
      # harbor ingress-specific annotations
      annotations: {}
      # harbor ingress-specific labels
      labels: {}
  clusterIP:
    # The name of ClusterIP service
    name: harbor
    # The ip address of the ClusterIP service (leave empty for acquiring dynamic ip)
    staticClusterIP: ""
    # Annotations on the ClusterIP service
    annotations: {}
    ports:
      # The service port Harbor listens on when serving HTTP
      httpPort: 80
      # The service port Harbor listens on when serving HTTPS
      httpsPort: 443
  nodePort:
    # The name of NodePort service
    name: harbor
    ports:
      http:
        # The service port Harbor listens on when serving HTTP
        port: 80
        # The node port Harbor listens on when serving HTTP
        nodePort: 30002
      https:
        # The service port Harbor listens on when serving HTTPS
        port: 443
        # The node port Harbor listens on when serving HTTPS
        nodePort: 30003
  loadBalancer:
    # The name of LoadBalancer service
    name: harbor
    # Set the IP if the LoadBalancer supports assigning IP
    IP: ""
    ports:
      # The service port Harbor listens on when serving HTTP
      httpPort: 80
      # The service port Harbor listens on when serving HTTPS
      httpsPort: 443
    annotations: {}
    sourceRanges: []

# The external URL for Harbor core service. It is used to
# 1) populate the docker/helm commands showed on portal
# 2) populate the token service URL returned to docker client
#
# Format: protocol://domain[:port]. Usually:
# 1) if "expose.type" is "ingress", the "domain" should be
# the value of "expose.ingress.hosts.core"
# 2) if "expose.type" is "clusterIP", the "domain" should be
# the value of "expose.clusterIP.name"
# 3) if "expose.type" is "nodePort", the "domain" should be
# the IP address of k8s node
#
# If Harbor is deployed behind the proxy, set it as the URL of proxy
externalURL: https://harbor.viperliu.com

# The internal TLS used for harbor components secure communicating. In order to enable https
# in each component tls cert files need to provided in advance.
internalTLS:
  # If internal TLS enabled
  enabled: false
  # enable strong ssl ciphers (default: false)
  strong_ssl_ciphers: false
  # There are three ways to provide tls
  # 1) "auto" will generate cert automatically
  # 2) "manual" need provide cert file manually in following value
  # 3) "secret" internal certificates from secret
  certSource: "auto"
  # The content of trust ca, only available when `certSource` is "manual"
  trustCa: ""
  # core related cert configuration
  core:
    # secret name for core's tls certs
    secretName: ""
    # Content of core's TLS cert file, only available when `certSource` is "manual"
    crt: ""
    # Content of core's TLS key file, only available when `certSource` is "manual"
    key: ""
  # jobservice related cert configuration
  jobservice:
    # secret name for jobservice's tls certs
    secretName: ""
    # Content of jobservice's TLS key file, only available when `certSource` is "manual"
    crt: ""
    # Content of jobservice's TLS key file, only available when `certSource` is "manual"
    key: ""
  # registry related cert configuration
  registry:
    # secret name for registry's tls certs
    secretName: ""
    # Content of registry's TLS key file, only available when `certSource` is "manual"
    crt: ""
    # Content of registry's TLS key file, only available when `certSource` is "manual"
    key: ""
  # portal related cert configuration
  portal:
    # secret name for portal's tls certs
    secretName: ""
    # Content of portal's TLS key file, only available when `certSource` is "manual"
    crt: ""
    # Content of portal's TLS key file, only available when `certSource` is "manual"
    key: ""
  # trivy related cert configuration
  trivy:
    # secret name for trivy's tls certs
    secretName: ""
    # Content of trivy's TLS key file, only available when `certSource` is "manual"
    crt: ""
    # Content of trivy's TLS key file, only available when `certSource` is "manual"
    key: ""

ipFamily:
  # ipv6Enabled set to true if ipv6 is enabled in cluster, currently it affected the nginx related component
  ipv6:
    enabled: false
  # ipv4Enabled set to true if ipv4 is enabled in cluster, currently it affected the nginx related component
  ipv4:
    enabled: true

# The persistence is enabled by default and a default StorageClass
# is needed in the k8s cluster to provision volumes dynamically.
# Specify another StorageClass in the "storageClass" or set "existingClaim"
# if you already have existing persistent volumes to use
#
# For storing images and charts, you can also use "azure", "gcs", "s3",
# "swift" or "oss". Set it in the "imageChartStorage" section
persistence:
  enabled: true
  # Setting it to "keep" to avoid removing PVCs during a helm delete
  # operation. Leaving it empty will delete PVCs after the chart deleted
  # (this does not apply for PVCs that are created for internal database
  # and redis components, i.e. they are never deleted automatically)
  resourcePolicy: "keep"
  persistentVolumeClaim:
    registry:
      # Use the existing PVC which must be created manually before bound,
      # and specify the "subPath" if the PVC is shared with other components
      existingClaim: ""
      # Specify the "storageClass" used to provision the volume. Or the default
      # StorageClass will be used (the default).
      # Set it to "-" to disable dynamic provisioning
      storageClass: "nfs-viperliu"
      subPath: ""
      accessMode: ReadWriteOnce
      size: 50Gi
      annotations: {}
    jobservice:
      jobLog:
        existingClaim: ""
        storageClass: "nfs-viperliu"
        subPath: ""
        accessMode: ReadWriteOnce
        size: 10Gi
        annotations: {}
    # If external database is used, the following settings for database will
    # be ignored
    database:
      existingClaim: ""
      storageClass: ""
      subPath: ""
      accessMode: ReadWriteOnce
      size: 1Gi
      annotations: {}
    # If external Redis is used, the following settings for Redis will
    # be ignored
    redis:
      existingClaim: ""
      storageClass: ""
      subPath: ""
      accessMode: ReadWriteOnce
      size: 1Gi
      annotations: {}
    trivy:
      existingClaim: ""
      storageClass: "nfs-viperliu"
      subPath: ""
      accessMode: ReadWriteOnce
      size: 5Gi
      annotations: {}
  # Define which storage backend is used for registry to store
  # images and charts. Refer to
  # https://github.com/distribution/distribution/blob/main/docs/configuration.md#storage
  # for the detail.
  imageChartStorage:
    # Specify whether to disable `redirect` for images and chart storage, for
    # backends which not supported it (such as using minio for `s3` storage type), please disable
    # it. To disable redirects, simply set `disableredirect` to `true` instead.
    # Refer to
    # https://github.com/distribution/distribution/blob/main/docs/configuration.md#redirect
    # for the detail.
    disableredirect: false
    # Specify the "caBundleSecretName" if the storage service uses a self-signed certificate.
    # The secret must contain keys named "ca.crt" which will be injected into the trust store
    # of registry's containers.
    # caBundleSecretName:

    # Specify the type of storage: "filesystem", "azure", "gcs", "s3", "swift",
    # "oss" and fill the information needed in the corresponding section. The type
    # must be "filesystem" if you want to use persistent volumes for registry
    type: filesystem
    filesystem:
      rootdirectory: /storage
      #maxthreads: 100
    azure:
      accountname: accountname
      accountkey: base64encodedaccountkey
      container: containername
      #realm: core.windows.net
      # To use existing secret, the key must be AZURE_STORAGE_ACCESS_KEY
      existingSecret: ""
    gcs:
      bucket: bucketname
      # The base64 encoded json file which contains the key
      encodedkey: base64-encoded-json-key-file
      #rootdirectory: /gcs/object/name/prefix
      #chunksize: "5242880"
      # To use existing secret, the key must be GCS_KEY_DATA
      existingSecret: ""
      useWorkloadIdentity: false
    s3:
      # Set an existing secret for S3 accesskey and secretkey
      # keys in the secret should be REGISTRY_STORAGE_S3_ACCESSKEY and REGISTRY_STORAGE_S3_SECRETKEY for registry
      #existingSecret: ""
      region: us-west-1
      bucket: bucketname
      #accesskey: awsaccesskey
      #secretkey: awssecretkey
      #regionendpoint: http://myobjects.local
      #encrypt: false
      #keyid: mykeyid
      #secure: true
      #skipverify: false
      #v4auth: true
      #chunksize: "5242880"
      #rootdirectory: /s3/object/name/prefix
      #storageclass: STANDARD
      #multipartcopychunksize: "33554432"
      #multipartcopymaxconcurrency: 100
      #multipartcopythresholdsize: "33554432"
    swift:
      authurl: https://storage.myprovider.com/v3/auth
      username: username
      password: password
      container: containername
      # keys in existing secret must be REGISTRY_STORAGE_SWIFT_PASSWORD, REGISTRY_STORAGE_SWIFT_SECRETKEY, REGISTRY_STORAGE_SWIFT_ACCESSKEY
      existingSecret: ""
      #region: fr
      #tenant: tenantname
      #tenantid: tenantid
      #domain: domainname
      #domainid: domainid
      #trustid: trustid
      #insecureskipverify: false
      #chunksize: 5M
      #prefix:
      #secretkey: secretkey
      #accesskey: accesskey
      #authversion: 3
      #endpointtype: public
      #tempurlcontainerkey: false
      #tempurlmethods:
    oss:
      accesskeyid: accesskeyid
      accesskeysecret: accesskeysecret
      region: regionname
      bucket: bucketname
      # key in existingSecret must be REGISTRY_STORAGE_OSS_ACCESSKEYSECRET
      existingSecret: ""
      #endpoint: endpoint
      #internal: false
      #encrypt: false
      #secure: true
      #chunksize: 10M
      #rootdirectory: rootdirectory

imagePullPolicy: IfNotPresent

# Use this set to assign a list of default pullSecrets
imagePullSecrets:
#  - name: docker-registry-secret
#  - name: internal-registry-secret

# The update strategy for deployments with persistent volumes(jobservice, registry): "RollingUpdate" or "Recreate"
# Set it as "Recreate" when "RWM" for volumes isn't supported
updateStrategy:
  type: RollingUpdate

# debug, info, warning, error or fatal
logLevel: info

# The initial password of Harbor admin. Change it from portal after launching Harbor
# or give an existing secret for it
# key in secret is given via (default to HARBOR_ADMIN_PASSWORD)
# existingSecretAdminPassword:
existingSecretAdminPasswordKey: HARBOR_ADMIN_PASSWORD
harborAdminPassword: "viperliu@666"

# The name of the secret which contains key named "ca.crt". Setting this enables the
# download link on portal to download the CA certificate when the certificate isn't
# generated automatically
caSecretName: ""

# The secret key used for encryption. Must be a string of 16 chars.
secretKey: "not-a-secure-key"
# If using existingSecretSecretKey, the key must be secretKey
existingSecretSecretKey: ""

# The proxy settings for updating trivy vulnerabilities from the Internet and replicating
# artifacts from/to the registries that cannot be reached directly
proxy:
  httpProxy:
  httpsProxy:
  noProxy: 127.0.0.1,localhost,.local,.internal
  components:
    - core
    - jobservice
    - trivy

# Run the migration job via helm hook
enableMigrateHelmHook: false

# The custom ca bundle secret, the secret must contain key named "ca.crt"
# which will be injected into the trust store for core, jobservice, registry, trivy components
# caBundleSecretName: ""

## UAA Authentication Options
# If you're using UAA for authentication behind a self-signed
# certificate you will need to provide the CA Cert.
# Set uaaSecretName below to provide a pre-created secret that
# contains a base64 encoded CA Certificate named `ca.crt`.
# uaaSecretName:

# If service exposed via "ingress", the Nginx will not be used
nginx:
  image:
    repository: goharbor/nginx-photon
    tag: v2.10.0
  # set the service account to be used, default if left empty
  serviceAccountName: ""
  # mount the service account token
  automountServiceAccountToken: false
  replicas: 1
  revisionHistoryLimit: 10
  # resources:
  #  requests:
  #    memory: 256Mi
  #    cpu: 100m
  extraEnvVars: []
  nodeSelector: {}
  tolerations: []
  affinity: {}
  # Spread Pods across failure-domains like regions, availability zones or nodes
  topologySpreadConstraints: []
  # - maxSkew: 1
  #   topologyKey: topology.kubernetes.io/zone
  #   nodeTaintsPolicy: Honor
  #   whenUnsatisfiable: DoNotSchedule
  ## Additional deployment annotations
  podAnnotations: {}
  ## Additional deployment labels
  podLabels: {}
  ## The priority class to run the pod as
  priorityClassName:

portal:
  image:
    repository: goharbor/harbor-portal
    tag: v2.10.0
  # set the service account to be used, default if left empty
  serviceAccountName: ""
  # mount the service account token
  automountServiceAccountToken: false
  replicas: 1
  revisionHistoryLimit: 10
  # resources:
  #  requests:
  #    memory: 256Mi
  #    cpu: 100m
  extraEnvVars: []
  nodeSelector: {}
  tolerations: []
  affinity: {}
  # Spread Pods across failure-domains like regions, availability zones or nodes
  topologySpreadConstraints: []
  # - maxSkew: 1
  #   topologyKey: topology.kubernetes.io/zone
  #   nodeTaintsPolicy: Honor
  #   whenUnsatisfiable: DoNotSchedule
  ## Additional deployment annotations
  podAnnotations: {}
  ## Additional deployment labels
  podLabels: {}
  ## Additional service annotations
  serviceAnnotations: {}
  ## The priority class to run the pod as
  priorityClassName:

core:
  image:
    repository: goharbor/harbor-core
    tag: v2.10.0
  # set the service account to be used, default if left empty
  serviceAccountName: ""
  # mount the service account token
  automountServiceAccountToken: false
  replicas: 1
  revisionHistoryLimit: 10
  ## Startup probe values
  startupProbe:
    enabled: true
    initialDelaySeconds: 10
  # resources:
  #  requests:
  #    memory: 256Mi
  #    cpu: 100m
  extraEnvVars: []
  nodeSelector: {}
  tolerations: []
  affinity: {}
  # Spread Pods across failure-domains like regions, availability zones or nodes
  topologySpreadConstraints: []
  # - maxSkew: 1
  #   topologyKey: topology.kubernetes.io/zone
  #   nodeTaintsPolicy: Honor
  #   whenUnsatisfiable: DoNotSchedule
  ## Additional deployment annotations
  podAnnotations: {}
  ## Additional deployment labels
  podLabels: {}
  ## Additional service annotations
  serviceAnnotations: {}
  ## User settings configuration json string
  configureUserSettings:
  # The provider for updating project quota(usage), there are 2 options, redis or db.
  # By default it is implemented by db but you can configure it to redis which
  # can improve the performance of high concurrent pushing to the same project,
  # and reduce the database connections spike and occupies.
  # Using redis will bring up some delay for quota usage updation for display, so only
  # suggest switch provider to redis if you were ran into the db connections spike around
  # the scenario of high concurrent pushing to same project, no improvment for other scenes.
  quotaUpdateProvider: db # Or redis
  # Secret is used when core server communicates with other components.
  # If a secret key is not specified, Helm will generate one. Alternatively set existingSecret to use an existing secret
  # Must be a string of 16 chars.
  secret: ""
  # Fill in the name of a kubernetes secret if you want to use your own
  # If using existingSecret, the key must be secret
  existingSecret: ""
  # Fill the name of a kubernetes secret if you want to use your own
  # TLS certificate and private key for token encryption/decryption.
  # The secret must contain keys named:
  # "tls.key" - the private key
  # "tls.crt" - the certificate
  secretName: ""
  # If not specifying a preexisting secret, a secret can be created from tokenKey and tokenCert and used instead.
  # If none of secretName, tokenKey, and tokenCert are specified, an ephemeral key and certificate will be autogenerated.
  # tokenKey and tokenCert must BOTH be set or BOTH unset.
  # The tokenKey value is formatted as a multiline string containing a PEM-encoded RSA key, indented one more than tokenKey on the following line.
  tokenKey: |
  # If tokenKey is set, the value of tokenCert must be set as a PEM-encoded certificate signed by tokenKey, and supplied as a multiline string, indented one more than tokenCert on the following line.
  tokenCert: |
  # The XSRF key. Will be generated automatically if it isn't specified
  xsrfKey: ""
  # If using existingSecret, the key is defined by core.existingXsrfSecretKey
  existingXsrfSecret: ""
  # If using existingSecret, the key
  existingXsrfSecretKey: CSRF_KEY
  ## The priority class to run the pod as
  priorityClassName:
  # The time duration for async update artifact pull_time and repository
  # pull_count, the unit is second. Will be 10 seconds if it isn't set.
  # eg. artifactPullAsyncFlushDuration: 10
  artifactPullAsyncFlushDuration:
  gdpr:
    deleteUser: false

jobservice:
  image:
    repository: goharbor/harbor-jobservice
    tag: v2.10.0
  replicas: 1
  revisionHistoryLimit: 10
  # set the service account to be used, default if left empty
  serviceAccountName: ""
  # mount the service account token
  automountServiceAccountToken: false
  maxJobWorkers: 10
  # The logger for jobs: "file", "database" or "stdout"
  jobLoggers:
    - file
    # - database
    # - stdout
  # The jobLogger sweeper duration (ignored if `jobLogger` is `stdout`)
  loggerSweeperDuration: 14 #days
  notification:
    webhook_job_max_retry: 3
    webhook_job_http_client_timeout: 3 # in seconds
  reaper:
    # the max time to wait for a task to finish, if unfinished after max_update_hours, the task will be mark as error, but the task will continue to run, default value is 24
    max_update_hours: 24
    # the max time for execution in running state without new task created
    max_dangling_hours: 168

  # resources:
  #   requests:
  #     memory: 256Mi
  #     cpu: 100m
  extraEnvVars: []
  nodeSelector: {}
  tolerations: []
  affinity: {}
  # Spread Pods across failure-domains like regions, availability zones or nodes
  topologySpreadConstraints:
  # - maxSkew: 1
  #   topologyKey: topology.kubernetes.io/zone
  #   nodeTaintsPolicy: Honor
  #   whenUnsatisfiable: DoNotSchedule
  ## Additional deployment annotations
  podAnnotations: {}
  ## Additional deployment labels
  podLabels: {}
  # Secret is used when job service communicates with other components.
  # If a secret key is not specified, Helm will generate one.
  # Must be a string of 16 chars.
  secret: ""
  # Use an existing secret resource
  existingSecret: ""
  # Key within the existing secret for the job service secret
  existingSecretKey: JOBSERVICE_SECRET
  ## The priority class to run the pod as
  priorityClassName:

registry:
  # set the service account to be used, default if left empty
  serviceAccountName: ""
  # mount the service account token
  automountServiceAccountToken: false
  registry:
    image:
      repository: goharbor/registry-photon
      tag: v2.10.0
    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
    extraEnvVars: []
  controller:
    image:
      repository: goharbor/harbor-registryctl
      tag: v2.10.0

    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
    extraEnvVars: []
  replicas: 1
  revisionHistoryLimit: 10
  nodeSelector: {}
  tolerations: []
  affinity: {}
  # Spread Pods across failure-domains like regions, availability zones or nodes
  topologySpreadConstraints: []
  # - maxSkew: 1
  #   topologyKey: topology.kubernetes.io/zone
  #   nodeTaintsPolicy: Honor
  #   whenUnsatisfiable: DoNotSchedule
  ## Additional deployment annotations
  podAnnotations: {}
  ## Additional deployment labels
  podLabels: {}
  ## The priority class to run the pod as
  priorityClassName:
  # Secret is used to secure the upload state from client
  # and registry storage backend.
  # See: https://github.com/distribution/distribution/blob/main/docs/configuration.md#http
  # If a secret key is not specified, Helm will generate one.
  # Must be a string of 16 chars.
  secret: ""
  # Use an existing secret resource
  existingSecret: ""
  # Key within the existing secret for the registry service secret
  existingSecretKey: REGISTRY_HTTP_SECRET
  # If true, the registry returns relative URLs in Location headers. The client is responsible for resolving the correct URL.
  relativeurls: false
  credentials:
    username: "harbor_registry_user"
    password: "harbor_registry_password"
    # If using existingSecret, the key must be REGISTRY_PASSWD and REGISTRY_HTPASSWD
    existingSecret: ""
    # Login and password in htpasswd string format. Excludes `registry.credentials.username`  and `registry.credentials.password`. May come in handy when integrating with tools like argocd or flux. This allows the same line to be generated each time the template is rendered, instead of the `htpasswd` function from helm, which generates different lines each time because of the salt.
    # htpasswdString: $apr1$XLefHzeG$Xl4.s00sMSCCcMyJljSZb0 # example string
    htpasswdString: ""
  middleware:
    enabled: false
    type: cloudFront
    cloudFront:
      baseurl: example.cloudfront.net
      keypairid: KEYPAIRID
      duration: 3000s
      ipfilteredby: none
      # The secret key that should be present is CLOUDFRONT_KEY_DATA, which should be the encoded private key
      # that allows access to CloudFront
      privateKeySecret: "my-secret"
  # enable purge _upload directories
  upload_purging:
    enabled: true
    # remove files in _upload directories which exist for a period of time, default is one week.
    age: 168h
    # the interval of the purge operations
    interval: 24h
    dryrun: false

trivy:
  # enabled the flag to enable Trivy scanner
  enabled: true
  image:
    # repository the repository for Trivy adapter image
    repository: goharbor/trivy-adapter-photon
    # tag the tag for Trivy adapter image
    tag: v2.10.0
  # set the service account to be used, default if left empty
  serviceAccountName: ""
  # mount the service account token
  automountServiceAccountToken: false
  # replicas the number of Pod replicas
  replicas: 1
  # debugMode the flag to enable Trivy debug mode with more verbose scanning log
  debugMode: false
  # vulnType a comma-separated list of vulnerability types. Possible values are `os` and `library`.
  vulnType: "os,library"
  # severity a comma-separated list of severities to be checked
  severity: "UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL"
  # ignoreUnfixed the flag to display only fixed vulnerabilities
  ignoreUnfixed: false
  # insecure the flag to skip verifying registry certificate
  insecure: false
  # gitHubToken the GitHub access token to download Trivy DB
  #
  # Trivy DB contains vulnerability information from NVD, Red Hat, and many other upstream vulnerability databases.
  # It is downloaded by Trivy from the GitHub release page https://github.com/aquasecurity/trivy-db/releases and cached
  # in the local file system (`/home/scanner/.cache/trivy/db/trivy.db`). In addition, the database contains the update
  # timestamp so Trivy can detect whether it should download a newer version from the Internet or use the cached one.
  # Currently, the database is updated every 12 hours and published as a new release to GitHub.
  #
  # Anonymous downloads from GitHub are subject to the limit of 60 requests per hour. Normally such rate limit is enough
  # for production operations. If, for any reason, it's not enough, you could increase the rate limit to 5000
  # requests per hour by specifying the GitHub access token. For more details on GitHub rate limiting please consult
  # https://developer.github.com/v3/#rate-limiting
  #
  # You can create a GitHub token by following the instructions in
  # https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line
  gitHubToken: ""
  # skipUpdate the flag to disable Trivy DB downloads from GitHub
  #
  # You might want to set the value of this flag to `true` in test or CI/CD environments to avoid GitHub rate limiting issues.
  # If the value is set to `true` you have to manually download the `trivy.db` file and mount it in the
  # `/home/scanner/.cache/trivy/db/trivy.db` path.
  skipUpdate: false
  # The offlineScan option prevents Trivy from sending API requests to identify dependencies.
  #
  # Scanning JAR files and pom.xml may require Internet access for better detection, but this option tries to avoid it.
  # For example, the offline mode will not try to resolve transitive dependencies in pom.xml when the dependency doesn't
  # exist in the local repositories. It means a number of detected vulnerabilities might be fewer in offline mode.
  # It would work if all the dependencies are in local.
  # This option doesn’t affect DB download. You need to specify skipUpdate as well as offlineScan in an air-gapped environment.
  offlineScan: false
  # Comma-separated list of what security issues to detect. Possible values are `vuln`, `config` and `secret`. Defaults to `vuln`.
  securityCheck: "vuln"
  # The duration to wait for scan completion
  timeout: 5m0s
  resources:
    requests:
      cpu: 200m
      memory: 512Mi
    limits:
      cpu: 1
      memory: 1Gi
  extraEnvVars: []
  nodeSelector: {}
  tolerations: []
  affinity: {}
  # Spread Pods across failure-domains like regions, availability zones or nodes
  topologySpreadConstraints: []
  # - maxSkew: 1
  #   topologyKey: topology.kubernetes.io/zone
  #   nodeTaintsPolicy: Honor
  #   whenUnsatisfiable: DoNotSchedule
  ## Additional deployment annotations
  podAnnotations: {}
  ## Additional deployment labels
  podLabels: {}
  ## The priority class to run the pod as
  priorityClassName:

database:
  # if external database is used, set "type" to "external"
  # and fill the connection information in "external" section
  type: external
  internal:
    # set the service account to be used, default if left empty
    serviceAccountName: ""
    # mount the service account token
    automountServiceAccountToken: false
    image:
      repository: goharbor/harbor-db
      tag: v2.10.0
    # The initial superuser password for internal database
    password: "changeit"
    # The size limit for Shared memory, pgSQL use it for shared_buffer
    # More details see:
    # https://github.com/goharbor/harbor/issues/15034
    shmSizeLimit: 512Mi
    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
    # The timeout used in livenessProbe; 1 to 5 seconds
    livenessProbe:
      timeoutSeconds: 1
    # The timeout used in readinessProbe; 1 to 5 seconds
    readinessProbe:
      timeoutSeconds: 1
    extraEnvVars: []
    nodeSelector: {}
    tolerations: []
    affinity: {}
    ## The priority class to run the pod as
    priorityClassName:
    initContainer:
      migrator: {}
      # resources:
      #  requests:
      #    memory: 128Mi
      #    cpu: 100m
      permissions: {}
      # resources:
      #  requests:
      #    memory: 128Mi
      #    cpu: 100m
  external:
    host: "harbor-postgresql.harbor.svc.cluster.local"
    port: "5432"
    username: "harbordata"
    password: "registryauthdata"
    coreDatabase: "harbor_core"
    clairDatabase: "clair"
    # if using existing secret, the key must be "password"
    existingSecret: ""
    # "disable" - No SSL
    # "require" - Always SSL (skip verification)
    # "verify-ca" - Always SSL (verify that the certificate presented by the
    # server was signed by a trusted CA)
    # "verify-full" - Always SSL (verify that the certification presented by the
    # server was signed by a trusted CA and the server host name matches the one
    # in the certificate)
    sslmode: "disable"
  # The maximum number of connections in the idle connection pool per pod (core+exporter).
  # If it <=0, no idle connections are retained.
  maxIdleConns: 100
  # The maximum number of open connections to the database per pod (core+exporter).
  # If it <= 0, then there is no limit on the number of open connections.
  # Note: the default number of connections is 1024 for postgre of harbor.
  maxOpenConns: 900
  ## Additional deployment annotations
  podAnnotations: {}
  ## Additional deployment labels
  podLabels: {}

redis:
  # if external Redis is used, set "type" to "external"
  # and fill the connection information in "external" section
  type: external
  internal:
    # set the service account to be used, default if left empty
    serviceAccountName: ""
    # mount the service account token
    automountServiceAccountToken: false
    image:
      repository: goharbor/redis-photon
      tag: v2.10.0
    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
    extraEnvVars: []
    nodeSelector: {}
    tolerations: []
    affinity: {}
    ## The priority class to run the pod as
    priorityClassName:
    # # jobserviceDatabaseIndex defaults to "1"
    # # registryDatabaseIndex defaults to "2"
    # # trivyAdapterIndex defaults to "5"
    # # harborDatabaseIndex defaults to "0", but it can be configured to "6", this config is optional
    # # cacheLayerDatabaseIndex defaults to "0", but it can be configured to "7", this config is optional
    jobserviceDatabaseIndex: "1"
    registryDatabaseIndex: "2"
    trivyAdapterIndex: "5"
    # harborDatabaseIndex: "6"
    # cacheLayerDatabaseIndex: "7"
  external:
    # support redis, redis+sentinel
    # addr for redis: <host_redis>:<port_redis>
    # addr for redis+sentinel: <host_sentinel1>:<port_sentinel1>,<host_sentinel2>:<port_sentinel2>,<host_sentinel3>:<port_sentinel3>
    addr: "redis-harbor.harbor.svc.cluster.local:6379"
    # The name of the set of Redis instances to monitor, it must be set to support redis+sentinel
    sentinelMasterSet: ""
    # The "coreDatabaseIndex" must be "0" as the library Harbor
    # used doesn't support configuring it
    # harborDatabaseIndex defaults to "0", but it can be configured to "6", this config is optional
    # cacheLayerDatabaseIndex defaults to "0", but it can be configured to "7", this config is optional
    coreDatabaseIndex: "0"
    jobserviceDatabaseIndex: "1"
    registryDatabaseIndex: "2"
    trivyAdapterIndex: "5"
    # harborDatabaseIndex: "6"
    # cacheLayerDatabaseIndex: "7"
    # username field can be an empty string, and it will be authenticated against the default user
    username: ""
    password: "registryauthdata"
    # If using existingSecret, the key must be REDIS_PASSWORD
    existingSecret: ""
  ## Additional deployment annotations
  podAnnotations: {}
  ## Additional deployment labels
  podLabels: {}

exporter:
  replicas: 1
  revisionHistoryLimit: 10
  # resources:
  #  requests:
  #    memory: 256Mi
  #    cpu: 100m
  extraEnvVars: []
  podAnnotations: {}
  ## Additional deployment labels
  podLabels: {}
  serviceAccountName: ""
  # mount the service account token
  automountServiceAccountToken: false
  image:
    repository: goharbor/harbor-exporter
    tag: v2.10.0
  nodeSelector: {}
  tolerations: []
  affinity: {}
  # Spread Pods across failure-domains like regions, availability zones or nodes
  topologySpreadConstraints: []
  # - maxSkew: 1
  #   topologyKey: topology.kubernetes.io/zone
  #   nodeTaintsPolicy: Honor
  #   whenUnsatisfiable: DoNotSchedule
  cacheDuration: 23
  cacheCleanInterval: 14400
  ## The priority class to run the pod as
  priorityClassName:

metrics:
  enabled: false
  core:
    path: /metrics
    port: 8001
  registry:
    path: /metrics
    port: 8001
  jobservice:
    path: /metrics
    port: 8001
  exporter:
    path: /metrics
    port: 8001
  ## Create prometheus serviceMonitor to scrape harbor metrics.
  ## This requires the monitoring.coreos.com/v1 CRD. Please see
  ## https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/getting-started.md
  ##
  serviceMonitor:
    enabled: false
    additionalLabels: {}
    # Scrape interval. If not set, the Prometheus default scrape interval is used.
    interval: ""
    # Metric relabel configs to apply to samples before ingestion.
    metricRelabelings:
      []
      # - action: keep
      #   regex: 'kube_(daemonset|deployment|pod|namespace|node|statefulset).+'
      #   sourceLabels: [__name__]
    # Relabel configs to apply to samples before ingestion.
    relabelings:
      []
      # - sourceLabels: [__meta_kubernetes_pod_node_name]
      #   separator: ;
      #   regex: ^(.*)$
      #   targetLabel: nodename
      #   replacement: $1
      #   action: replace

trace:
  enabled: false
  # trace provider: jaeger or otel
  # jaeger should be 1.26+
  provider: jaeger
  # set sample_rate to 1 if you wanna sampling 100% of trace data; set 0.5 if you wanna sampling 50% of trace data, and so forth
  sample_rate: 1
  # namespace used to differentiate different harbor services
  # namespace:
  # attributes is a key value dict contains user defined attributes used to initialize trace provider
  # attributes:
  #   application: harbor
  jaeger:
    # jaeger supports two modes:
    #   collector mode(uncomment endpoint and uncomment username, password if needed)
    #   agent mode(uncomment agent_host and agent_port)
    endpoint: http://hostname:14268/api/traces
    # username:
    # password:
    # agent_host: hostname
    # export trace data by jaeger.thrift in compact mode
    # agent_port: 6831
  otel:
    endpoint: hostname:4318
    url_path: /v1/traces
    compression: false
    insecure: true
    # timeout is in seconds
    timeout: 10

# cache layer configurations
# if this feature enabled, harbor will cache the resource
# `project/project_metadata/repository/artifact/manifest` in the redis
# which help to improve the performance of high concurrent pulling manifest.
cache:
  # default is not enabled.
  enabled: false
  # default keep cache for one day.
  expireHours: 24
```





##### harbor的https访问配置

默认情况下，Harbor 不附带证书。可以在没有安全性的情况下部署 Harbor，以便您可以通过 HTTP 连接到它。但是，只有在没有连接到外部 Internet 的气隙测试或开发环境中才可以使用 HTTP。在非气隙环境中使用 HTTP 会使您遭受中间人攻击。在生产环境中，始终使用 HTTPS。如果您启用 Content Trust with Notary 来正确签署所有图像，则必须使用 HTTPS。



要配置 HTTPS，您必须创建 SSL 证书。您可以使用由受信任的第三方 CA 签名的证书，也可以使用自签名证书。本节介绍如何使用 OpenSSL创建 CA，以及如何使用 CA 签署服务器证书和客户端证书。您可以使用其他 CA 提供商，例如 Let’s Encrypt。



以下过程假设您的 Harbor 注册表的主机名是viperliu.com，并且其 DNS 记录指向您运行 Harbor 的主机。





在生产环境中，您应该从 CA 获取证书。在测试或开发环境中，您可以生成自己的CA。要生成 CA 证书，请运行以下命令

生成 CA 证书私钥。

```plain
openssl genrsa -out ca.key 4096
```

生成 CA 证书。



调整选项中的值-subj以反映您的组织。如果您使用 FQDN 连接 Harbor 主机，则必须将其指定为公用名 ( CN) 属性。

```toml
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=viperliu.com" \
 -key ca.key \
 -out ca.crt

 
```

###### 生成服务器证书

证书通常包含一个`.crt`文件和一个`.key`文件，例如`viperliu.com.crt`和`viperliu.com.key`。



生成私钥。

```toml
openssl genrsa -out viperliu.com.key 4096
```

生成证书签名请求 (CSR)。

调整选项中的值`-subj`以反映您的组织。如果您使用 FQDN 连接 Harbor 主机，则必须将其指定为公用名 ( `CN`) 属性，并在密钥和 CSR 文件名中使用它

```toml
openssl req -sha512 -new \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=viperliu.com" \
    -key viperliu.com.key \
    -out viperliu.com.csr
```

生成 x509 v3 扩展文件。

无论您是使用 FQDN 还是 IP 地址连接到 Harbor 主机，都必须创建此文件，以便可以为 Harbor 主机生成符合主题备用名称 (SAN) 和 x509 v3 的证书扩展要求。替换`DNS`条目以反映您的域。

```toml
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=viperliu.com
DNS.2=viperliu
DNS.3=harbor.viperliu.com
EOF
```

使用该`v3.ext`文件为您的 Harbor 主机生成证书。

`viperliu.com`将CSR 和 CRT 文件名中的替换为 Harbor 主机名。

```toml
openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in viperliu.com.csr \
    -out viperliu.com.crt
```

**向 Docker 提供证书**

**生成ca.crt、viperliu.com.crt、 和viperliu.com.key文件后，您必须将它们提供给 Harbor 和 Docker，并重新配置 Harbor 以使用它们。**



**转换viperliu.com.crt为viperliu.com.cert, 供 Docker 使用。**



**Docker 守护进程将.crt文件解释为 CA 证书，.cert将文件解释为客户端证书。**

```toml
openssl x509 -inform PEM -in viperliu.com.crt -out viperliu.com.cert
```

将服务器证书、密钥和 CA 文件复制到 Harbor 主机上的 Docker 证书文件夹中。您必须首先创建适当的文件夹。

```toml
mkdir -p /etc/docker/certs.d/harbor.viperliu.com
cp viperliu.com.cert /etc/docker/certs.d/harbor.viperliu.com/
cp viperliu.com.key /etc/docker/certs.d/harbor.viperliu.com/
cp ca.crt /etc/docker/certs.d/harbor.viperliu.com/
```

重新启动 Docker 引擎。

```toml
systemctl restart docker
harbor安全配置
# 修改默认的管理员用户名admin为viperliu
kubectl -n harbor exec -it $(kubectl -n harbor get pod --no-headers |awk '/harbor-postgres/{print $1}') -- bash

psql -U harbordata -h 127.0.0.1 -p 5432  harbor_core

select * from harbor_user;

update harbor_user set username='viperliu' where user_id=1;
```



这些做好之后 在在上面做拉取push的docker操作 

```toml
# 在k8s上生成tls secret
kubectl -n harbor create secret tls viperliu-com-tls --cert=viperliu.com.crt --key=viperliu.com.key

# 在k8s上生成harbor私有镜像仓库的secret
kubectl -n harbor create secret docker-registry harbor --docker-server=harbor.viperliu.com --docker-username=viperliu --docker-password=viperliu@666 --docker-email=ops@viperliu.com
kubectl -n harbor create secret docker-registry harbor --docker-server=harbor.viperliu.com --docker-username=viperliu --docker-password=viperliu@666 --docker-email=ops@viperliu.com
# ***注意：因为我们测试是用的自签证书，并且容器运行时是Containerd，为了能让k8s能正常摘取镜像，我们需要在 Containerd 中禁用证书验证
# k8s集群中能调度pod的node上都需要操作

# 先配置好本地hosts
10.0.1.201 harbor.viperliu.com

# 登陆harbor后台，创建一个私有仓库 product
https://harbor.viperliu.com/

# 在带有docker(server+client)的deploy机器上操作
docker login harbor.viperliu.com -u viperliu
docker pull registry.cn-shanghai.aliyuncs.com/acs/busybox:v1.29.2
docker tag registry.cn-shanghai.aliyuncs.com/acs/busybox:v1.29.2 harbor.viperliu.com/product/busybox:v1.29.2
docker push harbor.viperliu.com/product/busybox:v1.29.2

# 编辑本地hosts
# vim /etc/hosts
10.0.1.201    easzlab.io.local  harbor.viperliu.com

# 编辑 Containerd的配置，在 Containerd 中禁用证书验证
# vim /etc/containerd/config.toml，找到这行配置`[plugins."io.containerd.grpc.v1.cri".registry.configs]`，在它下面添加
      [plugins."io.containerd.grpc.v1.cri".registry.configs]
# 这下面两行是我们需要添加的新内容
        [plugins."io.containerd.grpc.v1.cri".registry.configs."harbor.viperliu.com".tls]
          insecure_skip_verify = true


# 然后重启该节点的的 Containerd
# systemctl restart containerd
# systemctl status containerd


# 在k8s上部署测试服务
kubectl -n harbor apply -f test.yaml
```









  test.yaml

kubectl -n harbor apply -f test.yaml

```toml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: busybox
  name: busybox
spec:
  replicas: 1
  selector:
    matchLabels:
      app: busybox
  strategy: {}
  template:
    metadata:
      labels:
        app: busybox
    spec:
      containers:
      - image: harbor.viperliu.com/product/busybox:v1.29.2
        name: busybox
        args:
        - /bin/sh
        - -c
        - >
           while :; do
             echo "[$(date +%F\ %T)] ${MY_POD_NAMESPACE}-${MY_POD_NAME}-${MY_POD_IP}"
             sleep 1
           done
        env:
          - name: TZ
            value: Asia/Shanghai
          - name: MY_POD_NAME
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: metadata.name
          - name: MY_POD_NAMESPACE
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: metadata.namespace
          - name: MY_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
        resources: {}
      hostAliases:
      - hostnames:
        - harbor.viperliu.com
        ip: 10.0.1.201
      imagePullSecrets:
      - name: harbor

调度到那个机器上  去那个机器上家host文件的解析 
```