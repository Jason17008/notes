- 查看证书上过期时间：

kubeadm alpha certs check-expiration

- 查看配置文件并输出到yaml里：

kubeadm config view > kubeadm-cluster.yaml

3，备份文件：

cp -ar /etc/kubernetes/ /etc/kubernetesbak-20220805 (备份k8s文件)

cp /root/.kube/config /root/.kube/config-20220805 (备份配置文件)

- 更新所有证书：

kubeadm alpha certs renew all --config=kubeadm-cluster.yaml

- 再次查看证书过期时间：

kubeadm alpha certs check-expiration

6，重启服务：

docker ps |grep -E 'k8s_kube-apiserver|k8s_kube-controller-manager|k8s_kube-scheduler|k8s_etcd_etcd' | awk -F ' ' '{print $1}' |xargs docker restart

7，新配置文件覆盖掉原配置文件：

cp -af /etc/kubernetes/admin.conf /root/.kube/config