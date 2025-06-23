https://blog.csdn.net/weixin_46887489/article/details/134897931?spm=1001.2014.3001.5502





```
# 在集群所有节点上添加两块硬盘并挂载目录
mkfs.ext4 /dev/sdb
mkfs.ext4 /dev/sdc
# cat /etc/fstab
/dev/sdb /mnt/longhorn-sdb ext4 defaults 0 1
/dev/sdc /mnt/longhorn-sdc ext4 defaults 0 1
#
mount -a
df -Th|grep -E 'longhorn-sdb|longhorn-sdc'


# 配置节点信息
metadata:
labels:
    node.longhorn.io/create-default-disk: "config"
annotations:
    node.longhorn.io/default-disks-config: '[
    {
        "path":"/mnt/longhorn-sdb",
        "allowScheduling":true
    },
    {    
        "path":"/mnt/longhorn-sdc",
        "allowScheduling":true
    }
]'


# 利用helm安装longhorn服务
wget https://github.com/longhorn/longhorn/archive/refs/tags/v1.5.3.zip
unzip longhorn-1.5.3.zip
rm longhorn-1.5.3.zip
cd longhorn-1.5.3/
helm install longhorn ./chart/ --namespace longhorn-system --create-namespace --set defaultSettings.createDefaultDiskLabeledNodes=true --dry-run --debug
helm install longhorn ./chart/ --namespace longhorn-system --create-namespace --set defaultSettings.createDefaultDiskLabeledNodes=true
kubectl -n longhorn-system get pod -o wide -w


# 测试挂载存储
# kubectl get sc
NAME                          PROVISIONER          RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
longhorn (default)            driver.longhorn.io   Delete          Immediate           true                   64m


# cat test.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-claim
spec:
  storageClassName: longhorn
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi   # 实测最小存储分配为10Mi

---
kind: Pod
apiVersion: v1
metadata:
  name: test
spec:
  containers:
  - name: test
#    image: busybox:1.28.4
    image: registry.cn-shanghai.aliyuncs.com/acs/busybox:v1.29.2
    imagePullPolicy: IfNotPresent
    command:
      - "/bin/sh"
    args:
      - "-c"
      - "echo 'hello k8s' > /mnt/SUCCESS && sleep 36000 || exit 1"
    volumeMounts:
      - name: longhorn-pvc
        mountPath: "/mnt"
  restartPolicy: "Never"
  volumes:
    - name: longhorn-pvc
      persistentVolumeClaim:
        claimName: test-claim


# 写入严格限制大小
# kubectl exec -it test -- sh
/ # cd /mnt/
/mnt # ls -lh
total 13
-rw-r--r--    1 root     root          10 Dec  8 04:11 SUCCESS
drwx------    2 root     root       12.0K Dec  8 04:11 lost+found
/mnt # dd if=/dev/zero of=./test.log bs=1M count=11
dd: ./test.log: No space left on device



# 把ui的svc改成NodePort,查看页面，生产的话可以弄个ingress
# kubectl -n longhorn-system get svc longhorn-frontend
NAME                TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
longhorn-frontend   NodePort   10.68.135.61   <none>        80:31408/TCP   68m


```

##### Longhorn监控

https://longhorn.io/docs/1.5.3/monitoring/

##### Longhorn备份还原

https://longhorn.io/docs/1.5.3/snapshots-and-backups/