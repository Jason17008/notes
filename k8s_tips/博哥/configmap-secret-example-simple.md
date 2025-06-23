```
---
# configmap
# kubectl create configmap localconfig-env --from-literal=log_level_test=TEST --from-literal=log_level_produce=PRODUCE
apiVersion: v1
kind: ConfigMap
metadata:
  name: localconfig-env
data:
  log_level_test: TEST
  log_level_produce: PRODUCE

---
# configmap
# kubectl create configmap localconfig-file --from-file=localconfig-test=localconfig-test.conf --from-file=localconfig-produce=localconfig-produce.conf
apiVersion: v1
kind: ConfigMap
metadata:
  name: localconfig-file
data:
  localconfig-produce: |
    TEST_RELEASE = False
    PORT = 80
    PROCESSES = 0
    MESSAGE = Produce
  localconfig-test: |
    TEST_RELEASE = True
    PORT = 8080
    PROCESSES = 1
    MESSAGE = Test

---
# secret
# kubectl create secret generic mysecret --from-literal=mysql-root-password='BogeMysqlPassword' --from-literal=redis-root-password='BogeRedisPassword' --from-file=my_id_rsa=/root/.ssh/id_rsa --from-file=my_id_rsa_pub=/root/.ssh/id_rsa.pub
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
  namespace: default
type: Opaque
data:
  my_id_rsa: bXlfaWRfcnNhCg==
  my_id_rsa_pub: bXlfaWRfcnNhX3B1Ygo=
  mysql-root-password: Qm9nZU15c3FsUGFzc3dvcmQ=
  redis-root-password: Qm9nZVJlZGlzUGFzc3dvcmQ=

---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    run: test-busybox
  name: test-busybox
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      run: test-busybox
  template:
    metadata:
      labels:
        run: test-busybox
    spec:
      containers:
      - name: test-busybox
        image: registry.cn-shanghai.aliyuncs.com/acs/busybox:v1.29.2

        args:
          - /bin/sh
          - -c
          - >
              echo "-------------------------------------------------";
              echo "TEST_ENV is:$(TEST_ENV)";
              echo "-------------------------------------------------";
              echo "PRODUCE_ENV is:$(PRODUCE_ENV)";
              echo "-------------------------------------------------";
              echo "secret MYSQL_ROOT_PASSWORD is:$(MYSQL_ROOT_PASSWORD)";
              echo "-------------------------------------------------";
              echo "secret REDIS_ROOT_PASSWORD is:$(REDIS_ROOT_PASSWORD)";
              echo "-------------------------------------------------";
              echo "/etc/local_config_test.py body is:";
              cat /etc/local_config_test.py;
              echo "-------------------------------------------------";
              echo "/etc/local_config_produce.py body is:";
              cat /etc/local_config_produce.py;
              echo "-------------------------------------------------";
              echo "/etc/id_rsa body is:";
              cat /etc/id_rsa;
              echo "-------------------------------------------------";
              echo "/etc/id_rsa.pub body is:";
              cat /etc/id_rsa.pub;
              echo "-------------------------------------------------";
              ls -ltr /etc;
              sleep 30000;
        env:
          - name: TEST_ENV
            valueFrom:
              configMapKeyRef:
                name: localconfig-env
                key: log_level_test
          - name: PRODUCE_ENV
            valueFrom:
              configMapKeyRef:
                name: localconfig-env
                key: log_level_produce
          - name: MYSQL_ROOT_PASSWORD
            valueFrom:
              secretKeyRef:
                name: mysecret
                key: mysql-root-password
          - name: REDIS_ROOT_PASSWORD
            valueFrom:
              secretKeyRef:
                name: mysecret
                key: redis-root-password
        volumeMounts:
        - name: testconfig
          mountPath: "/etc/local_config_test.py"
          subPath: localconfig-test
        - name: testconfig
          mountPath: "/etc/local_config_produce.py"
          subPath: localconfig-produce
          readOnly: true
        - name: testsecret
          mountPath: "/etc/id_rsa"
          subPath: my_id_rsa
          readOnly: true
        - name: testsecret
          mountPath: "/etc/id_rsa.pub"
          subPath: my_id_rsa_pub
          readOnly: true

      volumes:
      - name: testconfig
        configMap:
          name: localconfig-file
          defaultMode: 0660
      - name: testsecret
        secret:
          secretName: mysecret
          defaultMode: 0600


```

