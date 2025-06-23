可以这么理解 这就是前端nvm

terraform的是 tfenv

类似 `nvm` 或 `pyenv`



```plain
bash

复制
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc  # 或 ~/.zshrc
source ~/.bashrc
```

#### **Windows (WSL2 或 Git Bash)**

建议在 WSL2 中按 Linux 方式安装。

------

### **2. 常用命令**

| **命令**                    | **作用**                                         |
| --------------------------- | ------------------------------------------------ |
| `tfenv --version`           | 检查 tfenv 是否安装成功                          |
| `tfenv list`                | 查看已安装的所有 Terraform 版本                  |
| `tfenv list-remote`         | 列出所有可安装的远程版本（包括最新和 beta 版本） |
| `tfenv install <version>`   | 安装指定版本（如 `1.5.7`）                       |
| `tfenv install latest`      | 安装最新稳定版                                   |
| `tfenv use <version>`       | 临时切换当前 shell 的版本                        |
| `tfenv uninstall <version>` | 卸载指定版本                                     |

------

### **3. 实战示例**

#### **(1) 安装特定版本**

```plain
bash

复制
# 安装 Terraform 1.5.7
tfenv install 1.5.7

# 验证安装
terraform version  # 输出：Terraform v1.5.7
```

#### **(2) 切换版本**

```plain
bash

复制
# 切换到 1.3.9（需已安装）
tfenv use 1.3.9

# 验证切换
terraform version  # 输出：Terraform v1.3.9
```

#### **(3) 为项目固定版本**

在项目根目录创建 `.terraform-version` 文件，写入版本号：

```plain
bash

复制
echo "1.5.7" > .terraform-version
```

此后进入项目目录时，`tfenv` 会自动切换到指定版本。

------

### **4. 高级用法**

#### **(1) 自定义镜像加速（国内用户）**

```plain
bash

复制
# 设置镜像地址（避免 GitHub 下载慢）
export TFENV_TERRAFORM_RELEASE_MIRROR=https://mirrors.aliyun.com/terraform
tfenv install 1.5.7
```

#### **(2) 全局默认版本**

```plain
bash

复制
# 设置全局默认版本（无 .terraform-version 文件时使用）
tfenv use 1.5.7 --default
```

#### **(3) 卸载 tfenv**

```plain
bash

复制
rm -rf ~/.tfenv
# 并从 shell 配置文件（如 .bashrc）中删除 PATH 相关行
```









之前的课程⾥，我们虽然了解了 Terraform 的⼀些基本操作，但是在实际⼯作中，当你接⼿ 

前⼈的代码，还是会遇到后⾯这类困难。 

因为 Terraform 在不同的版本存在⼀些兼容性问题，在 version.tf 中需要使⽤某个特定版 

本的 Terraform。

代码年久失修，仍在使⽤某个很⽼的 Terraform 版本，缺少⼀些新版本的特性。 

这时候你就需要⼀个 Terraform 版本管理⼯具，帮助你在不同的版本中切换。这⾥我们需要 

⽤到 tfenv 来帮助我们管理 Terraform 的版本，它的 GitHub 的地址是这个：

https://github.com/tfutils/tfenv。

如果你没有⽤过 tfenv，可以参考官⽅提供的⽅法进⾏安装。tfenv 的核⼼⽤法就是将远程 

的不同版本 Terraform 下载下来，然后通过改变环境变量来切换成指定版本。当你装好 tfenv 

之后，可以使⽤ list-remote 参数来查看所有的 terraform 的版本号，并指定所需要的版本。



```toml
root@devops:~# tfenv list-remote
```

然后，你可以使⽤ latest 的参数安装最新版本，也可以安装指定版本。

```toml
root@devops:~# tfenv install latest
 Installing Terraform v1.3.2
 Downloading release tarball from https://releases.hashicorp.com/terraform/1.3.2/t
 #################################################################################
 Downloading SHA hash file from https://releases.hashicorp.com/terraform/1.3.2/ter
 Not instructed to use Local PGP (/root/.tfenv/use-{gpgv,gnupg}) & No keybase inst
 Archive: /tmp/tfenv_download.cTS98Z/terraform_1.3.2_linux_amd64.zip
 inflating: /root/.tfenv/versions/1.3.2/terraform
 Installation of terraform v1.3.2 successful. To make this your default version, r
 root@devops:~/infra-automation/terraform/eks/example# tfenv install 1.2.0
 Installing Terraform v1.2.0
 Downloading release tarball from https://releases.hashicorp.com/terraform/1.2.0/t
 #################################################################################
 Downloading SHA hash file from https://releases.hashicorp.com/terraform/1.2.0/ter
 Not instructed to use Local PGP (/root/.tfenv/use-{gpgv,gnupg}) & No keybase inst
 Archive: /tmp/tfenv_download.TpmQi9/terraform_1.2.0_linux_amd64.zip
 inflating: /root/.tfenv/versions/1.2.0/terraform
 Installation of terraform v1.2.0 successful. To make this your default version, r
root@devops:~/infra-automation/terraform/eks/example# tfenv use 1.2.0
Switching default version to v1.2.0
Default version (when not overridden by .terraform-version or TFENV_TERRAFORM_VER
root@devops:~/infra-automation/terraform/eks/example#
```