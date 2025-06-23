# **一、简介**

Terraform 是一种开源工具，它允许你通过代码来定义、预配和编排云计算服务。使用 Terraform，用户可以编写一个或多个配置文件，这些文件定义了你的基础设施需求，然后 Terraform 就可以自动地在云服务提供商上创建和管理这些资源。





特点：

自动化：通过代码定义基础设施，减少了手动配置的需求。

一致性：相同的配置可以用于不同的环境，如开发、测试和生产。

可重用：配置可以被重用和共享，提高了开发效率。

效率：自动化了基础设施的创建和维护，减少了手动操作的时间。





资源编排：

Terraform 类似于 AWS 控制台、腾讯云控制台等，都是用来管理你的云资源。不过，控制台是通过图形界面操作，而 Terraform 是通过配置文件来实现。





# 

# **二、关键概念**

## **1.****Provider(基础设施管理组件)**

Provider 是基础设施管理组件，它允许 Terraform 管理和控制特定的云服务提供商资源。每个云服务提供商都需要提供一个 Provider 来与 Terraform 集成。

## **2.****Resource (基础设施资源和服务的管理)**

### **（****1）定义资源及服务**

一个具体的资源或服务被称为一个 resource。例如，一台 ECS 实例、一个 VPC 网络或一个 SLB 实例。每个特定的 resource 包含了多个可用于描述对应资源或服务的属性字段。通过这些字段来定义一个完整的资源或服务，例如实例的名称 (name)、实例的规格 (instance_type)、VPC 或 VSwitch 的网段 (cidr_block) 等。





示例：定义一个ECS实例

resource "alicloud_instance" "default" {

image_id        = "ubuntu_16_04_64_20G_alibase_20190620.vhd"

instance_type   = "ecs.sn1ne.large"

instance_name   = "my-first-vm"

system_disk_category = "cloud_ssd"

...

}





在这个示例中:

alicloud_instance 表示资源类型（Resource Type），用于定义这个资源是阿里云的 ECS 实例。

default 表示资源名称（Resource Name），资源名称在同一个模块中必须是唯一的，主要用于供其他资源引用该资源。

大括号 { ... } 内部的 block 块表示配置参数（Configuration Arguments），用于定义资源的属性，例如 ECS 实例的规格、镜像、名称等。

显然，这个 Terraform 模板的功能是在阿里云上创建一个 ECS 实例，其镜像 ID 为 ubuntu_16_04_64_20G_alibase_20190620.vhd，规格为 ecs.sn1ne.large，并自定义了实例名称和系统盘的类型。





### **（****2）****资源之间的关系**

在 Terraform 中，一个资源与另一个资源的关系也被定义为一个资源。例如，一块云盘与一台 ECS 实例的挂载，一个弹性 IP（EIP）与一台 ECS 或 SLB 实例的绑定关系。这样定义的好处在于，一方面资源架构非常清晰，另一方面，当模板中有若干个 EIP 需要与若干台 ECS 实例绑定时，只需要通过 Terraform 的 count 功能就可以在无需编写大量重复代码的前提下实现绑定功能。





示例：定义多个 ECS 实例、EIP 和 EIP 关联

resource "alicloud_instance" "default" {

count = 5

...

}

resource "alicloud_eip" "default" {

count = 5

...

}

resource "alicloud_eip_association" "default" {

count = 5

instance_id = alicloud_instance.default[count.index].id

allocation_id = alicloud_eip.default[count.index].id

}

以上示例展示了如何使用 count 来创建多个资源，并将这些资源相互关联起来。





## **3.****Data Source (基础设施资源和服务的查询)**

对资源的查询是运维人员或系统最常使用的操作之一。例如，查看某个 region 下有哪些可用区、某个可用区下有哪些实例规格、每个 region 下有哪些镜像、当前账号下有多少机器等。通过对资源及其资源属性的查询可以帮助和引导开发者进行下一步的操作。

除了在编写 Terraform 模板时使用的固定静态变量外，有时参数变量可能是不确定的或可能会随时变化。例如，在创建 ECS 实例时，通常需要指定自己的镜像 ID 和实例规格。但是，如果模板可能随时更新，那么在代码中指定 Image ID 和 Instance 类型意味着一旦更新镜像模板就需要重新修改代码。

数据源的结果可以在运行时确定，并且可以被 Terraform 资源使用。这使得模板更加灵活，因为你可以根据实际情况动态选择资源属性，而不必在代码中硬编码这些值。

在 Terraform 中，Data Source 提供了一个查询资源的功能。每个 Data Source 实现对一个资源的动态查询，Data Source 的结果可以被认为是动态变量，只有在运行时才能确定其值。





示例：使用 Data Source 查询资源

data "alicloud_images" "default" {

most_recent = true

owners      = "system"

name_regex  = "^ubuntu_18.*_64"

}





data "alicloud_zones" "default" {

available_resource_creation = "VSwitch"

enable_details              = true

}





data "alicloud_instance_types" "default" {

availability_zone = [data.alicloud_zones.default.zones.0.id](http://data.alicloud_zones.default.zones.0.id/)

cpu_core_count    = 2

memory_size       = 4

}





resource "alicloud_instance" "web" {

image_id        = data.alicloud_images.default.images[0].id

instance_type   = data.alicloud_instance_types.default.instance_types[0].id

instance_name   = "my-first-vm"

system_disk_category = "cloud_ssd"

...

}

在上述代码中：

alicloud_images 用于查询阿里云上的 Ubuntu 18.04 64位镜像。

alicloud_instance_types 用于查询指定可用区下的 ECS 实例规格。

alicloud_zones 用于获取指定可用区下的 VSwitch 创建信息。





## **4.****State (保存资源关系及其属性文件的数据库)**

Terraform 创建和管理的所有资源都会保存在一个名为 terraform.tfstate 的文件中，在 Terraform 中称之为 state。这个文件不是传统意义上的数据库（如 MySQL、Redis 等），而是一个存储状态信息的文件，默认存放在执行 Terraform 命令的本地目录下。

这个 state 文件非常重要，如果该文件损坏，Terraform 将认为已创建的资源被破坏或需要重建（实际上，云上的资源通常不会受到影响）。在执行 Terraform 命令时，Terraform 会利用此文件与当前目录下的模板进行差异比较（Diff），如果出现不一致，Terraform 将按照模板中的定义重新创建或修改已有资源，直到没有差异为止。因此，可以认为 Terraform 是一个有状态的服务。





## **5.****Provisioner (在机器上执行操作的组件)**

Provisioner 通常用来在本地机器或远程主机上执行相关的操作。例如，local-exec provisioner 用于执行本地命令，chef provisioner 用于在远程机器上安装、配置和执行 Chef 客户端，remote-exec provisioner 用于登录远程主机并在其上执行命令。

Provisioner 通常与 Provider 配合使用。Provider 用于创建和管理资源，而 Provisioner 在创建好的机器上执行各种操作。





示例：使用 Provisioner 登录远程主机并执行命令

resource "huaweicloud_compute_instance" "example" {

name              = "example-instance"

image_id          = "YOUR_IMAGE_ID"

flavor_id         = "YOUR_FLAVOR_ID"

security_group_id = "YOUR_SECURITY_GROUP_ID"

availability_zone = "cn-east-3a"





network {

uuid = "YOUR_NETWORK_ID"

}

}





provisioner "remote-exec" {

inline = [

"sudo apt-get update",

"sudo apt-get install -y apache2",

"sudo systemctl start apache2",

"sudo systemctl enable apache2",

]





connection {

host        = huaweicloud_compute_instance.example.access_ip_v4

user        = "ubuntu"

private_key = file("path/to/your/private/key.pem")

}

}





# 三、**模块**

模块是用于组织和重用代码的强大功能。模块允许您将一组相关的资源定义封装在一起，并作为一个单元来使用。

## **1.****基础概念****：**

封装：模块是一组 Terraform 配置文件的集合，它们可以一起被复用来配置和部署资源。你可以将模块看作是函数或者库，它们定义了可以重复使用的组件。

重用性：通过模块，你可以创建可重用的组件，比如一个虚拟网络、一个数据库实例或者一整套相关的服务。

抽象化：模块允许你隐藏复杂的配置细节，使得基础设施的部署和管理更加简单和直观。





## **2.****结构**

一个 Terraform 模块通常包含以下文件和目录结构：

[main.tf](http://main.tf/)：这是主配置文件，包含了模块的主要配置和资源定义。

[variables.tf](http://variables.tf/)：定义模块可以接收的变量，允许调用者自定义模块的行为。

[outputs.tf](http://outputs.tf/)：定义模块可以输出的值，使得调用者可以获取模块部署的状态或信息。

[providers.tf](http://providers.tf/)：配置模块所需的提供者（Providers）。

[README.md](http://readme.md/)：包含模块的使用说明和文档。





# **四、****Terraform 文件结构**

Terraform 文件通常按照职责和组织方式进行组织，以下是一些常见的 Terraform 配置文件及其用途：

[provider.tf](http://provider.tf/) - 提供商配置 这个文件包含了 Terraform 用来与云服务提供商交互的配置。它定义了提供商的名字、区域、认证方式等信息。

terraform.tfvars - 变量文件 这个文件用于存储 Terraform 配置中使用的变量值。这些变量可以是静态的或动态的，用于配置资源。

[variables.tf](http://variables.tf/) - 变量定义 这个文件定义了 Terraform 配置中使用的变量。这些变量可以是静态的或动态的，用于配置资源。

[resource.tf](http://resource.tf/) - 资源定义 这个文件定义了 Terraform 配置中要创建的资源。每个资源由一个资源类型、一个唯一的名称和一系列配置参数组成。

[data.tf](http://data.tf/) - 数据源定义 这个文件定义了 Terraform 配置中要使用的数据源。数据源用于查询外部资源的信息，而不是直接创建或管理资源。

[output.tf](http://output.tf/) - 输出定义 这个文件定义了 Terraform 配置中要输出的变量。这些输出变量可以用于展示 Terraform 管理的资源的状态信息。





# **五、常用命令**

Terraform 是一个强大的基础设施即代码（IaC）工具，可以帮助您定义、创建和管理云环境中的资源。以下是一些常用的 Terraform 命令及其用途：





terraform init：初始化 Terraform 工作区，确保所有必需的插件都已经下载到本地，并且准备好了工作目录以供后续操作使用。这是开始任何 Terraform 操作之前必须执行的命令。





terraform plan -var-file development.tfvars：计划即将进行的操作，如创建、更新或删除资源。该命令会根据您的配置文件生成一个执行计划，并显示预计会发生的变化。





terraform apply -var-file development.tfvars：应用前面计划的更改。在运行 terraform apply 前，通常需要先运行 terraform plan 以查看计划中的更改。terraform apply 会提示确认是否要继续。





terraform output：显示输出变量的值。输出变量是配置中定义的值，用于从 Terraform 状态文件中检索数据。





terraform show：显示当前 Terraform 状态文件中的详细信息。





terraform destroy：销毁之前创建的所有资源。





terraform state list：列出当前状态文件中存在的所有资源。这可以帮助您跟踪哪些资源正在被 Terraform 管理。