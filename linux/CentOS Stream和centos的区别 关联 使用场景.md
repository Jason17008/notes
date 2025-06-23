![img](https://cdn.nlark.com/yuque/0/2025/jpeg/35538885/1736432063956-505f95f6-035e-49e2-85a6-fe7ab541a3b1.jpeg)

Fedora---> CentOS Stream---->RHEL --->CentOS Linux（停更了）

​                                                        |||

​                                            Alma Linux rocylinux  oracle linux

最不推荐 

Fedora------>CentOS Stream---->CentOS Linux

最推荐的(因地制宜)

CentOS Linux---->rocylinux

CentOS Stream和centos的区别 关联 使用场景  

```
entOS Stream 和 CentOS（传统版本）之间有一些关键区别。随着 CentOS 项目的变化，它们在目标、功能和使用场景上也有所不同。

1. CentOS（传统版本）
基于 RHEL：CentOS 是基于 Red Hat Enterprise Linux (RHEL) 的一个免费版本。它与 RHEL 保持二进制兼容，意味着 CentOS 和 RHEL 在系统和软件包上几乎完全相同。
发布周期：CentOS 基本上跟随 RHEL 的版本发布，在 RHEL 发布新版本后，CentOS 会稍作延迟进行编译和发布。它没有自己的开发周期，而是 RHEL 的副本。
更新策略：CentOS 主要提供 稳定性，通常不加入最新的功能或更新，而是等到 RHEL 确保了它们的稳定性后再发布。
支持：CentOS 不提供官方支持服务，但社区提供了广泛的支持。
使用场景：

生产环境：适用于需要与 RHEL 兼容的生产环境，尤其是那些无法承担 RHEL 订阅费用的企业。
测试环境：可以用作开发和测试环境，尤其是与 RHEL 环境兼容的情况下。
企业级部署：用于生产环境中对稳定性有很高要求的场景，常见于 Web 服务器、数据库服务器等企业级应用。
CentOS 8 结束支持： CentOS 8 的生命周期原本计划到 2029 年，但在 2020 年 12 月，Red Hat 宣布 CentOS 8 将在 2021 年底停止支持，转而鼓励用户使用 CentOS Stream 或 RHEL。

2. CentOS Stream
滚动更新：CentOS Stream 是一个滚动发布（rolling release）版本，它位于 RHEL 和 Fedora 之间。CentOS Stream 更像是 RHEL 下一个版本的预览版。它先于 RHEL 发布，意味着 CentOS Stream 的软件包和特性通常比 RHEL 早一些，但它们并不保证在最终的 RHEL 版本中完全相同。
与 RHEL 的关系：CentOS Stream 是 RHEL 的“开发版本”，即 CentOS Stream 会先获得新特性、修复和更新，然后经过一定的验证，最终成为 RHEL 的正式版本。
更新策略：CentOS Stream 会持续接收更新，类似于 Fedora，但并不像 Fedora 那样频繁和不稳定。它会在 RHEL 新版本发布前进行大量的测试。
支持：与传统的 CentOS 类似，CentOS Stream 没有商业支持，但也有社区支持。
使用场景：

开发和测试：CentOS Stream 是开发人员和测试人员的理想选择，尤其是那些想要提前体验 RHEL 下一个版本特性的人。适合做 应用开发、测试和预发布。
RHEL 兼容性测试：CentOS Stream 可作为开发和测试 RHEL 版本的新特性与功能的工具。
生产环境的预演：适合那些希望提前在类似 RHEL 的环境中使用新特性的企业。
```

![img](https://cdn.nlark.com/yuque/0/2024/png/35538885/1735059012780-d7c1e2ca-a215-4ad2-b921-02fadf572a48.png)

# CentOS Stream和centos的区别 关联 使用场景  

```
Fedora 是一个由红帽公司赞助和支持的开源Linux操作系统发行版。它是作为Red Hat Enterprise Linux (RHEL) 的测试平台而存在的

共同点:

都是由 Red Hat 提供的支持基础，属于同一系列的产品。
基于相同的核心技术栈。


不同点:

位置在生态系统中：
CentOS Linux: 这是 Red Hat Enterprise Linux (RHEL) 的免费再构建版本，位于 RHEL 下游。这意味着它包含了来自 RHEL 的稳定且经过验证的组件，并保持与其同步的主要版本更新周期。


CentOS Stream: 则处于 Fedora 和 RHEL 之间的一个中间层，作为滚动式预览渠道存在。其目的是让社区能够提前试用未来的 RHEL 功能和技术改进，从而帮助发现潜在的问题并在正式发布前解决这些问题
```

# 为啥 有  Alma Linux rocy这些 

```
为什么会有这些新的发行版？
稳定性：企业和组织需要一个可靠的、更新周期明确的操作系统来运行关键业务应用。
兼容性：很多软件和工具都是基于 RHEL 构建的，所以一个新的发行版如果能与 RHEL 兼容，就会更容易被接受。
社区和支持：有些用户更喜欢由活跃社区支持的发行版，而其他人则可能倾向于有商业实体支持的选项。
成本效益：对于一些公司来说，使用一个免费但是稳定可靠的操作系统比购买昂贵的 RHEL 许可证更具吸引力。
```

# 推荐一个操作系统推荐那个 为啥 （个人意见 ）

```
ubuntu 
sudo这个东西 提权 能强制规范 
社区活跃  
```