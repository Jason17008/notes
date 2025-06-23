https://blog.csdn.net/weixin_46887489/article/details/134586363?spm=1001.2014.3001.5502



```toml
然后更改他的工作的cpu个数 
最好是ingress-nginx 单独占一个节点 
worker-processes 
比如8c   分6 7个核心 
worker-cpu-affinity:"" 这个不要填写 
给了2种部署方式 一种是deployment 一种是daemont
检验还是用daemmmnont 


limit 跟requests 记得要开启一下 
按照实际机器进行分配 比如8c 给分6c其他 给系统留一些空余 
555 记得单独部署到一台机器上   标签选择 然后打上污点 

测试环境 打上一个标签选择器 然后只在标签选择器上会部署你的pod 
kubectl label node xx.xx.xx.xx viperliu/ingress-controller-ready=true  
      # kubectl get node --show-labels
      # kubectl label node xx.xx.xx.xx viperliu/ingress-controller-ready-
      nodeSelector:
        viperliu/ingress-controller-ready: "true"


也要上污点最好 
下面一个是博哥的示范例子
一个是我进行安装 批量替换的viperliu
```





```toml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ingress-nginx
  namespace: kube-system

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.9.3
  name: ingress-nginx
  namespace: kube-system
rules:
- apiGroups:
  - ""
  resources:
  - namespaces
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - configmaps
  - pods
  - secrets
  - endpoints
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - networking.k8s.io
  resources:
  - ingresses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - networking.k8s.io
  resources:
  - ingresses/status
  verbs:
  - update
- apiGroups:
  - networking.k8s.io
  resources:
  - ingressclasses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resourceNames:
  - ingress-controller-leader-nginx
  resources:
  - configmaps
  verbs:
  - get
  - update
- apiGroups:
  - ""
  resources:
  - configmaps
  verbs:
  - create
- apiGroups:
  - coordination.k8s.io
  resourceNames:
  - ingress-controller-leader-nginx
  resources:
  - leases
  verbs:
  - get
  - update
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - create
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - create
  - patch
- apiGroups:
  - discovery.k8s.io
  resources:
  - endpointslices
  verbs:
  - list
  - watch
  - get
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.9.3
  name: ingress-nginx
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  - endpoints
  - nodes
  - pods
  - secrets
  - namespaces
  verbs:
  - list
  - watch
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - networking.k8s.io
  resources:
  - ingresses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - create
  - patch
- apiGroups:
  - networking.k8s.io
  resources:
  - ingresses/status
  verbs:
  - update
- apiGroups:
  - networking.k8s.io
  resources:
  - ingressclasses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - discovery.k8s.io
  resources:
  - endpointslices
  verbs:
  - list
  - watch
  - get
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.9.3
  name: ingress-nginx
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ingress-nginx
subjects:
- kind: ServiceAccount
  name: ingress-nginx
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.9.3
  name: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ingress-nginx
subjects:
- kind: ServiceAccount
  name: ingress-nginx
  namespace: kube-system


# https://www.cnblogs.com/dudu/p/12197646.html
#---
#apiVersion: monitoring.coreos.com/v1
#kind: ServiceMonitor
#metadata:
#  labels:
#    app: ingress-nginx
#  name: nginx-ingress-scraping
#  namespace: kube-system
#spec:
#  endpoints:
#  - interval: 30s
#    path: /metrics
#    port: metrics
#  jobLabel: app
#  namespaceSelector:
#    matchNames:
#    - ingress-nginx
#  selector:
#    matchLabels:
#      app: ingress-nginx

---

apiVersion: v1
kind: Service
metadata:
  labels:
    app: ingress-nginx
  name: nginx-ingress-lb
  namespace: kube-system
spec:
  # DaemonSet need:
  # ----------------
  type: ClusterIP
  # ----------------
  # Deployment need:
  # ----------------
#  type: NodePort
  # ----------------
  ports:
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
  - name: https
    port: 443
    targetPort: 443
    protocol: TCP
  - name: metrics
    port: 10254
    protocol: TCP
    targetPort: 10254
  selector:
    app: ingress-nginx

---
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller-admission
  namespace: kube-system
spec:
  type: ClusterIP
  ports:
    - name: https-webhook
      port: 443
      targetPort: 8443
  selector:
    app: ingress-nginx

---
# all configmaps means:
# https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/configmap.md

kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-configuration
  namespace: kube-system
  labels:
    app: ingress-nginx
data:
  allow-snippet-annotations: "true"
  allow-backend-server-header: "true"
  disable-access-log: "false"
  enable-underscores-in-headers: "true"
  generate-request-id: "true"
  ignore-invalid-headers: "true"
  keep-alive: "900"
  keep-alive-requests: "10000"
  large-client-header-buffers: 5 20k
  log-format-upstream: '{"@timestamp": "$time_iso8601","remote_addr": "$remote_addr","x-forward-for": "$proxy_add_x_forwarded_for","request_id": "$req_id","remote_user": "$remote_user","bytes_sent": $bytes_sent,"request_time": $request_time,"status": $status,"vhost": "$host","request_proto": "$server_protocol","path": "$uri","request_query": "$args","request_length": $request_length,"duration": $request_time,"method": "$request_method","http_referrer": "$http_referer","http_user_agent":  "$http_user_agent","upstream-sever":"$proxy_upstream_name","proxy_alternative_upstream_name":"$proxy_alternative_upstream_name","upstream_addr":"$upstream_addr","upstream_response_length":$upstream_response_length,"upstream_response_time":$upstream_response_time,"upstream_status":$upstream_status}'
  max-worker-connections: "65536"
  proxy-body-size: 20m
  proxy-connect-timeout: "10"
  proxy-read-timeout: "60"
  proxy-send-timeout: "60"
  reuse-port: "true"
  server-tokens: "false"
  ssl-redirect: "false"
  upstream-keepalive-connections: "300"
  upstream-keepalive-requests: "1000"
  upstream-keepalive-timeout: "900"
  worker-cpu-affinity: ""
  worker-processes: "1"
  http-redirect-code: "301"
  proxy_next_upstream: error timeout http_502
  ssl-ciphers: ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA
  ssl-protocols: TLSv1 TLSv1.1 TLSv1.2


---
kind: ConfigMap
apiVersion: v1
metadata:
  name: tcp-services
  namespace: kube-system
  labels:
    app: ingress-nginx

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: udp-services
  namespace: kube-system
  labels:
    app: ingress-nginx

---
apiVersion: apps/v1
kind: DaemonSet
#kind: Deployment
metadata:
  name: nginx-ingress-controller
  namespace: kube-system
  labels:
    app: ingress-nginx
  annotations:
    component.revision: "2"
    component.version: 1.9.3
spec:
  # Deployment need:
  # ----------------
#  replicas: 1
  # ----------------
  selector:
    matchLabels:
      app: ingress-nginx
  template:
    metadata:
      labels:
        app: ingress-nginx
      annotations:
        prometheus.io/port: "10254"
        prometheus.io/scrape: "true"
    spec:
      # DaemonSet need:
      # ----------------
      hostNetwork: true
      # ----------------
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - ingress-nginx
              topologyKey: kubernetes.io/hostname
            weight: 100
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: type
                operator: NotIn
                values:
                - virtual-kubelet
              - key: k8s.aliyun.com
                operator: NotIn
                values:
                - "true"
      containers:
      - args:
          - /nginx-ingress-controller
          - --election-id=ingress-controller-leader-nginx
          - --ingress-class=nginx
          - --watch-ingress-without-class
          - --controller-class=k8s.io/ingress-nginx
          - --configmap=$(POD_NAMESPACE)/nginx-configuration
          - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
          - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
          - --annotations-prefix=nginx.ingress.kubernetes.io
          - --publish-service=$(POD_NAMESPACE)/nginx-ingress-lb
          - --validating-webhook=:8443
          - --validating-webhook-certificate=/usr/local/certificates/cert
          - --validating-webhook-key=/usr/local/certificates/key
          - --enable-metrics=false
          - --v=2
        env:
          - name: POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: LD_PRELOAD
            value: /usr/local/lib/libmimalloc.so
        image: registry-cn-hangzhou.ack.aliyuncs.com/acs/aliyun-ingress-controller:v1.9.3-aliyun.1
        imagePullPolicy: IfNotPresent
        lifecycle:
          preStop:
            exec:
              command:
                - /wait-shutdown
        livenessProbe:
          failureThreshold: 5
          httpGet:
            path: /healthz
            port: 10254
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 1
          successThreshold: 1
        name: nginx-ingress-controller
        ports:
          - name: http
            containerPort: 80
            protocol: TCP
          - name: https
            containerPort: 443
            protocol: TCP
          - name: webhook
            containerPort: 8443
            protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /healthz
            port: 10254
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 1
          successThreshold: 1
#        resources:
#          limits:
#            cpu: 1
#            memory: 2G
#          requests:
#            cpu: 1
#            memory: 2G
        securityContext:
          allowPrivilegeEscalation: true
          capabilities:
            drop:
              - ALL
            add:
              - NET_BIND_SERVICE
          runAsUser: 101
          # if get 'mount: mounting rw on /proc/sys failed: Permission denied', use:
#          privileged: true
#          procMount: Default
#          runAsUser: 0
        volumeMounts:
        - name: webhook-cert
          mountPath: /usr/local/certificates/
          readOnly: true
        - mountPath: /etc/localtime
          name: localtime
          readOnly: true
      dnsPolicy: ClusterFirst
      initContainers:
      - command:
        - /bin/sh
        - -c
        - |
          if [ "$POD_IP" != "$HOST_IP" ]; then
          mount -o remount rw /proc/sys
          sysctl -w net.core.somaxconn=65535
          sysctl -w net.ipv4.ip_local_port_range="1024 65535"
          sysctl -w kernel.core_uses_pid=0
          fi
        env:
        - name: POD_IP
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: status.podIP
        - name: HOST_IP
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: status.hostIP
        image: registry.cn-shanghai.aliyuncs.com/acs/busybox:v1.29.2
        imagePullPolicy: IfNotPresent
        name: init-sysctl
        resources:
          limits:
            cpu: 100m
            memory: 70Mi
          requests:
            cpu: 100m
            memory: 70Mi
        securityContext:
          capabilities:
            add:
            - SYS_ADMIN
            drop:
            - ALL
          # if get 'mount: mounting rw on /proc/sys failed: Permission denied', use:
          privileged: true
          procMount: Default
          runAsUser: 0
      # choose node with set this label running
      # kubectl label node xx.xx.xx.xx viperliu/ingress-controller-ready=true
      # kubectl get node --show-labels
      # kubectl label node xx.xx.xx.xx viperliu/ingress-controller-ready-
      nodeSelector:
        viperliu/ingress-controller-ready: "true"
      priorityClassName: system-node-critical
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      serviceAccount: ingress-nginx
      serviceAccountName: ingress-nginx
      terminationGracePeriodSeconds: 300
      # kubectl taint nodes xx.xx.xx.xx viperliu/ingress-controller-ready="true":NoExecute
      # kubectl taint nodes xx.xx.xx.xx viperliu/ingress-controller-ready:NoExecute-
      tolerations:
      - operator: Exists
#      tolerations:
#      - effect: NoExecute
#        key: viperliu/ingress-controller-ready
#        operator: Equal
#        value: "true"
      volumes:
      - name: webhook-cert
        secret:
          defaultMode: 420
          secretName: ingress-nginx-admission
      - hostPath:
          path: /etc/localtime
          type: File
        name: localtime

---
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx-master
  namespace: kube-system
  annotations:
   ingressclass.kubernetes.io/is-default-class: "true"
spec:
  controller: k8s.io/ingress-nginx


---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  labels:
    name: ingress-nginx
  name: ingress-nginx-admission
webhooks:
  - name: validate.nginx.ingress.kubernetes.io
    matchPolicy: Equivalent
    rules:
      - apiGroups:
          - networking.k8s.io
        apiVersions:
          - v1
        operations:
          - CREATE
          - UPDATE
        resources:
          - ingresses
    failurePolicy: Fail
    sideEffects: None
    admissionReviewVersions:
      - v1
    clientConfig:
      service:
        namespace: kube-system
        name: ingress-nginx-controller-admission
        path: /networking/v1/ingresses
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ingress-nginx-admission
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ingress-nginx-admission
rules:
  - apiGroups:
      - admissionregistration.k8s.io
    resources:
      - validatingwebhookconfigurations
    verbs:
      - get
      - update
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ingress-nginx-admission
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ingress-nginx-admission
subjects:
  - kind: ServiceAccount
    name: ingress-nginx-admission
    namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ingress-nginx-admission
  namespace: kube-system
rules:
  - apiGroups:
      - ""
    resources:
      - secrets
    verbs:
      - get
      - create
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ingress-nginx-admission
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ingress-nginx-admission
subjects:
  - kind: ServiceAccount
    name: ingress-nginx-admission
    namespace: kube-system
---
apiVersion: batch/v1
kind: Job
metadata:
  name: ingress-nginx-admission-create
  labels:
    name: ingress-nginx
  namespace: kube-system
spec:
  template:
    metadata:
      name: ingress-nginx-admission-create
      labels:
        name: ingress-nginx
    spec:
      containers:
        - name: create
#          image: registry-vpc.cn-hangzhou.aliyuncs.com/acs/kube-webhook-certgen:v1.1.1
          image: registry.cn-beijing.aliyuncs.com/acs/kube-webhook-certgen:v1.5.1
          imagePullPolicy: IfNotPresent
          args:
            - create
            - --host=ingress-nginx-controller-admission,ingress-nginx-controller-admission.$(POD_NAMESPACE).svc
            - --namespace=$(POD_NAMESPACE)
            - --secret-name=ingress-nginx-admission
          env:
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
      restartPolicy: OnFailure
      serviceAccountName: ingress-nginx-admission
      securityContext:
        runAsNonRoot: true
        runAsUser: 2000
---
apiVersion: batch/v1
kind: Job
metadata:
  name: ingress-nginx-admission-patch
  labels:
    name: ingress-nginx
  namespace: kube-system
spec:
  template:
    metadata:
      name: ingress-nginx-admission-patch
      labels:
        name: ingress-nginx
    spec:
      containers:
        - name: patch
          image: registry.cn-hangzhou.aliyuncs.com/acs/kube-webhook-certgen:v1.1.1  # if error use this image
          imagePullPolicy: IfNotPresent
          args:
            - patch
            - --webhook-name=ingress-nginx-admission
            - --namespace=$(POD_NAMESPACE)
            - --patch-mutating=false
            - --secret-name=ingress-nginx-admission
            - --patch-failure-policy=Fail
          env:
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          securityContext:
            allowPrivilegeEscalation: false
      restartPolicy: OnFailure
      serviceAccountName: ingress-nginx-admission
      securityContext:
        runAsNonRoot: true
        runAsUser: 2000

---
## Deployment need for aliyun'k8s:
#apiVersion: v1
#kind: Service
#metadata:
#  annotations:
#    service.beta.kubernetes.io/alibaba-cloud-loadbalancer-id: "lb-xxxxxxxxxxxxxxxxx"
#    service.beta.kubernetes.io/alibaba-cloud-loadbalancer-force-override-listeners: "true"
#  labels:
#    app: nginx-ingress-lb
#  name: nginx-ingress-lb-viperliu
#  namespace: kube-system
#spec:
#  externalTrafficPolicy: Local
#  ports:
#  - name: http
#    port: 80
#    protocol: TCP
#    targetPort: 80
#  - name: https
#    port: 443
#    protocol: TCP
#    targetPort: 443
#  selector:
#    app: ingress-nginx
#  type: LoadBalancer
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ingress-nginx
  namespace: kube-system

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.9.3
  name: ingress-nginx
  namespace: kube-system
rules:
- apiGroups:
  - ""
  resources:
  - namespaces
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - configmaps
  - pods
  - secrets
  - endpoints
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - networking.k8s.io
  resources:
  - ingresses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - networking.k8s.io
  resources:
  - ingresses/status
  verbs:
  - update
- apiGroups:
  - networking.k8s.io
  resources:
  - ingressclasses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resourceNames:
  - ingress-controller-leader-nginx
  resources:
  - configmaps
  verbs:
  - get
  - update
- apiGroups:
  - ""
  resources:
  - configmaps
  verbs:
  - create
- apiGroups:
  - coordination.k8s.io
  resourceNames:
  - ingress-controller-leader-nginx
  resources:
  - leases
  verbs:
  - get
  - update
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - create
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - create
  - patch
- apiGroups:
  - discovery.k8s.io
  resources:
  - endpointslices
  verbs:
  - list
  - watch
  - get
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.9.3
  name: ingress-nginx
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  - endpoints
  - nodes
  - pods
  - secrets
  - namespaces
  verbs:
  - list
  - watch
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - networking.k8s.io
  resources:
  - ingresses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - create
  - patch
- apiGroups:
  - networking.k8s.io
  resources:
  - ingresses/status
  verbs:
  - update
- apiGroups:
  - networking.k8s.io
  resources:
  - ingressclasses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - discovery.k8s.io
  resources:
  - endpointslices
  verbs:
  - list
  - watch
  - get
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.9.3
  name: ingress-nginx
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ingress-nginx
subjects:
- kind: ServiceAccount
  name: ingress-nginx
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.9.3
  name: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ingress-nginx
subjects:
- kind: ServiceAccount
  name: ingress-nginx
  namespace: kube-system


# https://www.cnblogs.com/dudu/p/12197646.html
#---
#apiVersion: monitoring.coreos.com/v1
#kind: ServiceMonitor
#metadata:
#  labels:
#    app: ingress-nginx
#  name: nginx-ingress-scraping
#  namespace: kube-system
#spec:
#  endpoints:
#  - interval: 30s
#    path: /metrics
#    port: metrics
#  jobLabel: app
#  namespaceSelector:
#    matchNames:
#    - ingress-nginx
#  selector:
#    matchLabels:
#      app: ingress-nginx

---

apiVersion: v1
kind: Service
metadata:
  labels:
    app: ingress-nginx
  name: nginx-ingress-lb
  namespace: kube-system
spec:
  # DaemonSet need:
  # ----------------
  type: ClusterIP
  # ----------------
  # Deployment need:
  # ----------------
#  type: NodePort
  # ----------------
  ports:
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
  - name: https
    port: 443
    targetPort: 443
    protocol: TCP
  - name: metrics
    port: 10254
    protocol: TCP
    targetPort: 10254
  selector:
    app: ingress-nginx

---
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller-admission
  namespace: kube-system
spec:
  type: ClusterIP
  ports:
    - name: https-webhook
      port: 443
      targetPort: 8443
  selector:
    app: ingress-nginx

---
# all configmaps means:
# https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/configmap.md

kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-configuration
  namespace: kube-system
  labels:
    app: ingress-nginx
data:
  allow-snippet-annotations: "true"
  allow-backend-server-header: "true"
  disable-access-log: "false"
  enable-underscores-in-headers: "true"
  generate-request-id: "true"
  ignore-invalid-headers: "true"
  keep-alive: "900"
  keep-alive-requests: "10000"
  large-client-header-buffers: 5 20k
  log-format-upstream: '{"@timestamp": "$time_iso8601","remote_addr": "$remote_addr","x-forward-for": "$proxy_add_x_forwarded_for","request_id": "$req_id","remote_user": "$remote_user","bytes_sent": $bytes_sent,"request_time": $request_time,"status": $status,"vhost": "$host","request_proto": "$server_protocol","path": "$uri","request_query": "$args","request_length": $request_length,"duration": $request_time,"method": "$request_method","http_referrer": "$http_referer","http_user_agent":  "$http_user_agent","upstream-sever":"$proxy_upstream_name","proxy_alternative_upstream_name":"$proxy_alternative_upstream_name","upstream_addr":"$upstream_addr","upstream_response_length":$upstream_response_length,"upstream_response_time":$upstream_response_time,"upstream_status":$upstream_status}'
  max-worker-connections: "65536"
  proxy-body-size: 20m
  proxy-connect-timeout: "10"
  proxy-read-timeout: "60"
  proxy-send-timeout: "60"
  reuse-port: "true"
  server-tokens: "false"
  ssl-redirect: "false"
  upstream-keepalive-connections: "300"
  upstream-keepalive-requests: "1000"
  upstream-keepalive-timeout: "900"
  worker-cpu-affinity: ""
  worker-processes: "1"
  http-redirect-code: "301"
  proxy_next_upstream: error timeout http_502
  ssl-ciphers: ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA
  ssl-protocols: TLSv1 TLSv1.1 TLSv1.2


---
kind: ConfigMap
apiVersion: v1
metadata:
  name: tcp-services
  namespace: kube-system
  labels:
    app: ingress-nginx

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: udp-services
  namespace: kube-system
  labels:
    app: ingress-nginx

---
apiVersion: apps/v1
kind: DaemonSet
#kind: Deployment
metadata:
  name: nginx-ingress-controller
  namespace: kube-system
  labels:
    app: ingress-nginx
  annotations:
    component.revision: "2"
    component.version: 1.9.3
spec:
  # Deployment need:
  # ----------------
#  replicas: 1
  # ----------------
  selector:
    matchLabels:
      app: ingress-nginx
  template:
    metadata:
      labels:
        app: ingress-nginx
      annotations:
        prometheus.io/port: "10254"
        prometheus.io/scrape: "true"
    spec:
      # DaemonSet need:
      # ----------------
      hostNetwork: true
      # ----------------
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - ingress-nginx
              topologyKey: kubernetes.io/hostname
            weight: 100
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: type
                operator: NotIn
                values:
                - virtual-kubelet
              - key: k8s.aliyun.com
                operator: NotIn
                values:
                - "true"
      containers:
      - args:
          - /nginx-ingress-controller
          - --election-id=ingress-controller-leader-nginx
          - --ingress-class=nginx
          - --watch-ingress-without-class
          - --controller-class=k8s.io/ingress-nginx
          - --configmap=$(POD_NAMESPACE)/nginx-configuration
          - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
          - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
          - --annotations-prefix=nginx.ingress.kubernetes.io
          - --publish-service=$(POD_NAMESPACE)/nginx-ingress-lb
          - --validating-webhook=:8443
          - --validating-webhook-certificate=/usr/local/certificates/cert
          - --validating-webhook-key=/usr/local/certificates/key
          - --enable-metrics=false
          - --v=2
        env:
          - name: POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: LD_PRELOAD
            value: /usr/local/lib/libmimalloc.so
        image: registry-cn-hangzhou.ack.aliyuncs.com/acs/aliyun-ingress-controller:v1.9.3-aliyun.1
        imagePullPolicy: IfNotPresent
        lifecycle:
          preStop:
            exec:
              command:
                - /wait-shutdown
        livenessProbe:
          failureThreshold: 5
          httpGet:
            path: /healthz
            port: 10254
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 1
          successThreshold: 1
        name: nginx-ingress-controller
        ports:
          - name: http
            containerPort: 80
            protocol: TCP
          - name: https
            containerPort: 443
            protocol: TCP
          - name: webhook
            containerPort: 8443
            protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /healthz
            port: 10254
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 1
          successThreshold: 1
#        resources:
#          limits:
#            cpu: 1
#            memory: 2G
#          requests:
#            cpu: 1
#            memory: 2G
        securityContext:
          allowPrivilegeEscalation: true
          capabilities:
            drop:
              - ALL
            add:
              - NET_BIND_SERVICE
          runAsUser: 101
          # if get 'mount: mounting rw on /proc/sys failed: Permission denied', use:
#          privileged: true
#          procMount: Default
#          runAsUser: 0
        volumeMounts:
        - name: webhook-cert
          mountPath: /usr/local/certificates/
          readOnly: true
        - mountPath: /etc/localtime
          name: localtime
          readOnly: true
      dnsPolicy: ClusterFirst
      initContainers:
      - command:
        - /bin/sh
        - -c
        - |
          if [ "$POD_IP" != "$HOST_IP" ]; then
          mount -o remount rw /proc/sys
          sysctl -w net.core.somaxconn=65535
          sysctl -w net.ipv4.ip_local_port_range="1024 65535"
          sysctl -w kernel.core_uses_pid=0
          fi
        env:
        - name: POD_IP
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: status.podIP
        - name: HOST_IP
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: status.hostIP
        image: registry.cn-shanghai.aliyuncs.com/acs/busybox:v1.29.2
        imagePullPolicy: IfNotPresent
        name: init-sysctl
        resources:
          limits:
            cpu: 100m
            memory: 70Mi
          requests:
            cpu: 100m
            memory: 70Mi
        securityContext:
          capabilities:
            add:
            - SYS_ADMIN
            drop:
            - ALL
          # if get 'mount: mounting rw on /proc/sys failed: Permission denied', use:
          privileged: true
          procMount: Default
          runAsUser: 0
      # choose node with set this label running
      # kubectl label node xx.xx.xx.xx viperliu/ingress-controller-ready=true
      # kubectl get node --show-labels
      # kubectl label node xx.xx.xx.xx viperliu/ingress-controller-ready-
      nodeSelector:
        viperliu/ingress-controller-ready: "true"
      priorityClassName: system-node-critical
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      serviceAccount: ingress-nginx
      serviceAccountName: ingress-nginx
      terminationGracePeriodSeconds: 300
      # kubectl taint nodes xx.xx.xx.xx viperliu/ingress-controller-ready="true":NoExecute
      # kubectl taint nodes xx.xx.xx.xx viperliu/ingress-controller-ready:NoExecute-
      tolerations:
      - operator: Exists
#      tolerations:
#      - effect: NoExecute
#        key: viperliu/ingress-controller-ready
#        operator: Equal
#        value: "true"
      volumes:
      - name: webhook-cert
        secret:
          defaultMode: 420
          secretName: ingress-nginx-admission
      - hostPath:
          path: /etc/localtime
          type: File
        name: localtime

---
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx-master
  namespace: kube-system
  annotations:
   ingressclass.kubernetes.io/is-default-class: "true"
spec:
  controller: k8s.io/ingress-nginx


---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  labels:
    name: ingress-nginx
  name: ingress-nginx-admission
webhooks:
  - name: validate.nginx.ingress.kubernetes.io
    matchPolicy: Equivalent
    rules:
      - apiGroups:
          - networking.k8s.io
        apiVersions:
          - v1
        operations:
          - CREATE
          - UPDATE
        resources:
          - ingresses
    failurePolicy: Fail
    sideEffects: None
    admissionReviewVersions:
      - v1
    clientConfig:
      service:
        namespace: kube-system
        name: ingress-nginx-controller-admission
        path: /networking/v1/ingresses
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ingress-nginx-admission
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ingress-nginx-admission
rules:
  - apiGroups:
      - admissionregistration.k8s.io
    resources:
      - validatingwebhookconfigurations
    verbs:
      - get
      - update
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ingress-nginx-admission
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ingress-nginx-admission
subjects:
  - kind: ServiceAccount
    name: ingress-nginx-admission
    namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ingress-nginx-admission
  namespace: kube-system
rules:
  - apiGroups:
      - ""
    resources:
      - secrets
    verbs:
      - get
      - create
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ingress-nginx-admission
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ingress-nginx-admission
subjects:
  - kind: ServiceAccount
    name: ingress-nginx-admission
    namespace: kube-system
---
apiVersion: batch/v1
kind: Job
metadata:
  name: ingress-nginx-admission-create
  labels:
    name: ingress-nginx
  namespace: kube-system
spec:
  template:
    metadata:
      name: ingress-nginx-admission-create
      labels:
        name: ingress-nginx
    spec:
      containers:
        - name: create
#          image: registry-vpc.cn-hangzhou.aliyuncs.com/acs/kube-webhook-certgen:v1.1.1
          image: registry.cn-beijing.aliyuncs.com/acs/kube-webhook-certgen:v1.5.1
          imagePullPolicy: IfNotPresent
          args:
            - create
            - --host=ingress-nginx-controller-admission,ingress-nginx-controller-admission.$(POD_NAMESPACE).svc
            - --namespace=$(POD_NAMESPACE)
            - --secret-name=ingress-nginx-admission
          env:
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
      restartPolicy: OnFailure
      serviceAccountName: ingress-nginx-admission
      securityContext:
        runAsNonRoot: true
        runAsUser: 2000
---
apiVersion: batch/v1
kind: Job
metadata:
  name: ingress-nginx-admission-patch
  labels:
    name: ingress-nginx
  namespace: kube-system
spec:
  template:
    metadata:
      name: ingress-nginx-admission-patch
      labels:
        name: ingress-nginx
    spec:
      containers:
        - name: patch
          image: registry.cn-hangzhou.aliyuncs.com/acs/kube-webhook-certgen:v1.1.1  # if error use this image
          imagePullPolicy: IfNotPresent
          args:
            - patch
            - --webhook-name=ingress-nginx-admission
            - --namespace=$(POD_NAMESPACE)
            - --patch-mutating=false
            - --secret-name=ingress-nginx-admission
            - --patch-failure-policy=Fail
          env:
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          securityContext:
            allowPrivilegeEscalation: false
      restartPolicy: OnFailure
      serviceAccountName: ingress-nginx-admission
      securityContext:
        runAsNonRoot: true
        runAsUser: 2000

---
## Deployment need for aliyun'k8s:
#apiVersion: v1
#kind: Service
#metadata:
#  annotations:
#    service.beta.kubernetes.io/alibaba-cloud-loadbalancer-id: "lb-xxxxxxxxxxxxxxxxx"
#    service.beta.kubernetes.io/alibaba-cloud-loadbalancer-force-override-listeners: "true"
#  labels:
#    app: nginx-ingress-lb
#  name: nginx-ingress-lb-viperliu
#  namespace: kube-system
#spec:
#  externalTrafficPolicy: Local
#  ports:
#  - name: http
#    port: 80
#    protocol: TCP
#    targetPort: 80
#  - name: https
#    port: 443
#    protocol: TCP
#    targetPort: 443
#  selector:
#    app: ingress-nginx
#  type: LoadBalancer
```





kubectl -n kube-system apply -f  ingress-nginx-conttler.yaml



部署完成之后 然后要搞ingress  这样才能看到是否部署成功 

ingress 配置

下面的是博哥的例子  我将会搞一套自己的使用的

```toml
---
kind: Service
apiVersion: v1
metadata:
  name: new-nginx
spec:
  selector:
    app: new-nginx
  ports:
    - name: http-port
      port: 80
      protocol: TCP
      targetPort: 80

---
# 新版本k8s的ingress配置
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: new-nginx
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
    nginx.ingress.kubernetes.io/whitelist-source-range: 0.0.0.0/0
    nginx.ingress.kubernetes.io/configuration-snippet: |
      if ($host != 'www.boge.com' ) {
        rewrite ^ http://www.boge.com$request_uri permanent;
      }
spec:
  rules:
    - host: boge.com
      http:
        paths:
          - backend:
              service:
                name: new-nginx
                port:
                  number: 80
            path: /
            pathType: Prefix
    - host: m.boge.com
      http:
        paths:
          - backend:
              service:
                name: new-nginx
                port:
                  number: 80
            path: /
            pathType: Prefix
    - host: www.boge.com
      http:
        paths:
          - backend:
              service:
                name: new-nginx
                port:
                  number: 80
            path: /
            pathType: Prefix
#  tls:
#      - hosts:
#          - boge.com
#          - m.boge.com
#          - www.boge.com
#        secretName: boge-com-tls

# tls secret create command:
#   kubectl -n <namespace> create secret tls boge-com-tls --key boge-com.key --cert boge-com.csr

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: new-nginx
  labels:
    app: new-nginx
spec:
  replicas: 3  # 数量可以根据NODE节点数量来定义
  selector:
    matchLabels:
      app: new-nginx
  template:
    metadata:
      labels:
        app: new-nginx
    spec:
      containers:
#--------------------------------------------------
      - name: new-nginx
        image: nginx:1.21.6
        env:
          - name: TZ
            value: Asia/Shanghai
        ports:
        - containerPort: 80
        volumeMounts:
          - name: html-files
            mountPath: "/usr/share/nginx/html"
#--------------------------------------------------
      - name: busybox
        image: registry.cn-hangzhou.aliyuncs.com/acs/busybox:v1.29.2
        args:
        - /bin/sh
        - -c
        - >
           while :; do
             if [ -f /html/index.html ];then
               echo "[$(date +%F\ %T)] ${MY_POD_NAMESPACE}-${MY_POD_NAME}-${MY_POD_IP}" > /html/index.html
               sleep 1
             else
               touch /html/index.html
             fi
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
        volumeMounts:
          - name: html-files
            mountPath: "/html"
          - mountPath: /etc/localtime
            name: tz-config

#--------------------------------------------------
      volumes:
        - name: html-files
          emptyDir:
            medium: Memory
            sizeLimit: 10Mi
        - name: tz-config
          hostPath:
            path: /usr/share/zoneinfo/Asia/Shanghai

---
```

下面是我自己使用的

首选全部替换了viperliu  老版本的注解报错 已修复 

然后在其他节点上添加hosts解析 

172.16.15.110   boge.com m.boge.com www.boge.com viperliu.com m.viperliu.com www.viperliu.com

curl www.viperliu.com

返回有时间证明成功 

kubectl -n kube-system logs -f nginx-ingress-controller-99msv

可以查看到日志 

```toml
kind: Service
apiVersion: v1
metadata:
  name: new-nginx
spec:
  selector:
    app: new-nginx
  ports:
    - name: http-port
      port: 80
      protocol: TCP
      targetPort: 80

---
# 新版本k8s的ingress配置
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: new-nginx
  annotations:
    #kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
    nginx.ingress.kubernetes.io/whitelist-source-range: 0.0.0.0/0
    nginx.ingress.kubernetes.io/configuration-snippet: |
      if ($host != 'www.viperliu.com' ) {
        rewrite ^ http://www.viperliu.com$request_uri permanent;
      }
spec:
  ingressClassName: nginx-master
  rules:
    - host: viperliu.com
      http:
        paths:
          - backend:
              service:
                name: new-nginx
                port:
                  number: 80
            path: /
            pathType: Prefix
    - host: m.viperliu.com
      http:
        paths:
          - backend:
              service:
                name: new-nginx
                port:
                  number: 80
            path: /
            pathType: Prefix
    - host: www.viperliu.com
      http:
        paths:
          - backend:
              service:
                name: new-nginx
                port:
                  number: 80
            path: /
            pathType: Prefix
#  tls:
#      - hosts:
#          - viperliu.com
#          - m.viperliu.com
#          - www.viperliu.com
#        secretName: viperliu-com-tls

# tls secret create command:
#   kubectl -n <namespace> create secret tls viperliu-com-tls --key viperliu-com.key --cert viperliu-com.csr

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: new-nginx
  labels:
    app: new-nginx
spec:
  replicas: 3  # 数量可以根据NODE节点数量来定义
  selector:
    matchLabels:
      app: new-nginx
  template:
    metadata:
      labels:
        app: new-nginx
    spec:
      containers:
#--------------------------------------------------
      - name: new-nginx
        image: nginx:1.21.6
        env:
          - name: TZ
            value: Asia/Shanghai
        ports:
        - containerPort: 80
        volumeMounts:
          - name: html-files
            mountPath: "/usr/share/nginx/html"
#--------------------------------------------------
      - name: busybox
        image: registry.cn-hangzhou.aliyuncs.com/acs/busybox:v1.29.2
        args:
        - /bin/sh
        - -c
        - >
           while :; do
             if [ -f /html/index.html ];then
               echo "[$(date +%F\ %T)] ${MY_POD_NAMESPACE}-${MY_POD_NAME}-${MY_POD_IP}" > /html/index.html
               sleep 1
             else
               touch /html/index.html
             fi
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
        volumeMounts:
          - name: html-files
            mountPath: "/html"
          - mountPath: /etc/localtime
            name: tz-config

#--------------------------------------------------
      volumes:
        - name: html-files
          emptyDir:
            medium: Memory
            sizeLimit: 10Mi
        - name: tz-config
          hostPath:
            path: /usr/share/zoneinfo/Asia/Shanghai

---
```

然后要搞一波证书 证书也要开启起来  

首先要自己签名 

```toml
openssl genrsa -out viperliu.key 2048

#2.再基于key生成tls证书(注意：这里我用的*.boge.com，这是生成泛域名的证书，后面所有新增加的三级域名都是可以用这个证书的)
# openssl req -new -x509 -key boge.key -out boge.csr -days 360 -subj /CN=*.boge.com
————————————————
openssl req -new -x509 -key viperliu.key -out viperliu.csr -days 3600 -subj /CN=*.viperliu.com

查看创建结果 
```

然后修改这个ingress的这个 

```toml
#  tls:
#      - hosts:
#          - viperliu.com
#          - m.viperliu.com
#          - www.viperliu.com
#        secretName: viperliu-com-tls

#这些注释都给释放开 
#kubectl -n <namespace> create secret tls viperliu-com-tls --key viperliu-com.key --cert viperliu-com.csr

kubectl  create secret tls viperliu-com-tls --key viperliu.key --cert viperliu.csr
```

然后再次实验

需要把https强制跳转改为true

然后改为https

最后的yaml文件 为

```toml
kind: Service
apiVersion: v1
metadata:
  name: new-nginx
spec:
  selector:
    app: new-nginx
  ports:
    - name: http-port
      port: 80
      protocol: TCP
      targetPort: 80

---
# 新版本k8s的ingress配置
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: new-nginx
  annotations:
    #kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/whitelist-source-range: 0.0.0.0/0
    nginx.ingress.kubernetes.io/configuration-snippet: |
      if ($host != 'www.viperliu.com' ) {
        rewrite ^ https://www.viperliu.com$request_uri permanent;
      }
spec:
  ingressClassName: nginx-master
  rules:
    - host: viperliu.com
      http:
        paths:
          - backend:
              service:
                name: new-nginx
                port:
                  number: 80
            path: /
            pathType: Prefix
    - host: m.viperliu.com
      http:
        paths:
          - backend:
              service:
                name: new-nginx
                port:
                  number: 80
            path: /
            pathType: Prefix
    - host: www.viperliu.com
      http:
        paths:
          - backend:
              service:
                name: new-nginx
                port:
                  number: 80
            path: /
            pathType: Prefix
  tls:
      - hosts:
          - viperliu.com
          - m.viperliu.com
          - www.viperliu.com
        secretName: viperliu-com-tls

# tls secret create command:
#   kubectl -n <namespace> create secret tls viperliu-com-tls --key viperliu-com.key --cert viperliu-com.csr

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: new-nginx
  labels:
    app: new-nginx
spec:
  replicas: 3  # 数量可以根据NODE节点数量来定义
  selector:
    matchLabels:
      app: new-nginx
  template:
    metadata:
      labels:
        app: new-nginx
    spec:
      containers:
#--------------------------------------------------
      - name: new-nginx
        image: nginx:1.21.6
        env:
          - name: TZ
            value: Asia/Shanghai
        ports:
        - containerPort: 80
        volumeMounts:
          - name: html-files
            mountPath: "/usr/share/nginx/html"
#--------------------------------------------------
      - name: busybox
        image: registry.cn-hangzhou.aliyuncs.com/acs/busybox:v1.29.2
        args:
        - /bin/sh
        - -c
        - >
           while :; do
             if [ -f /html/index.html ];then
               echo "[$(date +%F\ %T)] ${MY_POD_NAMESPACE}-${MY_POD_NAME}-${MY_POD_IP}" > /html/index.html
               sleep 1
             else
               touch /html/index.html
             fi
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
        volumeMounts:
          - name: html-files
            mountPath: "/html"
          - mountPath: /etc/localtime
            name: tz-config

#--------------------------------------------------
      volumes:
        - name: html-files
          emptyDir:
            medium: Memory
            sizeLimit: 10Mi
        - name: tz-config
          hostPath:
            path: /usr/share/zoneinfo/Asia/Shanghai

---
```



下面还有一个例子 讲的 从传参id 和body 蓝绿发布 这样 





# ingress-nginx  无法获取真实客户端ip的问题 

https://blog.csdn.net/weixin_46887489/article/details/134616471?spm=1001.2014.3001.5502



给ingress-nginx  configmap加参数 

```toml
# kubectl -n kube-system edit configmaps nginx-configuration

apiVersion: v1
data:
  ......
  compute-full-forwarded-for: "true"
  forwarded-for-header: "X-Forwarded-For"
  use-forwarded-headers: "true"
compute-full-forwarded-for
: 将 remote address 附加到 X-Forwarded-For Header而不是替换它。当启用此选项后端应用程序负责根据自己的受信任代理列表排除并提取客户端 IP。

forwarded-for-header
: 设置用于标识客户端的原始 IP 地址的 Header 字段。默认值X-Forwarded-For
，此处由于A10带入的是自定义记录IP的Header,所以此处填入是X_FORWARDED_FOR

use-forwarded-headers
: 如果设置为True时，则将设定的X-Forwarded-*
 Header传递给后端, 当Ingress在L7 代理/负载均衡器
之后使用此选项。如果设置为 false 时，则会忽略传入的X-Forwarded-*
Header, 当 Ingress 直接暴露在互联网或者 L3/数据包的负载均衡器后面,并且不会更改数据包中的源 IP请使用此选项。
```

然后按照博客里面的操作 

操作成功 会有1个信任的问题 需要其他业务 ingress里面 增加这样

```toml
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
    nginx.ingress.kubernetes.io/whitelist-source-range: 10.0.1.201/32  # 只允许信任IP访问，其他返回403
    nginx.ingress.kubernetes.io/configuration-snippet: |  # 加入自定义头部，保存remote_addr信息
      proxy_set_header X-Custom-Real-IP $remote_addr;
```

但要注意的是，对于提供安全的厂商来说，他们的出口IP信息会经常变化的，意味着一旦变化，那么获取客户端真实IP又会存在问题。我们在加这个信任配置的时候，需要根据实际情况来作考量要不要添加，其实只要我们不暴露限制的IP信息，通常情况下还是相对安全的

如果想在要ingress-nginx里面加信任

```toml
proxy-real-ip-cidr: 10.0.1.201/32,10.0.1.203/32
```

# 快速定位业务服务慢的问题：利用 Ingress-Nginx 和日志查询实现高效故障排查

```toml
这个时候我们是需要在ingress-nginx查看日志来定位问题的，那么我们怎么把有问题的这条业务服务请求和ingress-nginx日志关联起来呢，就是我们在业务开发的时候，可以和研发部门沟通，将ingress-nginx传过来的头部里面X-Request-Id这个唯一性标识ID记录下来，保存到我们的业务服务日志字段里面，这时候就把两者之间的日志给关联起来了
```

nginx带的

利用这个request id

跟开发  ingress-nginx  request id记录下  加到业务日志里面 

```toml
"request_time": 0.179,"status": 200   # 客户端发来的请求延迟+我们的服务端响应请求的延迟、请求状态码
"upstream_response_time":0.179,"upstream_status":200   # 我们的服务端响应请求的延迟、请求响应状态码

分析的话 如果是后面的慢 那么就是处理逻辑的问题了 响应请求慢 
如果request_time-upstream_response_time  时间长
就要看到 整个网络端前面的服务 
是网络运营商的问题  cdn慢  还是客户发起的慢  
```