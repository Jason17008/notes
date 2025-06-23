https://blog.csdn.net/weixin_46887489/article/details/134982607?spm=1001.2014.3001.5502



RBAC里面的几种资源关系图，下面将用下面的资源来演示生产中经典的RBAC应用

```
                  |--- Role --- RoleBinding                只在指定namespace中生效
ServiceAccount ---|
                  |--- ClusterRole --- ClusterRoleBinding  不受namespace限制，在整个K8s集群中生效

```

1. 创建对指定namespace有只读权限的kube-config

```
#!/bin/bash

export KUBECONFIG=/root/.kube/config

BASEDIR="$(dirname "$0")"
folder="$BASEDIR/kube_config"

echo -e "All namespaces is here: \n$(kubectl get ns|awk 'NR!=1{print $1}')"
echo "endpoint server if local network you can use $(kubectl cluster-info |awk '/Kubernetes/{print $NF}')"

clustername=$1
endpoint=$(echo "$2" | sed -e 's,https\?://,,g')

if [[ -z "$endpoint" || -z "$clustername" ]]; then
	echo "Use "$(basename "$0")" CLUSTERNAME ENDPOINT";
	exit 1;
fi

# https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.24.md#urgent-upgrade-notes
echo "---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: all-readonly-${clustername}
  namespace: kube-system
---
apiVersion: v1
kind: Secret
metadata:
  name: all-readonly-secret-sa-$clustername-user
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: "all-readonly-${clustername}"
type: kubernetes.io/service-account-token
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: all-readonly-${clustername}
rules:
- apiGroups:
  - ''
  resources:
  - configmaps
  - endpoints
  - persistentvolumes
  - persistentvolumeclaims
  - pods
  - replicationcontrollers
  - replicationcontrollers/scale
  - serviceaccounts
  - services
  - nodes
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ''
  resources:
  - bindings
  - events
  - limitranges
  - namespaces/status
  - pods/log
  - pods/status
  - replicationcontrollers/status
  - resourcequotas
  - resourcequotas/status
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ''
  resources:
  - namespaces
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - controllerrevisions
  - daemonsets
  - deployments
  - deployments/scale
  - replicasets
  - replicasets/scale
  - statefulsets
  - statefulsets/scale
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - autoscaling
  resources:
  - horizontalpodautoscalers
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - cronjobs
  - jobs
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - deployments/scale
  - ingresses
  - networkpolicies
  - replicasets
  - replicasets/scale
  - replicationcontrollers/scale
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - policy
  resources:
  - poddisruptionbudgets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - networking.k8s.io
  resources:
  - networkpolicies
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - metrics.k8s.io
  resources:
  - pods
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - storage.k8s.io
  resources:
  - storageclasses
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: all-readonly-${clustername}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: all-readonly-${clustername}
subjects:
- kind: ServiceAccount
  name: all-readonly-${clustername}
  namespace: kube-system" | kubectl apply -f -

mkdir -p $folder
#tokenName=$(kubectl get sa all-readonly-${clustername} -n $namespace -o "jsonpath={.secrets[0].name}")
tokenName="all-readonly-secret-sa-$clustername-user"
token=$(kubectl get secret $tokenName -n kube-system -o "jsonpath={.data.token}" | base64 --decode)
certificate=$(kubectl get secret $tokenName -n kube-system -o "jsonpath={.data['ca\.crt']}")

echo "apiVersion: v1
kind: Config
preferences: {}
clusters:
- cluster:
    certificate-authority-data: $certificate
    server: https://$endpoint
  name: all-readonly-${clustername}
users:
- name: all-readonly-${clustername}
  user:
    as-user-extra: {}
    client-key-data: $certificate
    token: $token
contexts:
- context:
    cluster: all-readonly-${clustername}
    user: all-readonly-${clustername}
  name: ${clustername}
current-context: ${clustername}" > $folder/${clustername}-all-readonly.conf



```





2.创建对指定namespace有所有权限的kube-config（在已有的namespace中创建）

```
# same ServiceAccount:" test-a-user " default can contorl my own namespace:" test-a " and config later to contorl other namespace: "test-b"

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: test-b-user-full-access
  namespace: test-b
rules:
- apiGroups: ['', 'extensions', 'apps', 'metrics.k8s.io', 'networking.k8s.io']
  resources: ['*']
  verbs: ['*']
- apiGroups: ['batch']
  resources:
  - jobs
  - cronjobs
  verbs: ['*']
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: test-b-user-full-access-both-test-a-user
  namespace: test-b
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: test-b-user-full-access
subjects:
- kind: ServiceAccount
  name: test-a-user
  namespace: test-a


```

1. 在已有sa上附加其他命名空间的权限

   ```
   # same ServiceAccount:" test-a-user " default can contorl my own namespace:" test-a " and config later to contorl other namespace: "test-b"
   
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     name: test-b-user-full-access
     namespace: test-b
   rules:
   - apiGroups: ['', 'extensions', 'apps', 'metrics.k8s.io', 'networking.k8s.io']
     resources: ['*']
     verbs: ['*']
   - apiGroups: ['batch']
     resources:
     - jobs
     - cronjobs
     verbs: ['*']
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: RoleBinding
   metadata:
     name: test-b-user-full-access-both-test-a-user
     namespace: test-b
   roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: Role
     name: test-b-user-full-access
   subjects:
   - kind: ServiceAccount
     name: test-a-user
     namespace: test-a
   
   
   ```

   





运行传参

查看api服务器地址
kubectl cluster-info
Kubernetes control plane is running at https://172.16.15.110:6443





运行命令 sh 1.sh  test   https://172.16.15.110:6443

运行完成之后 出现kube-config文件  



