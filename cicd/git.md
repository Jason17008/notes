Git 全局设置:

```
git config --global user.name "11111"
git config --global user.email "z1111@163.com"
```

创建 git 仓库:

```
mkdir go-chromedp
cd go-chromedp
git init 
touch README.md
git add README.md
git commit -m "first commit"
git remote add origin(自定义仓库名字) https://gitee.com/zed118928/go-chromedp.git
git push -u origin "master"
```

已有仓库?

```
cd existing_git_repo
git remote add origin https://gitee.com/zed118928/go-chromedp.git
git push -u origin "master"
```

# git拉取代码

```
  git clone <repository_url>
  cd <repository_name>
  git branch -a
  git checkout <branch_name>
  git pull origin <branch_name>

  具体解释看下面 
   
   git clone <repository_url>
   ```
   将 `<repository_url>` 替换为你要拉取的代码库的 URL。你可以在代码库的页面上找到它。

4. 进入你刚刚克隆的代码库目录。使用 `cd` 命令来进入目录。例如：
   ```
   cd <repository_name>
   ```
   `<repository_name>` 是你克隆的代码库的名称。

5. 使用以下命令来查看当前所有分支并选择要拉取的分支：
   ```
   git branch -a
   ```
   这将列出所有可用的分支，本地分支以及远程分支。

6. 使用以下命令来切换到你想要拉取的分支：
   ```
   git checkout <branch_name>
   ```
   将 `<branch_name>` 替换为你要拉取的分支名称。

7. 最后，使用 `git pull` 命令来拉取代码库的最新更改：
   ```
   git pull origin <branch_name>
   ```
   这将从远程分支拉取最新的更改并合并到你的本地分支中。
   
```

注意下  git里面不能套git 仓库 否则会上传的是空目录 

git 推送代码

```
git  init

git  status

git add .

 git commit -m "go日报飞书脚本"

git config --global user.email "you@example.com"

 git config --global  user.name "Your Name"

cd existing_repo
git remote add origin https://gitlab.com/admin-liu/ci_test.git
git branch-m main
 git push -uf origin main
```

# 总结一下  从0到1创建分支 到gitlab中

创造一个分支

git branch pikaqiu 来创建一个新的分支

切换分支

git check  pikaqiu

初始化

git init

添加文件 git add .

提交备注

git commit -m “备注内容 ”

添加要推送的源

git remote add pikaqiiu  git@gitlab.paigod.work:pikaqiu/fr.git

之前要添加ssh公钥

推送

 git push --set-upstream pikaqiu1 pikaqiu1