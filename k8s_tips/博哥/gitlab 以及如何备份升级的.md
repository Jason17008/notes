（一）

讲 cicd 架构



以及云上 线下自建机房如何操作



k8s 增加节点  k8s减少节点  以及二进制升级版本 





（二）

开始安装 

```toml
# ------------------------------------------------
#  mkdir -p /nfs_dir/{gitlab_etc_ver130806,gitlab_log_ver130806,gitlab_opt_ver130806,gitlab_postgresql_data_ver130806}
#  kubectl create namespace gitlab-ver130806
#  kubectl -n gitlab-ver130806 apply -f 3postgres.yaml
#  kubectl -n gitlab-ver130806 apply -f 4redis.yaml
#  kubectl -n gitlab-ver130806 apply -f 5gitlab.yaml
#  kubectl -n gitlab-ver130806 apply -f 6gitlab-tls.yaml
# ------------------------------------------------
```



3postgres.yaml

```toml
# pv
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gitlab-postgresql-data-ver130806
  labels:
    type: gitlab-postgresql-data-ver130806
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs-viperliu
  nfs:
    path: /nfs_dir/gitlab_postgresql_data_ver130806
    server: 172.16.15.111

# pvc
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: gitlab-postgresql-data-ver130806-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs-viperliu
  selector:
    matchLabels:
      type: gitlab-postgresql-data-ver130806
---
apiVersion: v1
kind: Service
metadata:
  name: postgresql
  labels:
    app: gitlab
    tier: postgreSQL
spec:
  ports:
    - port: 5432
  selector:
    app: gitlab
    tier: postgreSQL

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgresql
  labels:
    app: gitlab
    tier: postgreSQL
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gitlab
      tier: postgreSQL
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: gitlab
        tier: postgreSQL
    spec:
      #nodeSelector:
      #  gee/disk: "500g"
      containers:
        - image: postgres:12.6-alpine
        #- image: harbor.viperliu.com/library/postgres:12.6-alpine
          name: postgresql
          env:
            - name: POSTGRES_USER
              value: gitlab
            - name: POSTGRES_DB
              value: gitlabhq_production
            - name: POSTGRES_PASSWORD
              value: viperliuusepg
            - name: TZ
              value: Asia/Shanghai
          ports:
            - containerPort: 5432
              name: postgresql
          livenessProbe:
            exec:
              command:
              - sh
              - -c
              - exec pg_isready -U gitlab -h 127.0.0.1 -p 5432 -d gitlabhq_production
            initialDelaySeconds: 110
            timeoutSeconds: 5
            failureThreshold: 6
          readinessProbe:
            exec:
              command:
              - sh
              - -c
              - exec pg_isready -U gitlab -h 127.0.0.1 -p 5432 -d gitlabhq_production
            initialDelaySeconds: 20
            timeoutSeconds: 3
            periodSeconds: 5
#          resources:
#            requests:
#              cpu: 100m
#              memory: 512Mi
#            limits:
#              cpu: "1"
#              memory: 1Gi
          volumeMounts:
            - name: postgresql
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: postgresql
          persistentVolumeClaim:
            claimName: gitlab-postgresql-data-ver130806-pvc
```

kubectl -n gitlab-ver130806 apply -f 3postgres.yaml



4redis.yaml

redis没做数据持久化  要用的话坐下

```toml
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  labels:
    app: gitlab
    tier: backend
spec:
  ports:
    - port: 6379
      targetPort: 6379
  selector:
    app: gitlab
    tier: backend
---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  labels:
    app: gitlab
    tier: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gitlab
      tier: backend
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: gitlab
        tier: backend
    spec:
      #nodeSelector:
      #  gee/disk: "500g"
      containers:
        - image: redis:6.2.0-alpine3.13
        #- image: harbor.viperliu.com/library/redis:6.2.0-alpine3.13
          name: redis
          command:
            - "redis-server"
          args:
            - "--requirepass"
            - "viperliuuseredis"
#          resources:
#            requests:
#              cpu: "1"
#              memory: 2Gi
#            limits:
#              cpu: "1"
#              memory: 2Gi
          ports:
            - containerPort: 6379
              name: redis
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
        image: registry.cn-beijing.aliyuncs.com/acs/busybox:v1.29.2
        imagePullPolicy: IfNotPresent
        name: init-redis
        resources: {}
        securityContext:
          privileged: true
          procMount: Default
```

kubectl -n gitlab-ver130806 apply -f 4redis.yaml



（三）

gitlab

打包镜像的时候报错

Dockerfile

```toml
Dockerfile
FROM gitlab/gitlab-ce:13.8.6-ce.0

# 1. 配置阿里云Ubuntu源（覆盖默认源）
RUN echo "deb http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse\n\
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse\n\
deb http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse" > /etc/apt/sources.list

# 2. 使用PostgreSQL官方存档仓库（兼容Xenial）
RUN echo "deb http://apt-archive.postgresql.org/pub/repos/apt xenial-pgdg main" > /etc/apt/sources.list.d/pgdg-archive.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# 3. 安装工具和PostgreSQL客户端
RUN apt-get update -yq && \
    apt-get install -y \
    vim \
    iproute2 \
    net-tools \
    iputils-ping \
    curl \
    wget \
    postgresql-client-12 && \
    rm -rf /var/lib/apt/lists/*

# 4. 链接pg_dump到GitLab嵌入式目录
RUN ln -sf /usr/bin/pg_dump /opt/gitlab/embedded/bin/pg_dump


#docker build -t gitlab/gitlab-ce:13.8.6-ce.1 .
```



gitlab部署

5gitlab.yaml

gitlab 的安装 自建注意下 安装的步骤 参数 

邮箱换成自己的  暴漏的url也换成自己的

镜像替换一下 

docker tag gitlab/gitlab-ce:13.8.6-ce.0 harbor.viperliu.com/library/gitlab-ce:13.8.6-ce.1

docker login harbor.viperliu.com -u viperliu

docker push harbor.viperliu.com/library/gitlab-ce:13.8.6-ce.1



```toml
# restore gitlab data command example:
#   kubectl -n gitlab-ver130806 exec -it $(kubectl -n gitlab-ver130806 get pod|grep -v runner|grep gitlab|awk '{print $1}') -- gitlab-rake gitlab:backup:restore BACKUP=1602889879_2020_10_17_12.9.2
#   kubectl -n gitlab-ver130806 exec -it $(kubectl -n gitlab-ver130806 get pod|grep -v runner|grep gitlab|awk '{print $1}') -- gitlab-ctl reconfigure
#   kubectl -n gitlab-ver130806 exec -it $(kubectl -n gitlab-ver130806 get pod|grep -v runner|grep gitlab|awk '{print $1}') -- gitlab-ctl status

# pv
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gitlab-etc-ver130806
  labels:
    type: gitlab-etc-ver130806
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs-viperliu
  nfs:
    path: /nfs_dir/gitlab_etc_ver130806
    server: 172.16.15.111

# pvc
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: gitlab-etc-ver130806-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs-viperliu
  selector:
    matchLabels:
      type: gitlab-etc-ver130806
# pv
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gitlab-log-ver130806
  labels:
    type: gitlab-log-ver130806
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs-viperliu
  nfs:
    path: /nfs_dir/gitlab_log_ver130806
    server: 172.16.15.111

# pvc
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: gitlab-log-ver130806-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs-viperliu
  selector:
    matchLabels:
      type: gitlab-log-ver130806
      
# pv
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gitlab-opt-ver130806
  labels:
    type: gitlab-opt-ver130806
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs-viperliu
  nfs:
    path: /nfs_dir/gitlab_opt_ver130806
    server: 172.16.15.111

# pvc
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: gitlab-opt-ver130806-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs-viperliu
  selector:
    matchLabels:
      type: gitlab-opt-ver130806
---
apiVersion: v1
kind: Service
metadata:
  name: gitlab
  labels:
    app: gitlab
    tier: frontend
spec:
  ports:
    - name: gitlab-ui
      port: 80
      protocol: TCP
      targetPort: 80
    - name: gitlab-ssh
      port: 22
      protocol: TCP
      targetPort: 22
  selector:
    app: gitlab
    tier: frontend
  type: NodePort
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gitlab
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: gitlab-cb-ver130806
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: gitlab
    namespace: gitlab-ver130806
---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitlab
  labels:
    app: gitlab
    tier: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gitlab
      tier: frontend
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: gitlab
        tier: frontend
    spec:
      serviceAccountName: gitlab
      containers:
        - image: harbor.viperliu.com/library/gitlab-ce:13.8.6-ce.1
          name: gitlab
#          resources:
#            requests:
#              cpu: 400m
#              memory: 4Gi
#            limits:
#              cpu: "800m"
#              memory: 8Gi
          securityContext:
            privileged: true
          env:
            - name: TZ
              value: Asia/Shanghai
            - name: GITLAB_OMNIBUS_CONFIG
              value: |
                postgresql['enable'] = false
                gitlab_rails['db_username'] = "gitlab"
                gitlab_rails['db_password'] = "viperliuusepg"
                gitlab_rails['db_host'] = "postgresql"
                gitlab_rails['db_port'] = "5432"
                gitlab_rails['db_database'] = "gitlabhq_production"
                gitlab_rails['db_adapter'] = 'postgresql'
                gitlab_rails['db_encoding'] = 'utf8'
                redis['enable'] = false
                gitlab_rails['redis_host'] = 'redis'
                gitlab_rails['redis_port'] = '6379'
                gitlab_rails['redis_password'] = 'viperliuuseredis'
                gitlab_rails['gitlab_shell_ssh_port'] = 22
                external_url 'http://git.viperliu.com/'
                nginx['listen_port'] = 80
                nginx['listen_https'] = false
                #-------------------------------------------
                gitlab_rails['gitlab_email_enabled'] = true
                gitlab_rails['gitlab_email_from'] = 'admin@viperliu.com'
                gitlab_rails['gitlab_email_display_name'] = 'viperliu'
                gitlab_rails['gitlab_email_reply_to'] = 'gitlab@viperliu.com'
                gitlab_rails['gitlab_default_can_create_group'] = true
                gitlab_rails['gitlab_username_changing_enabled'] = true
                gitlab_rails['smtp_enable'] = true
                gitlab_rails['smtp_address'] = "smtp.exmail.qq.com"
                gitlab_rails['smtp_port'] = 465
                gitlab_rails['smtp_user_name'] = "gitlab@viperliu.com"
                gitlab_rails['smtp_password'] = "viperliusendmail"
                gitlab_rails['smtp_domain'] = "exmail.qq.com"
                gitlab_rails['smtp_authentication'] = "login"
                gitlab_rails['smtp_enable_starttls_auto'] = true
                gitlab_rails['smtp_tls'] = true
                #-------------------------------------------
                # 关闭 promethues
                prometheus['enable'] = false
                # 关闭 grafana
                grafana['enable'] = false
                # 减少内存占用
                unicorn['worker_memory_limit_min'] = "200 * 1 << 20"
                unicorn['worker_memory_limit_max'] = "300 * 1 << 20"
                # 减少 sidekiq 的并发数
                sidekiq['concurrency'] = 16
                # 减少 postgresql 数据库缓存
                postgresql['shared_buffers'] = "256MB"
                # 减少 postgresql 数据库并发数量
                postgresql['max_connections'] = 8
                # 减少进程数   worker=CPU核数+1
                unicorn['worker_processes'] = 2
                nginx['worker_processes'] = 2
                puma['worker_processes'] = 2
                # puma['per_worker_max_memory_mb'] = 850
                # 保留3天备份的数据文件
                gitlab_rails['backup_keep_time'] = 259200
                #-------------------------------------------
          ports:
            - containerPort: 80
              name: gitlab
          livenessProbe:
            exec:
              command:
              - sh
              - -c
              - "curl -s http://127.0.0.1/-/health|grep -w 'GitLab OK'"
            initialDelaySeconds: 120
            periodSeconds: 10
            timeoutSeconds: 5
            successThreshold: 1
            failureThreshold: 3
          readinessProbe:
            exec:
              command:
              - sh
              - -c
              - "curl -s http://127.0.0.1/-/health|grep -w 'GitLab OK'"
            initialDelaySeconds: 120
            periodSeconds: 10
            timeoutSeconds: 5
            successThreshold: 1
            failureThreshold: 3
          volumeMounts:
            - mountPath: /etc/gitlab
              name: gitlab1
            - mountPath: /var/log/gitlab
              name: gitlab2
            - mountPath: /var/opt/gitlab
              name: gitlab3
            - mountPath: /etc/localtime
              name: tz-config

      volumes:
        - name: gitlab1
          persistentVolumeClaim:
            claimName: gitlab-etc-ver130806-pvc
        - name: gitlab2
          persistentVolumeClaim:
            claimName: gitlab-log-ver130806-pvc
        - name: gitlab3
          persistentVolumeClaim:
            claimName: gitlab-opt-ver130806-pvc
        - name: tz-config
          hostPath:
            path: /usr/share/zoneinfo/Asia/Shanghai

      securityContext:
        runAsUser: 0
        fsGroup: 0
```

kubectl -n gitlab-ver130806 apply -f 5gitlab.yaml





gitlab-tls 

注释掉的是老版本的

记得把证书给创建了

证书指定的域名为*.viperliu.com 

然后指定gitlab命名空间下创建secert

6gitlab-tls.yaml

```toml
# old version

#apiVersion: extensions/v1beta1
#kind: Ingress
#metadata:
#  name: gitlab
#  annotations:
#    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
#    nginx.ingress.kubernetes.io/proxy-body-size: "20m"
#spec:
#  tls:
#  - hosts:
#    - git.viperliu.com
#    secretName: mytls
#  rules:
#  - host: git.viperliu.com
#    http:
#      paths:
#      - path: /
#        backend:
#          serviceName: gitlab
#          servicePort: 80

# Add tls
openssl genrsa -out tls.key 2048
openssl req -new -x509 -key tls.key -out tls.cert -days 360 -subj /CN=*.viperliu.com
kubectl -n gitlab-ver130806 create secret tls mytls --cert=tls.cert --key=tls.key 

# new version

## https://kubernetes.io/docs/concepts/services-networking/ingress/
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gitlab
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
    nginx.ingress.kubernetes.io/proxy-body-size: "20m"
spec:
  tls:
  - hosts:
    - git.viperliu.com
    secretName: mytls
  rules:
  - host: git.viperliu.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: gitlab
            port:
              number: 80

---
```



kubectl -n gitlab-ver130806 apply -f 6gitlab-tls.yaml





增加hosts

git.viperliu.com 



登录修改   修改密码 zed452531.

用户名字为root  





首先在升级前，我们要确保gitlab的最新完整数据备份是有的，数据在手，万事无忧

```toml
namespace="gitlab-ver130806"
gitlabname=$(kubectl -n ${namespace} get pod|grep -v runner|grep -i running|grep gitlab|awk 'NR==1{print $1}')
# 13旧版本的备份命令
kubectl -n ${namespace} exec -it ${gitlabname} -- gitlab-rake gitlab:backup:create
# 14、15版本的备份命令
kubectl -n ${namespace} exec -it ${gitlabname} -- gitlab-backup create STRATEGY=copy


# 最后，在挂载的目录下面，会生成一个gitlab数据全备文件
/nfs_dir/gitlab/gitlab_opt/backups/1743837820_2025_04_05_13.8.6_gitlab_backup.tar

这个时候我们重新打包镜像 替换deployment镜像  重新打开也 git.viperliu.com/help 可以看到版本更新了
# 恢复全备数据库命令
kubectl -n ${namespace} exec -it $(kubectl -n ${namespace} get pod|grep -v runner|grep gitlab|awk '{print $1}') -- gitlab-rake gitlab:backup:restore BACKUP=1743837820_2025_04_05_13.8.6
```

然后看看完整的升级路线

```toml
从13版本升级到15版本的完整路线：
13.8.6 > 13.8.8 > 13.12.15 > 14.0.12 > 14.3.6 > 14.9.5 > 14.10.5 > 15.0.5 > 15.1.6 > 15.4.6 > 15.11.13
```



14版本之前都可以 但是看网上的来说  升级到14之后的版本都是hash存储了 