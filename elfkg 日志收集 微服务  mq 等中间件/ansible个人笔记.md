# ansible 个人总结笔记

<
https://releases.ansible.com/ansible/>   安装的官网 

<https://blog.51cto.com/u_13236892/5271230>  升级的话 看这个 

### Ansible 的核心概念

- **Inventory（清单）**：定义了Ansible管理的目标主机列表及其相关信息。
- **Playbook（剧本）**：使用YAML编写的文件，描述了Ansible需要执行的一系列任务。
- **Modules（模块）**：执行具体任务的独立单元，如文件复制、服务控制等。
- **Tasks（任务）**：Playbook中的每个条目，代表一个具体的动作。
- **Handlers（处理器）**：响应特定事件触发的任务，通常用于重启服务等。
- **Variables（变量）**：用于存储和传递数据，使得Playbook更具灵活性。
- **Plugins（插件）**：扩展Ansible的功能，如连接插件、回调插件等

# gather_facts

`gather_facts` 是一个控制选项，用于定义Ansible在执行任务之前是否应该收集目标主机的硬件信息和其他系统配置详情。
Ansible会在开始执行playbook前从远程主机上收集这些信息，这有助于Ansible了解目标系统的状态，并根据收集到的信息进行更智能的操作。

当你在Ansible的Play中设置 `gather_facts: no`

Ansible将不会花费时间去收集这些信息。这对于只需要执行一些简单的操作而不关心目标主机具体状态的情况非常有用，可以加快执行速度。

# ansible中导入变量

## 1.在Playbook内直接定义： 在Playbook的YAML文件中可以直接定义变量。例如：

```
- name: Example playbook
  hosts: all
  vars:
    web_port: 8080
    app_name: myapp

  tasks:
    - name: Print the port number
      ansible.builtin.debug:
        msg: "The web server runs on port {{ web_port }}"
```

## 2. 通过vars_files导入变量：

可以使用`vars_files`关键字来指定包含变量定义的YAML或JSON文件。例如，在`vars/main.yml`文件中定义变量，然后在Playbook中引用它：

```
# vars/main.yml
web_port: 8080
app_name: myapp
```

在Playbook中引用：

```
- name: Example playbook
  hosts: all
  vars_files:
    - vars/main.yml

  tasks:
    - name: Print the port number
      ansible.builtin.debug:
        msg: "The web server runs on port {{ web_port }}"
```

## 3.使用vars关键字导入变量

**使用vars关键字导入变量**

```
- name: Example playbook
  hosts: all
  vars:
    - include_vars: vars/main.yml
  tasks:
    ...
```

## 4.	从命令行传递变量

可以通过命令行参数传递变量给Playbook。例如：

```
ansible-playbook -e "web_port=8080" site.yml
```

## 5.使用group_vars和host_vars目录

nsible允许为特定的主机组或单个主机定义变量。在`group_vars/all`或`host_vars/hostname`文件中定义的变量会自动应用于对应的组或主机。

**6.从环境变量导入**：
Ansible可以从环境变量中读取值，比如：

```
export WEB_PORT=8080
ansible-playbook site.yml
```

在Playbook中访问该环境变量：

```
- name: Example playbook
  hosts: all
  vars:
    web_port: "{{ lookup('env', 'WEB_PORT') }}"

  tasks:
    ...
```

**7.使用inventory管理器定义变量**

在inventory文件中，可以在主机或组条目后面添加变量。例如

```
[webservers]
host1.example.com web_port=8080
```

**使用register关键字注册变量**：

```
- name: Get facts about the system
  ansible.builtin.setup:
  register: host_facts

- name: Print the kernel version
  ansible.builtin.debug:
    msg: "Kernel version is {{ host_facts.ansible_facts.kernels }}"
```

# ansible 中 迭代  与item 变量 

`loop`不是一个单独的模块，而是一个更为通用的概念，用于在任务中迭代一系列项目。`loop`通常与任务中的各种模块一起使用，以便对一组项目执行相同的操作。这可以是文件列表、用户列表、服务列表等。

例子如下 

```
 - name: copy files in current path
   copy:
     src: ./files/{{ item }}
     dest: '/tmp/es'
     owner: '{{ ansible_ssh_user }}'
     group: '{{ ansible_ssh_user }}'
   loop:
     - install_ES.sh
     - elasticsearch.service
     - elasticsearch.sh
     - '{{ softwarename }}.tar.gz'
     - login.sh
     - install-es.log
     - utils.sh
   become: yes

```

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1725848271320-6b8f5743-5e09-47f6-bea1-8aac4dabf2bb.png)

结合with_items

虽然`loop`是一个更现代的方式，但之前的版本中常用的是`with_items`。为了向后兼容，仍然可以看到它的使用，尽管推荐使用`loop`

```
- name: Create multiple users (legacy style)
  ansible.builtin.user:
    name: "{{ item }}"
    state: present
  with_items:
    - john
    - jane
    - doe
```

# include_tasks:

include_tasks: init-base-data.yml

在Ansible中，`include_tasks` 指令用于在当前的Playbook中包含另一个任务文件。这有助于组织代码，使Playbook更加模块化和可维护。`include_tasks` 通常用于将重复或通用的任务分离到单独的文件中，然后在多个Playbook或Play中重用这些任务。

# 什么是Jinja2？

Jinja2是一个用于生成文本输出的强大工具，它可以解析模板中的标签、过滤器和测试，以及执行基本的逻辑操作，如条件判断和循环。这使得你可以创建复杂的模板，这些模板可以根据变量的值动态地生成内容。

### Ansible中的应用

在Ansible中，Jinja2模板通常用于以下场景：

1. **生成配置文件**：你可以使用Jinja2模板来根据不同的环境或需求生成特定的配置文件。例如，你可以创建一个Web服务器配置文件的模板，该模板可以根据变量动态改变监听端口、文档根目录等。
2. **参数化任务**：除了配置文件之外，你还可以使用Jinja2来参数化Ansible的任务。例如，你可以使用变量来控制哪些服务应该启动或停止。
3. **生成脚本**：有时候你可能需要生成脚本来执行一些操作，这些脚本同样可以通过Jinja2模板生成。

### 基本语法

Jinja2模板的基本语法包括：

- **变量**：使用双大括号 `{}` 包围的变量名称，例如 `{{ variable_name }}`。
- **块标签**：使用 `{% %}` 包围的块标签，例如 `{% for item in items %}` 和 `{% if condition %}`。
- **过滤器**：可以在变量后面加上管道符号 `|` 来使用过滤器，例如 `{{ var | upper }}`。

### 示例

下面是一个简单的Jinja2模板示例，展示如何生成一个包含主机名和监听端口的配置文件：

#### 配置文件模板 `nginx.conf.j2`：

```
server {
    listen {{ web_port }};
    server_name {{ ansible_hostname }};

    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
    }
}
```

#### Ansible Playbook 任务：

```
- name: Configure web server
  hosts: webservers
  tasks:
    - name: Copy nginx configuration
      ansible.builtin.template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: '0644'
      vars:
        web_port: 80
```

在这个例子中，`template` 模块将会读取 `nginx.conf.j2` 模板文件，并使用变量 `web_port` 和 `ansible_hostname` 的值来生成最终的配置文件 `/etc/nginx/nginx.conf`。

### 总结

Jinja2模板是Ansible中一个非常强大的特性，它使得你可以创建高度动态的配置文件和其他文本输出。通过使用Jinja2，你可以使你的配置管理更加灵活，适应不同的环境和需求。

# ansible中特有的内置变量

```
ansible_hostname
描述：表示目标主机的本地主机名。
示例：{{ ansible_hostname }}
ansible_fqdn
描述：表示目标主机的完全限定域名（FQDN）。
示例：{{ ansible_fqdn }}
ansible_all_ipv4_addresses
描述：包含目标主机的所有IPv4地址的列表。
示例：{{ ansible_all_ipv4_addresses }}
ansible_all_ipv6_addresses
描述：包含目标主机的所有IPv6地址的列表。
示例：{{ ansible_all_ipv6_addresses }}
ansible_distribution
描述：表示目标主机的操作系统发行版名称。
示例：{{ ansible_distribution }}
ansible_distribution_major_version
描述：表示目标主机的操作系统发行版的主要版本号。
示例：{{ ansible_distribution_major_version }}
ansible_distribution_release
描述：表示目标主机的操作系统发行版的代号或发布名称。
示例：{{ ansible_distribution_release }}
ansible_os_family
描述：表示目标主机操作系统所属的家族，如RedHat、Debian等。
示例：{{ ansible_os_family }}
ansible_processor_vcpus
描述：表示目标主机的逻辑CPU数量。
示例：{{ ansible_processor_vcpus }}
ansible_memtotal_mb
描述：表示目标主机的总内存大小（以MB为单位）。
示例：{{ ansible_memtotal_mb }}
inventory_hostname
描述：表示目标主机在Inventory文件中的名称。
示例：{{ inventory_hostname }}
groups
描述：表示目标主机所在的主机组。
示例：{{ groups['webservers'] }} 将返回webservers组中的所有主机。
item
描述：当在任务中使用loop时，表示当前迭代的项。
示例：{{ item }}
ansible_play_hosts
描述：表示当前Play中的活动主机列表。
示例：{{ ansible_play_hosts }}
ansible_play_hosts_all
描述：表示所有Play中的活动主机列表。
示例：{{ ansible_play_hosts_all }}
ansible_play_hosts_in_play
描述：表示当前Play中的活动主机列表。
示例：{{ ansible_play_hosts_in_play }}
ansible_play_hosts_matched
描述：表示匹配当前Play模式的主机列表。
示例：{{ ansible_play_hosts_matched }}
ansible_play_hosts_unmatched
描述：表示未匹配当前Play模式的主机列表。
示例：{{ ansible_play_hosts_unmatched }}
ansible_play_hosts_skipped
描述：表示当前Play中被跳过的主机列表。
示例：{{ ansible_play_hosts_skipped }}
ansible_play_hosts_failed
描述：表示当前Play中失败的主机列表。
示例：{{ ansible_play_hosts_failed }}
ansible_play_hosts_ok
描述：表示当前Play中成功的主机列表。
示例：{{ ansible_play_hosts_ok }}
ansible_play_hosts_changed
描述：表示当前Play中状态发生改变的主机列表。
示例：{{ ansible_play_hosts_changed }}
ansible_play_hosts_rescued
描述：表示当前Play中被救援的主机列表。
示例：{{ ansible_play_hosts_rescued }}
ansible_play_hosts_ignored
描述：表示当前Play中被忽略的主机列表。
示例：{{ ansible_play_hosts_ignored }}
```

# 我现在有一堆ansible-playbook 我每次都要按照指定的顺序 一个一个安装 我现在想在这些ansible-plyabook 整合起来 完成一键部署自动化 如何操作 请给我点思路 

### 整合多个独立的Ansible Playbook，实现一键部署自动化，可以通过以下步骤来完成：

### 1. 组织Playbook结构

首先，你需要将现有的Playbook组织成一个合理的目录结构。通常，你可以按功能或按服务来组织Playbook。例如，你可以创建一个`playbooks`目录，并在其中创建子目录来存放不同的Playbook。

例如，目录结构可能如下所示：

```
深色版本

1project/
2├── playbooks/
3│   ├── 01-setup-hosts.yml
4│   ├── 02-install-packages.yml
5│   ├── 03-configure-services.yml
6│   ├── 04-deploy-applications.yml
7│   └── main.yml
8└── roles/
9    └── common/
10        ├── tasks/
11        │   └── main.yml
12        ├── files/
13        ├── templates/
14        └── handlers/
15            └── main.yml
```

### 2. 创建主Playbook (`main.yml`)

在`project/playbooks`目录下创建一个`main.yml`文件作为主Playbook，用于依次调用其他Playbook。

#### `main.yml` 示例：

```
yaml


深色版本

1- name: Main deployment playbook
2  hosts: all
3
4  pre_tasks:
5    - name: Include pre-tasks
6      ansible.builtin.import_tasks: pre-tasks.yml
7
8  roles:
9    - role: common
10
11  tasks:
12    - name: Include setup hosts tasks
13      ansible.builtin.import_tasks: 01-setup-hosts.yml
14
15    - name: Include install packages tasks
16      ansible.builtin.import_tasks: 02-install-packages.yml
17
18    - name: Include configure services tasks
19      ansible.builtin.import_tasks: 03-configure-services.yml
20
21    - name: Include deploy applications tasks
22      ansible.builtin.import_tasks: 04-deploy-applications.yml
```

### 3. 使用`import_tasks`或`include_tasks`

在主Playbook中，可以使用`import_tasks`或`include_tasks`来引入其他Playbook文件。`import_tasks`会立即执行导入的任务，而`include_tasks`则在执行到该指令时才加载并执行任务。

- `import_tasks`: 适用于静态包含，即在Playbook加载时就包含进来。
- `include_tasks`: 适用于动态包含，即在执行到该指令时才加载并执行任务。

### 4. 使用条件控制

根据需要，你可以在包含其他Playbook时添加条件控制，确保只在特定条件下执行某些任务。

```
yaml


深色版本

1- name: Include deploy applications tasks if OS is Ubuntu
2  ansible.builtin.include_tasks: 04-deploy-applications.yml
3  when: ansible_os_family == 'Debian'
```

### 5. 使用Roles

为了更好地组织和复用代码，你可以将一些通用的任务封装到Roles中。每个Role包含多个文件夹，如`tasks`、`files`、`templates`和`handlers`。

#### `roles/common/tasks/main.yml` 示例：

```
yaml


深色版本

1- name: Ensure common packages are installed
2  ansible.builtin.package:
3    name: "{{ item }}"
4    state: present
5  loop:
6    - curl
7    - unzip
```

### 6. 设置Inventory

确保你的Inventory文件正确配置了所有目标主机的信息。

#### `inventory.ini` 示例：

```
ini


深色版本

1[webservers]
2web01.example.com
3web02.example.com
4
5[dbservers]
6db01.example.com
7db02.example.com
```

### 7. 执行主Playbook

最后，执行主Playbook来完成一键部署。

```
bash


深色版本

1ansible-playbook -i inventory.ini playbooks/main.yml
```

### 8. 考虑使用动态Inventory

如果你的目标主机信息经常变化，可以考虑使用动态Inventory脚本，这样可以在执行Playbook时动态生成主机列表。

#### 动态Inventory脚本示例 (`inventory.py`)：

```
python


深色版本

1#!/usr/bin/env python
2
3import json
4
5inventory = {
6    '_meta': {'hostvars': {}},
7    'webservers': {'hosts': ['web01.example.com', 'web02.example.com']},
8    'dbservers': {'hosts': ['db01.example.com', 'db02.example.com']}
9}
10
11print(json.dumps(inventory))
```

### 总结

通过以上步骤，你可以将多个独立的Ansible Playbook整合到一个主Playbook中，实现一键部署自动化。这种方法不仅提高了部署效率，还使得整个过程更加清晰和易于维护。

j2 模板

```
{% if 'localhost' == bind %}bind 127.0.0.1 {{ curHost }}{% elif '0.0.0.0' == bind %}bind 0.0.0.0{% endif %}

port {{ redis_listen_port }}
# unixsocket /tmp/redis-{{ redis_listen_port }}.sock
# unixsocketperm 700

timeout 0
tcp-keepalive 300

# maxclients 10000
maxmemory {{ max_memory }}
maxmemory-policy noeviction

# 后台启动
daemonize yes
supervised systemd
pidfile '{{ path }}/redis/logs/redis-{{ redis_listen_port }}.pid'

loglevel notice
logfile '{{ path }}/redis/logs/redis-{{ redis_listen_port }}.log'

syslog-enabled yes
syslog-ident redis

databases 16

# save 900 1
# save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dir {{ path }}/redis/data
dbfilename dump.rdb

# Auth Password Configuration
requirepass '{{ redis_auth_pass }}'

appendonly yes
appendfilename 'appendonly.aof'

# appendfsync always
appendfsync everysec
# appendfsync no
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes

lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
notify-keyspace-events ''
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-entries 512
list-max-ziplist-value 64
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value -2
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes




if 语句：根据变量 bind 的值来设置 Redis 的绑定地址。如果 bind 是 'localhost'，则绑定到本地回环地址 127.0.0.1 和当前主机名；如果是 '0.0.0.0'，则绑定到所有网络接口。
port：设置 Redis 监听的端口，这里的端口号是由变量 redis_listen_port 动态决定的。
timeout：客户端空闲超时时间设置为 0，表示客户端永远不会因为超时而断开连接。
tcp-keepalive：TCP 保持连接活跃的时间间隔设为 300 秒。
maxmemory：设置 Redis 最大内存限制，该值由变量 max_memory 决定。
maxmemory-policy：当达到最大内存限制时采用的策略是 noeviction，意味着当内存不足以容纳新写入的数据时，Redis 将停止写操作。
daemonize：设置 Redis 以后台方式运行。
supervised：指示 Redis 由 systemd 进程管理工具监督。
pidfile：指定 Redis 进程 ID 文件的位置。
loglevel 和 logfile：设置日志级别和日志文件的位置。
syslog-enabled 和 syslog-ident：启用系统日志，并设置 Redis 在系统日志中的标识。
databases：定义 Redis 中可用数据库的数量。
save：设置 RDB 快照保存条件。
rdbcompression 和 rdbchecksum：开启 RDB 文件压缩和校验。
dir 和 dbfilename：指定 RDB 文件存储目录和文件名。
requirepass：设置 Redis 的访问密码。
appendonly 及相关选项：开启 AOF 日志持久化，并配置其行为。
lua-time-limit：设置执行 Lua 脚本的时间限制。
slowlog-log-slower-than 和 slowlog-max-len：设置慢查询日志记录的阈值和最大长度。
notify-keyspace-events：配置通知事件。
hash-max-ziplist-entries 等选项：配置不同数据结构的压缩列表限制。
activerehashing：控制哈希表 rehashing 的线程安全性。
client-output-buffer-limit：设置客户端输出缓冲区的限制。
hz：设置调度循环频率。
aof-rewrite-incremental-fsync：配置 AOF 文件重写期间的增量 fsync 行为。
这个配置模板允许通过替换模板中的占位符来生成具体的 Redis 配置文件，适用于自动化部署和配置管理场景。
```

# ignore_errors

`nore_errors` 是一个任务级别的选项，用于控制当任务执行失败时 Ansible 的行为。当你在一个任务定义中设置了 `ignore_errors: true`（或简写为 `ignore_errors: yes`），这意味着即使该任务失败，Ansible 也会继续执行后续的任务，而不是立即停止并标记主机的状态为失败。

默认情况下，如果一个任务在某台主机上失败了，Ansible 会认为该主机已经处于失败状态，并且不会在这台主机上继续执行 Playbook 中剩下的任务。但是，有时候你可能希望即使某个任务失败了，Playbook 也能继续执行下去，特别是在进行清理工作或执行非关键性的操作时。

例如，假设你有一个 Playbook，其中包含删除旧文件的任务，然后是安装软件包的任务。如果删除旧文件的任务在某些主机上失败了，但你知道这并不影响后续安装任务的成功执行，那么可以在删除任务中使用 `ignore_errors` 选项，确保即使删除失败，安装任务仍然会被执行。

# ansible中报错 没找到环境解释器 

需要在hosts 文件下 增加

ansible_python_interpreter=/usr/bin/python3   

指定使用python3的解释器 

# 排查

 ansible-playbook -i hostsrou openjdk.yml -vvv  

-vvv 细节排查 

# 想要刷新环境变量

```
- name: source bashrc
  become: true
  command: "bash ~/.bashrc"

- name: source ~/.bashrc
  shell: "source ~/.bashrc"
  args:
    executable: /bin/bash

```

要注意的是什么点呢  

![img](https://cdn.nlark.com/yuque/0/2024/jpeg/35538885/1726194788750-191a00af-5746-4505-a4b3-725ee7df5a5f.jpeg)

ansible 用的是 non-login shell 

如果说ansible 调用 shell 命令 还找不到java的变量 注释下 ~/.bashrc 

```
case $- in
    *i*) ;;
      *) return;;
esac
```

因为这几行判断接口调用的时候 返回return

# 遇到问题 bocome true 提权之后 找不到命令

在用户目录下 环境变量   有的 在root下也有环境变量的 

但是become true 就是找不到环境变量 

become_user:devops   在task 上加上对应 用户执行  