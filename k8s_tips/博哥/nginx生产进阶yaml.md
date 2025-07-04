```
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
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
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

#  kubectl -n <namespace> create secret tls boge-com-tls --key boge.key --cert boge.csr

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: new-nginx
  labels:
    app: new-nginx
spec:
  replicas: 2
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
#        image: nginx:1.25.1
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
        image: registry.cn-shanghai.aliyuncs.com/acs/busybox:v1.29.2
#        image: nicolaka/netshoot
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


```

