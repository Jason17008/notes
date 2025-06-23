生产中的小技巧：k8s删除namespaces状态一直为terminating问题处理

```
# kubectl get ns
NAME              STATUS        AGE
default           Active        5d4h
ingress-nginx     Active        30h
kube-node-lease   Active        5d4h
kube-public       Active        5d4h
kube-system       Active        5d4h
kubevirt          Terminating   2d2h   # <------ here

1、新开一个窗口运行命令  kubectl proxy
> 此命令启动了一个代理服务来接收来自你本机的HTTP连接并转发至API服务器，同时处理身份认证

2、新开一个终端窗口，将下面shell脚本整理到文本内`1.sh`并执行，$1参数即为删除不了的ns名称
#------------------------------------------------------------------------------------
#!/bin/bash

set -eo pipefail

die() { echo "$*" 1>&2 ; exit 1; }

need() {
        which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

# checking pre-reqs

need "jq"
need "curl"
need "kubectl"

PROJECT="$1"
shift

test -n "$PROJECT" || die "Missing arguments: kill-ns <namespace>"

kubectl proxy &>/dev/null &
PROXY_PID=$!
killproxy () {
        kill $PROXY_PID
}
trap killproxy EXIT

sleep 1 # give the proxy a second

kubectl get namespace "$PROJECT" -o json | jq 'del(.spec.finalizers[] | select("kubernetes"))' | curl -s -k -H "Content-Type: application/json" -X PUT -o /dev/null --data-binary @- http://localhost:8001/api/v1/namespaces/$PROJECT/finalize && echo "Killed namespace: $PROJECT"
#------------------------------------------------------------------------------------

3. 执行脚本删除
# bash 1.sh kubevirt
Killed namespace: kubevirt
1.sh: line 23: kill: (9098) - No such process

5、查看结果
# kubectl get ns    
NAME              STATUS   AGE
default           Active   5d4h
ingress-nginx     Active   30h
kube-node-lease   Active   5d4h
kube-public       Active   5d4h
kube-system       Active   5d4h

```