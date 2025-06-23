linux-x86_64 手动安装

```
wget https://github.com/kubernetes-sigs/krew/releases/download/v0.4.5/krew-linux_amd64.tar.gz
tar zxvf krew-linux_amd64.tar.gz
./krew-linux_amd64 install krew

# 配置环境变量
echo 'export PATH=$PATH:$HOME/.krew/bin' >> ~/.bashrc
```





卸载krew

```
kubectl krew uninstall krew
rm -rf ~/.krew
```

