# 一、RabbitMQ消息队列

## 1、消息队列的介绍

- **消息队列也可以称为消息中间件**


- 消息队列（Message Queue）是一种应用间的通信方式，消息发送后可以立即返回，有消息系统来确保信息的可靠传递，消息发布者只管把消息发布到 MQ 中而不管谁来取，消息使用者只管从 MQ 中取消息而不管谁发布的，这样发布者和使用者都不用知道对方的存在。


- 消息队列从字面上意思是 **Message+Queue**。Message 是信息载体，特征是携带的消息通常具有“可消费”性质；Queue 是一个单向通道，**特征是FIFO先进先出**。


- 消息队列作为一个独立的中间件产品存在，独立部署。它提供了一套标准化的接口和协议，让不同平台、不同语言、不同架构的应用程序之间能够实现数据交互。


- 类似这次我们的国庆出行，许多的景区都会出现人满为患，到处都是人从众的现象，这个时候，景区是怎么解决问题的呢？通常就是排队限流了，在检票处设一个等待区域，如果景区里面的人太多，那么就在售票处设立一个等待区，让游客进行排队， 等景区出来一些游客后，再放一批游客进去。


- **当下主流的消息中间件有RabbitMQ、Kafka、ActiveMQ（apache的）、RocketMQ（阿里云的）等。**

## 2、消息队列的作用

**MQ的主要作用**

- 解耦：订单系统下单后，消息写入消息队列，库存系统订阅下单系统，获取下单信息，进行库存操作；解耦降低了各个系统之间的耦合度，使得系统之间只需要关心自己感兴趣的数据，而不需要知道数据来源或去向


- 异步处理：注册信息保存后，同时异步发短信和邮件；例：系统由多个模块组成时，用户一个请求，往往需要调用多个模块才能返回响应。这样会导致用户响应变慢。


- 流量削峰：同一时间点流量暴涨，将用户请求写入消息队列，系统去到消息队列读取消息后慢慢处理


- 缓冲：消息队列可以在两个系统或组件不可用时，临时缓冲消息，等另一个系统恢复后再同步处理。


- 顺序保证：在大多数场景下，处理数据的顺序也很重要，大部分消息中间件支持一定的顺序性


- 冗余（存储）：在某些情况下处理数据的过程中会失败，消息中间件允许把数据持久化直到他们完全被处理。数据可以存储多份

## 3、消息队列的应用场景

### 3.1、异步处理

- 电商网站中，新的用户注册时，需要将用户的信息保存到数据库中，同时还需要额外发送注册的邮件通知、以及短信注册码给用户。但因为发送邮件、发送注册短信需要连接外部的服务器，需要额外等待一段时间，**此时，就可以使用消息队列来进行异步处理，从而实现快速响应。**

![null](assets\1685544269514.jpg)

![null](assets\1685544627368.jpg)

### 3.2、系统解耦

- 当我们开始开发一个系统的时候，逻辑总是比较清晰跟简单，随着需求的迭代，系统会变得越来越复杂，举个简单的例子，原先我们进行一次交易的时候，可能交易系统可能只是践行简单的库存扣减，然后写入订单。随着功能的迭代，**我们需要通知广告系统、第三方的卖家的话、需要通知商家系统等等**，像阿里巴巴，每发生一次简单的交易行为之后，可能需要通知数十个不同的业务方进行处理。


- 这些增加的逻辑，假如我们都做在交易系统的话，就会发现交易系统会变得越来越臃肿不堪，而且会难以保证数据的一致性。假如成单之后，通知广告系统失败了（例如网络波动），那么，这次交易行为是否还要进行下去呢，通知广告系统这种可能失败了就算了，要是通知商家系统失败了呢？数据不一致可能会给公司带来投诉与资损，后期开发要花大量的时间进行数据修复。


- 消息队列，是一种更简单又更可靠的方法。**当我们成功完成一次交易行为之后，我们生产一条消息，所有的业务方都来消费这条消息，由业务方自己来保证成功消费。这样子，交易系统就不用关心交易行为的后续动作，大大减少了交易系统的复杂性。**

![null](assets\1685544764177.jpg)

**加入MQ消息队列后**

![null](assets\1685544372610.jpg)

![null](assets\1685546815590.jpg)

### 3.3、流量削峰

- 举个例子，如果订单系统最多能处理一万次订单，这个处理能力应付正常时段的下单时绰绰有余，正常时段我们下单一秒后就能返回结果。但是在高峰期，如果有两万次下单操作系统是处理不了的，只能限制订单超过一万后不允许用户下单。这种体验很差，因为一万后的用户无法下单。


- 我们在搞秒杀活动时，往往会影响大量的用户同时请求下单，这样如果超过了订单系统的可承受访问，就会把系统压垮，导致用户无法下单。


- 我们可以使用消息队列做缓冲，把订单的必要消息放到消息队列中，把一秒内下的订单分散成一段时间慢慢处理，这时有些用户可能在下单十几秒后才能收到下单成功的操作，但是比不能下单的体验要好。


- 这种效果就是流量削峰

![null](assets\1685545283815.jpg)

![null](assets\1685545621780.jpg)

![null](assets\1685546733477.jpg)

### 3.4、日志处理（大数据领域常见）

大型电商网站（淘宝、京东、国美、苏宁...）、App（抖音、美团、滴滴等）等需要分析用户行为，要根据用户的访问行为来发现用户的喜好以及活跃情况，需要在页面上收集大量的用户访问信息。

![null](assets\1685545694989.jpg)

## 5、消息队列的两种模式

**消息队列包括两种模式，点对点模式（point to point， queue）和发布/订阅模式（publish/subscribe，topic）**

### 5.1、P2P模式

![null](assets\1685547031938.jpg)

**P2P模式包含三个角色：消息队列（Queue）、发送者(Sender)、接收者(Receiver)**

每个消息都被发送到一个特定的队列，接收者从队列中获取消息。队列保留着消息，直到它们被**消费或超时**

**相当于一对一的，发送者将消息发送到消息对列中，接受者只能有一个人去接收，而且接收到了消息之后消息就会消失了**

**P2P的特点：**（点对点：Queue，不可重复消费）

- 每个消息只有一个消费者（Consumer），即一旦被消费，消息就不再在消息队列中


- **发送者和接收者之间在时间上没有依赖性，也就是说当发送者发送了消息之后，不管接收者有没有正在运行它不会影响到消息被发送到队列**


- 接收者在成功接收消息之后需要向队列应答成功


- **如果希望发送的每个消息都会被成功处理的话，那么需要P2P模式**

### 5.2、Pub/Sub--发布/订阅模式

![null](assets\1685547458878.png)

**（发布/订阅：Topic，可以重复消费）**

**Pub/Sub模式包含三个角色：主题（Topic）、发布者（Publisher）、订阅者（Subscriber） 。多个发布者将消息发送到Topic，系统将这些消息传递给多个订阅者。**

**Pub/Sub的特点：**

- 消息生产者（发布）将消息发布到topic中，同时有多个消息消费者（订阅）消费该消息。和点对点方式不同，**发布到topic的消息会被所有订阅者消费**。


- **跟p2p模式最大的区别：每个消息可以有多个消费者，可以有很多个订阅者；一个是一对一，一个是多对多**


- 发布者和订阅者之间有时间上的依赖性。**针对某个主题（Topic）的订阅者，它必须创建一个订阅者之后，才能消费发布者的消息**


- 为了消费消息，订阅者必须保持运行的状态


- **如果希望发送的消息可以不被做任何处理、或者只被一个消费者处理、或者可以被多个消费者处理的话，那么可以采用Pub/Sub模型**

**支持订阅组的发布订阅模式：**

- 发布订阅模式下，当发布者消息量很大时，显然单个订阅者的处理能力是不足的。实际上现实场景中是多个订阅者节点组成一个订阅组负载均衡消费topic消息即分组订阅，这样订阅者很容易实现消费能力线性扩展。可以看成是一个topic下有多个Queue，每个Queue是点对点的方式，Queue之间是发布订阅方式。

![null](assets\1685547666937.jpg)

## 6、常用的消息中间件介绍与对比

![null](assets\1685545934682.jpg)

### 6.1、Kafka

- **kafka最适用的场景于大量日志，最少的日志量都是T，最主要的特点就是高吞吐量，就是一下子能接收非常大的流量**


- Kafka是LinkedIn开源的分布式发布——订阅消息系统，目前归属于Apache顶级项目。Kafka主要特点是追求高吞吐量，一开始的目的就是用于日志收集和传输。0.8版本开始支持复制，**不支持事务，对消息的重复、丢失、错误没有严格要求，适合产生大量日志数据的互联网服务的数据收集业务。**

### 6.2、RabbitMQ

- **最主要的特点就是：安全、可靠；如果系统对安全要求比较严格，就使用rabbitmq比较适合**


- RabbitMQ是使用Erlang语言开发的开源消息队列系统，**基于AMQP协议来实现。AMQP的主要特征是面向消息、队列、路由（包括点对点和发布/订阅）、可靠性、安全。AMQP协议更多用在企业系统内对数据一致性、稳定性和可靠性要求很高的场景，对性能和吞吐量的要求还在其次。**


- Erlang是一种通用的面向并发的编程语言

### 6.3、RocketMQ

- RocketMQ是阿里开源的消息中间件，**它是纯Java开发，具有高吞吐量、高可用性、适合大规模分布式系统应用的特点。**它对消息的可靠传输及事务性做了优化，目前在阿里集团被广泛应用于交易、充值、消息推送、日志流式处理、binglog分发等场景。


- RabbitMQ比Kafka可靠，Kafka更适合IO高吞吐的处理，一般应用在大数据日志处理或对实时性（少量延迟），可靠性（少量丢数据）要求稍低的场景使用，比如ELK日志收集。

**面试题：cache和buffer有什么区别？**

- cache：读缓存，用户第一次读数据会比较慢，如果将数据存储缓存中，用户第二次读速度就更快乐


- buffer：写缓存，将数据存储到硬盘中使用的，先将数据存到缓冲区中，再慢慢的写进去

**面试题：用一句话概括rabbitmq的作用**

- rabbitmq是一种跨进程、异步通信机制的消息中间件，用于上下游来传递消息。由消息系统来确保消息的可靠传递。**最重要的就是流量削峰**和松耦合，把海量并发请求变成数据流请求，让程序之间的耦合度变低，互不依赖；


- 还有一点就是能做数据冗余，做rabbitmq集群，一份数据丢了，另外一台服务器上还有数据，保证数据的安全

# 二、RabbitMQ集群讲解

## 1、RabbiMQ简介

官网地址：<https://www.rabbitmq.com/>

- RabbiMQ于2007 年发布，是一个在 AMQP**（高级消息队列协议）**基础上完成的，可复用的企业消息系统，是当前最主流的消息中间件之一。


- RabbitMQ是一个由erlang开发的AMQP（Advanced Message Queue 高级消息队列协议 ）的开源实现，由于erlang 语言的高并发特性，性能较好，本质是个队列，FIFO 先入先出，里面存放的内容是message


- RabbitMQ 是一个消息中间件，它接收消息并且转发，就类似于一个快递站，卖家把快递通过快递站，送到我们的手上，MQ也是这样，接收并存储消息，再转发。


- RabbiMQ是Erlang开发的，集群非常方便，因为Erlang天生就是分布式语言，但其本身**并不支持负载均衡，支持高并发，支持可扩展。支持AJAX，持久化，用于在分布式系统中存储转发消息，在易用性、扩展性、高可用性等方面表现不俗。**


- **Ajax** 即“Asynchronous Javascript And XML”(异步 JavaScript 和 XML)，是指一种创建交互式网页应用的网页开发技术。*Ajax* = 异步 JavaScript 和 XML


- 我们通过 AJAX 可以做以下事情：


- - 从服务器获取数据并更新网页内容，而不需要重新加载整个网页。


- - 在页面加载完毕后，在后台与服务器交换数据。


- - 在用户事件(如点击按钮、选择下拉框等)后，与服务器交换数据。

## 2、rabbitmq的主要作用

- 应用程序解耦。生产者(Producer)和消费者(Consumer)通过RabbitMQ交换信息，彼此之间没有直接的依赖关系，增加了系统的可扩展性和弹性。


- 流量削峰。RabbitMQ提供消息队列，可以缓存消息，平滑突发的流量高峰。


- 消息异步。生产者发送的消息被缓存到RabbitMQ中，生产者不需要等待消息被消费就可以继续执行，提高生产者的效率。


- 队列松耦合。消费者不需要直接连接生产者，而是通过RabbitMQ队列接受信息。


- 消息传输安全可靠。RabbitMQ支持AMQP协议，提供消息安全可靠传输。


- 负载均衡。RabbitMQ可以在多个消费者之间分配消息，实现负载均衡。


- 持久化。RabbitMQ支持将消息持久化到磁盘，即使服务器DOWN消息也不会丢失。


- 监控。RabbitMQ提供管理控制台和API监控消息的投递、消费情况以及队列长度等。


- 模式丰富。RabbitMQ支持多种消息模式，如点对点、发布订阅、工作队列等。

## 3、RabbitMQ 特点

- 可靠性，RabbitMQ 使用一些机制来保证可靠性，如持久化、传输确认、发布确认。


- 灵活的路由：在消息进入队列之前，通过 Exchange 来路由消息的。对于典型的路由功能，RabbitMQ 已经提供了一些内置的 Exchange 来实现。针对更复杂的路由，可以将多个 Exchange 绑定在一起，也通过插件机制实现自己的 Exchange


- 支持消息集群：rabbitmq可以做集群模式


- 支持高可用，因为支持集群，那么单点故障的这问题就解决了，所以就具备高可用的特点；而且队列可以在集群中的机器上进行镜像，使得在部分节点出问题的情况下队列仍然可用


- 支持多种协议，支持多种消息队列协议，比如 STOMP、MQTT 等等。


- 支持多语言，RabbitMQ 几乎支持所有常用语言，比如 Java、.NET、Ruby 等等。


- 拥有管理界面：RabbitMQ 提供了一个易用的用户界面，使得用户可以监控和管理消息 Broker 的许多方面。


- 支持跟踪机制：如果消息异常，RabbitMQ 提供了消息跟踪机制，使用者可以找出发生了什么。

## 4、rabbitmq的优点

```
轻量级： RabbitMQ 是基于Erlang语言开发的，性能高效、资源消耗低。
可靠： RabbitMQ 追求可靠性，同时支持事务和持久化，能有效避免消息丢失。
松耦合： RabbitMQ通过队列实现了生产者和消费者之间的松耦合，支持系统解耦。
多种模式： RabbitMQ支持多种消息模式，如点对点、发布订阅等，满足不同需求。
多语言： RabbitMQ 支持多种常见编程语言，如 Java、Python、.NET 等。
功能丰富： RabbitMQ 提供了消息转发、路由、削峰等多种功能。
性能高效： RabbitMQ使用基于内存的队列，并支持集群化提升吞吐量。
可扩展性好： 通过集群技术支持水平扩展，并支持大量的客户端连接。
高可用： RabbitMQ支持集群部署，可以提供高可用服务。
安全性好： 提供了基于用户、角色和权限的安全访问机制。
管理方便： 提供WEB管理控制台方便管理。

总的来说，RabbitMQ的优点主要体现在:
    性能高效、资源消耗低
    可靠性好，避免消息丢失
    松耦合设计，支持系统解耦
    丰富的功能满足多种需求
    支持多语言与多种协议
    易于管理和监控
    尤其是相对于其他消息中间件来说, RabbitMQ 代码开源透明、社区活跃、部署使用更加简单。
```

## 5、RabbitMQ模式介绍

**注意，RabbitMQ模式大概分为三种：单机模式（多用于测试环境）、普通集群模式（无高可用）、镜像集群模式（高可用集群）**

- 单机模式：RabbitMQ 安装在单个节点上，所有队列、交换器等都存储在该节点。这是最简单的部署模式，但故障后整个消息系统将不可用；我们基本上不用这个模式，一般都是开发用，自己部署测试代码


- 普通模式(默认的集群模式)：


- - 这个模式的意思就是在多台机器上启动多个 `RabbitMQ` 实例。类似的 `master-slave` 模式一样。**但是创建的 **`queue`**，只会放在一个 **`master rabbtimq`** 实例上，其他实例都同步那个接收消息的 **`RabbitMQ`** 元数据**。


- - **在消费消息的时候，如果你连接到的 **`RabbitMQ`** 实例不是存放 **`queue`** 数据的实例，这个时候 **`RabbitMQ`** 就会从存放 **`queue`** 数据的实例上拉去数据，然后返回给客户端。**


- - 总的来说，这种方式有点麻烦，没有做到真正的分布式，每次消费者连接一个实例后拉取数据，如果连接到不是存放 `queue` 数据的实例，这个时候会造成额外的性能开销。如果一直从存放 `queue` 的实例拉取，会导致单实例性能瓶颈。


- - 如果放 `queue` 的实例宕机了，会导致其他实例无法拉取数据，这个集群都无法消费消息了，没有做到真正的高可用。


- - 所以这个事儿就比较尴尬了，这就没有什么所谓的**高可用性**可言了，这方案主要是**提高吞吐量**的，**就是说让集群中多个节点来服务某个 **`queue`** 的读写操作**。


- 镜像模式（把需要的队列做成镜像队列，存在于多个节点，属于RabbiMQ的HA方案，在对业务可靠性要求较高的场合中比较适合）。要实现镜像模式，需要先搭建出普通集群模式，在这个模式的基础上再配置镜像模式以实现高可用。


- - 镜像集群模式才是真正的 `RabbitMQ` 的高可用模式，跟普通集群模式不一样的是：**创建的 **`queue`** 无论元数据还是 **`queue`** 里的消息都会存在于多个实例上，每次写消息到 **`queue`** 的时候，都会自动把消息到多个实例的 **`queue`** 里进行消息同步。**


- - 这样的话任何一个机器宕机了别的实例都可以用提供服务，这样就做到了真正的高可用了。


- 但是也存在着不足之处：


- - **性能开销过高，消息需要同步所有机器，会导致网络带宽压力和消耗很重**


- - 扩展性低：无法解决某个 `queue` 数据量特别大的情况，导致 `queue` 无法线性拓展。就算加了机器，那个机器也会包含 `queue` 的所有数据，`queue`** 的数据没有做到分布式存储**。


- **对于 **`RabbitMQ`** 的高可用一般的做法都是开启镜像集群模式，这样起码来说做到了高可用，一个节点宕机了，其他节点可以继续提供服务。**

**集群模式和镜像模式的区别**

![null](assets\1599188888(1).jpg)

- 普通模式：当请求被分发到1号机器中，1号机器中会存储数据，其他两台机器只会存储元数据（数据的属性信息），如果有消费者来消费，可能会去2号机器上消费，这时2号机器才会去1号机器上拿数据；优点和缺点就是：存储数据较快，但是消费速度较慢


- 镜像模式：只要一号机器有数据了，其他节点上也都会有相同的数据

## 6、RabbitMQ工作原理

![null](https://cdn.nlark.com/yuque/0/2024/png/35538885/1722481348609-acaf09a4-d019-4836-904b-74191fddebb5.png)

![null](assets\1685584918429.jpg)

```
生产者（Producer）通过信道（Channel）把消息发送给交换机（Exchange)，当创建交换机时需要指定类型（四种类型：直接Direct，扇出Fanout ，主题Topic ，消息头Headers ）；

交换机（Exchange）接收消息并且负责对消息进行路由，交换机根据消息的属性来把消息分发到不同的队列（Queue）上；

消息（Message）会一直留在队列里直到被消费者（Consumer）消费。
```

## 7、RabbitMQ核心概念

```
生产者（Producer）：发送消息的应用。

消费者（Consumer）：接收消息的应用。

队列（Queue）：存储消息的缓存。

消息（Message）：由生产者通过RabbitMQ发送给消费者的信息。

连接（Connection）：连接RabbitMQ和应用服务器的TCP连接。

信道（Channel）：连接里的一个虚拟通道，通过消息队列发送或者接收消息时，都是通过信道进行的。

交换机（Exchange）：交换机负责从生产者那里接收消息，并根据交换类型分发到对应的消息队列里。

绑定（Binding）：绑定是队列和交换机的一个关联连接。

路由键（Routing Key）：路由键是供交换机查看并根据键来决定如何分发消息到队列的一个键，路由键可以说是消息的目的地址。

代理（Broker）：接收和分发消息的应用，RabbitMQ Server就是Message Broker。

虚拟主机（Virtual host）：出于多租户和安全因素设计的，把AMQP的基本组件划分到一个虚拟的分组中，类似于网络中的namespace概念。当多个不同的用户使用同一个RabbitMQ server提供的服务时，可以划分出多个vhost，每个用户在自己的vhost创建exchange/queue 等。
```

## 8、了解集群中的基本概念

**集群模式中使用节点的类型**

- RabbitMQ集群中有两种节点类型，一种disk(磁盘)节点，一种ram(内存)节点。


- 内存节点将队列、交换器、绑定关系、权限和vhost的**元数据**定义都存储在内存中，磁盘节点将这些信息存储在磁盘上。


- RabbitMQ在创建队列、交换器、和绑定关系的时候，需要等集群所有的节点都成功提交元数据变更后才返回。**内存节点可以为集群提供出色的性能，因为写入内存比写入磁盘快的不是一点半点，磁盘节点为集群提供了高可靠性。**


- **RabbitMQ要求集群中至少有一个磁盘节点，其他节点都可以是内存节点。**


- 假设**磁盘节点**故障了，此时只能发送和消费消息，不能进行队列创建、交换器创建、绑定关系、用户，以及更改权限、添加和删除集群节点的操作。所以在建立集群的时候尽量保证多个磁盘节点的存在，其实在队列、交换器、绑定关系变化较小的RabbitMQ集群中，可以考虑将所有节点设置为磁盘节点。


- **内存类型节点：读写速度都快，缺点就是服务器重启数据就没了**


- **磁盘类型节点：将数据存储到内存和磁盘上，一个保存到内存上，一个保存到硬盘上**


- RabbitMQ的集群节点包括内存节点、磁盘节点。顾名思义内存节点就是将所有数据放在内存，磁盘节点将数据放在磁盘。


- 一个rabbitmq集群中可以共享 user，vhost，queue，exchange等，所有的数据和状态都是必须在所有节点上复制。

**面试注意：rabbitmq集群中有两种节点类型**

- 内存节点：只保存状态到内存（持久的queue的持久内容将被保存到disk）


- 磁盘节点：保存状态到内存和磁盘。推荐


- 内存节点虽然不写入磁盘，但是它执行比磁盘节点要好。集群中，只需要一个磁盘节点来保存状态，就足够了


- 如果集群中只有内存节点，那么不能停止它们，否则所有的状态，消息等都会丢失。

# 三、普通集群部署

## 3.1、准备集群环境

- **注意，三台服务器，RabbitMQ集群节点必须在同一网段，如果是跨域，效果会变差。关闭防火墙和selinux**


- **一定要做：修改主机名称，添加解析**


- 三台机器都操作：


- 配置hosts文件更改三台MQ节点的计算机名分别为rabbitmq-1、rabbitmq-2 和rabbitmq-3，然后修改hosts配置件

```
[root@rabbitmq-1 ~]# hostnamectl set-hostname rabbitmq-1
[root@rabbitmq-1 ~]# vim /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.50.138 rabbitmq-1
192.168.50.139 rabbitmq-2
192.168.50.140 rabbitmq-3
```

- 三个节点配置安装rabbitmq软件

```
#安装依赖
[root@rabbitmq-1 ~]# yum install -y *epel* gcc-c++ unixODBC unixODBC-devel openssl-devel ncurses-devel

#安装erlang
#查看rabbitmq对应的erlang版本：https://www.rabbitmq.com/which-erlang.html
#Erlang 语言是一种专为分布式系统而设计的函数式编程语言。

[root@rabbitmq-1 ~]# curl -s https://packagecloud.io/install/repositories/rabbitmq/erlang/script.rpm.sh | sudo bash

[root@rabbitmq-1 ~]# yum install erlang-21.3.8.21-1.el7.x86_64 -y

#测试是否有erl环境：
[root@rabbitmq-1 ~]# erl
Erlang/OTP 21 [erts-10.3.5.16] [source] [64-bit] [smp:2:2] [ds:2:2:10] [async-threads:1] [hipe]

Eshell V10.3.5.16  (abort with ^G)
1>	#crtl g
User switch command
 -->	q	#退出；h列出功能
[root@rabbitmq-1 ~]#


#安装socat
#安装 socat，主要是为了支持 Erlang 安全套接字(Erlang distribution)；具体来说，socat 提供了 Erlang distribution 需要使用的 Unix 域和TCP/IP 的通信功能
[root@rabbitmq-1 ~]# yum install -y socat

#安装rabbitmq
#https://github.com/rabbitmq/rabbitmq-server/releases/tag/v3.7.10   #选择版本

#下载下来将其上传到服务器中，三台机器相同操作
[root@rabbitmq-1 ~]# yum install -y rabbitmq-server-3.7.10-1.el7.noarch.rpm


# erlang 版本选择
https://packagecloud.io/rabbitmq/erlang
# rabbitmq 和erlang兼容版本
https://www.rabbitmq.com/which-erlang.html
```

```
#3、启动rabbitmq
[root@rabbitmq-1 ~]# systemctl daemon-reload

#启动并加入开机自启
[root@rabbitmq-1 ~]# systemctl enable  --now  rabbitmq-server.service

[root@rabbitmq-1 ~]# netstat -ntlp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:4369            0.0.0.0:*               LISTEN      2528/epmd
tcp        0      0 0.0.0.0:25672           0.0.0.0:*               LISTEN      2398/beam.smp
tcp6       0      0 :::5672                 :::*                    LISTEN      2398/beam.smp

#rabbitmq常见端口：
4369 - RabbitMQ 集群节点间通信的 Erlang 端口
5672 - AMQP 0-9-1 协议的默认端口,应用程序使用该端口与 RabbitMQ 服务器进行通信。
15672 - RabbitMQ 管理控制台的默认 HTTP 端口。
25672 - Erlang 分布式协议的默认端口,RabbitMQ 节点使用该端口进行通信。
61613 - STOMP 协议的默认端口。
61614 - STOMP over websocket 协议的默认端口。
1883 - MQTT 协议的默认端口。
8081 - RabbitMQ nodes/cluster 监控插件的默认 HTTP 端口。
8182 - RabbitMQ 虚拟机监控插件的默认 HTTP 端口。
#其中5672 端口用于 RabbitMQ 与客户端的连接，较为重要。15672 端口用于访问管理控制台，进行管理操作。
#一般情况下，这两个端口需要对外开放。其他端口默认情况下可以关闭。
#需要注意的是，以上端口仅为 RabbitMQ 的默认配置，可以通过修改配置文件进行自定义。
#当需要改变默认端口时，需要同时在 RabbitMQ 服务器和客户端均作出相应配置


#启动方式二:
[root@rabbitmq-1 ~]# /usr/sbin/service rabbitmq-server status  ---查看状态
[root@rabbitmq-1 ~]# /usr/sbin/service rabbitmq-server start   ---启动

#常见报错：
Error description:   noproc
#你的rabbitmq的版本和erlang 的版本不对应。请检查你的版本。


#每台都操作开启rabbitmq的web访问界面： 
[root@rabbitmq-1 ~]# rabbitmq-plugins enable rabbitmq_management
```

![null](assets\1685620634575.jpg)

**创建用户并修改权限**

```
注意：只在一台机器上操作即可！！！！！

#添加用户和密码
# 新增用户 rabbitmqctl add_user {username} {password}
# 修改用户密码 rabbitmqctl change_password {username} {newpassword}
# 验证用户密码 rabbitmqctl authenticate_user {username} {password}
# 删除用户 rabbitmqctl delete_user {username}
# 列出所有用户，结果为用户名和用户TAG rabbitmqctl list_users


#第一步：添加一个admin的用户
[root@rabbitmq-1 ~]# rabbitmqctl add_user admin admin
Adding user "admin" ...


# 设置用户标签(tag) rabbitmqctl set_user_tags {username} {tag...}
# tag有如下几种选项
# none：无任何角色，新建的用户默认值
# management：可以访问WEB管理界面
# policymaker：包含management的所有权限，并且可以管理策略(Policy)和参数(Parameter)
# monitoring：包含management的所有权限，并且可以看到所有连接、信道和节点信息。
# administrator：包含monitoring的所有权限，并且可管理虚拟主机、用户、权限、策略、参数等，这是最高权限。

#第二步：设置角色为管理员
[root@rabbitmq-1 ~]# rabbitmqctl set_user_tags admin administrator
Setting tags for user "admin" to [administrator] ...

#第三步：查看用户
[root@rabbitmq-1 ~]# rabbitmqctl list_users
Listing users ...
user    tags
admin   [administrator]
guest   [administrator]

#创建主机主机项
rabbitmqctl add_vhost {vhost}
# ｛vhost｝ 表示待创建的虚拟主机项的名称

rabbitmqctl delete_vhost {vhost}
# 表示删除一个vhost。删除一个vhost将会删除该vhost的所有exchange、queue、binding、用户权限、参数和策略

rabbitmqctl list_vhosts {vhostinfoitem ...}
# 表示列出所有的vhost。其中 {vhostinfoitem} 表示要展示的vhost的字段信息，展示的结果将按照 {vhostinfoitem} 指定的字段顺序展示。这些字段包括： name（名称） 和 tracing （是否为此vhost启动跟踪）。
# 如果没有指定具体的字段项，那么将展示vhost的名称。

#表示设置用户权限
rabbitmqctl set_permissions [-p vhost] {user} {conf} {write} {read}
# 。 {vhost} 表示待授权用户访问的vhost名称，默认为 "/"； {user} 表示待授权反问特定vhost的用户名称； {conf}表示待授权用户的配置权限，是一个匹配资源名称的正则表达式； {write} 表示待授权用户的写权限，是一个匹配资源名称的正则表达式； {read}表示待授权用户的读权限，是一个资源名称的正则表达式。

rabbitmqctl set_permissions -p /  admin "^mip-.*" ".*" ".*"
# 例如上面例子，表示授权给用户 "admin" 具有所有资源名称以 "mip-" 开头的配置权限；所有资源的写权限和读权限。


# 举两个列子
# 为rabbitmq用户设置可以对名称为test_vhost的vhost下面的资源可配置，可写，可读
rabbitmqctl set_permissions -p test_vhost rabbitmq ".*" ".*" ".*"

# 为rabbitmq用户设置可以对名称为test_vhost的vhost下面的以order开头的资源可配置，所有资源可写，所有资源可读
rabbitmqctl set_permissions -p test_vhost rabbitmq "^order.*" ".*" ".*"   

# conf：此处的值是一个正则表达式，用于匹配用户在哪些资源上拥有可配置权限。
# write：此处的值是一个正则表达式，用于匹配用户在哪些资源上拥有可写入权限。
# read：此处的值是一个正则表达式，用于匹配用户在哪些资源上拥有可读取权限。
rabbitmqctl set_permissions -p "/" admin ".*" ".*" ".*"


rabbitmqctl list_permissions [-p vhost]
# 表示列出具有权限访问指定vhost的所有用户、对vhost中的资源具有的操作权限。默认vhost为 "/"。
# 注意，空字符串表示没有任何权限。

rabbitmqctl list_user_permissions {username}
# 表示列出指定用户的权限vhost，和在该vhost上的资源可操作权限。

#第四步：
#我们要做的具体操作，对admin这个用户设置所有资源可读可写：
[root@rabbitmq-1 ~]# rabbitmqctl set_permissions -p "/" admin ".*" ".*" ".*"
Setting permissions for user "admin" in vhost "/" ...

#当没有给admin设置这三个权限前是没有权限查询队列，在ui界面也看不见
```

**3台机器都操作：开启用户远程登录**

```
[root@rabbitmq-1 ~]# cd /etc/rabbitmq/   
[root@rabbitmq-1 rabbitmq]# cp /usr/share/doc/rabbitmq-server-3.7.5/rabbitmq.config.example /etc/rabbitmq/rabbitmq.config 
[root@rabbitmq-1 ~]# cd /etc/rabbitmq/
[root@rabbitmq-1 rabbitmq]# ls
enabled_plugins  rabbitmq.config
[root@rabbitmq-1 rabbitmq]# cp rabbitmq.config{,.bak}
[root@rabbitmq-1 rabbitmq]# vim rabbitmq.config
#修改如下：
61    %% {loopback_users, []},
#改成： {loopback_users, []}
```

![null](https://cdn.nlark.com/yuque/0/2024/png/35538885/1722481348692-a15b1e9a-2af2-41a6-8a7e-7e83bf3f95ea.png)

![null](assets\1685628889207.jpg)

**逗号记得删掉！！！**

```
#三台机器都操作重启服务服务:
[root@rabbitmq-1 ~]# systemctl restart rabbitmq-server
```

**如果配置文件不对，那么下面做重启操作，就会无法重启，导致报错**

![null](assets\1685629172985.jpg)

**查看端口**

![null](assets\1685629343153.jpg)

```
#rabbitmq常见端口：
4369 - RabbitMQ 集群节点间通信的 Erlang 端口
5672 - AMQP 0-9-1 协议的默认端口，应用程序使用该端口与 RabbitMQ 服务器进行通信。
15672 - RabbitMQ 管理控制台的默认 HTTP 端口。
25672 - Erlang 分布式协议的默认端口，RabbitMQ 节点使用该端口进行通信。
61613 - STOMP 协议的默认端口。
61614 - STOMP over websocket 协议的默认端口。
1883 - MQTT 协议的默认端口。
8081 - RabbitMQ nodes/cluster 监控插件的默认 HTTP 端口。
8182 - RabbitMQ 虚拟机监控插件的默认 HTTP 端口。
#其中5672 端口用于 RabbitMQ 与客户端的连接，较为重要。15672 端口用于访问管理控制台，进行管理操作。
#一般情况下，这两个端口需要对外开放。其他端口默认情况下可以关闭。
#需要注意的是，以上端口仅为 RabbitMQ 的默认配置，可以通过修改配置文件进行自定义。
#当需要改变默认端口时，需要同时在 RabbitMQ 服务器和客户端均作出相应配置
```

**注意！！！如果是云服务器，切记添加安全组端口放行。**

**访问：192.168.17.133:15672**

**账号密码都是guest/admin**

![null](assets\1685629608837.jpg)

![null](assets\1685629824709.jpg)

## 3.2、集群部署操作

- **三台机器都操作:**


- 1、首先创建好数据存放目录和日志存放目录:

```
#以下操作所有机器都要操作！！！
[root@rabbitmq-1 ~]# mkdir -p /data/rabbitmq/{data,logs}
[root@rabbitmq-1 ~]# chmod 777 -R /data/rabbitmq
[root@rabbitmq-1 rabbitmq]# id rabbitmq
uid=997(rabbitmq) gid=995(rabbitmq) 组=995(rabbitmq)
[root@rabbitmq-1 ~]# chown rabbitmq.rabbitmq /data/ -R

#创建配置文件:
[root@rabbitmq-1 ~]# vim /etc/rabbitmq/rabbitmq-env.conf
[root@rabbitmq-1 ~]# cat /etc/rabbitmq/rabbitmq-env.conf
RABBITMQ_MNESIA_BASE=/data/rabbitmq/data
RABBITMQ_LOG_BASE=/data/rabbitmq/logs

#重启服务
[root@rabbitmq-1 ~]# systemctl restart rabbitmq-server
```

**2、拷贝erlang.cookie**

Rabbitmq的集群是依附于erlang的集群来工作的，所以必须先构建起erlang的集群。Erlang的集群中各节点是经由各个cookie来实现的，这个cookie存放在/var/lib/rabbitmq/.erlang.cookie中，文件是400的权限。所以必须保证各节点cookie一致，不然节点之间就无法通信

```
#如果执行# rabbitmqctl stop_app 这条命令报错，需要执行：
#chmod 400 .erlang.cookie
#chown rabbitmq.rabbitmq .erlang.cookie
```

- **官方在介绍集群的文档中提到过，erlang.cookie 一般会存在这两个地址：第一个是home/.erlang.cookie；第二个地方就是/var/lib/rabbitmq/.erlang.cookie。**


- **如果我们使用解压缩方式安装部署的rabbitmq，那么这个文件会在home目录下，也就是$home/.erlang.cookie。**


- **如果我们使用rpm等安装包方式进行安装的，那么这个文件会在/var/lib/rabbitmq目录下**

**将rabbitmq-1节点的.erlang.cookie的值复制到其他两个节点中**

```
[root@rabbitmq-1 rabbitmq]# cat /var/lib/rabbitmq/.erlang.cookie
TLRCSBNSYLEYNYUALPRM

#将rabbitmq-1节点的.erlang.cookie的值复制到其他两个节点中
[root@rabbitmq-1 ~]# scp /var/lib/rabbitmq/.erlang.cookie root@192.168.17.135:/var/lib/rabbitmq/

[root@rabbitmq-1 ~]# scp /var/lib/rabbitmq/.erlang.cookie root@192.168.17.136:/var/lib/rabbitmq/
```

**3、将mq-2、mq-3作为内存节点加到mq-1节点集群中**

```
#在rabbitmq-2、rabbitmq-3执行如下命令：
[root@rabbitmq-2 ~]# rabbitmqctl stop_app  #停止节点，切记不是停止服务！！！
#rabbitmqctl stop_app 表示终止RabbitMQ的应用，但是Erlang节点还在运行
#systemctl stop rabbitmq会停止当前主机上的所有关于RabbitMQ的节点

#先重启一下rabbitmq，不然stop_app就会报错！！！因为 Erlang 的 cookie发生了变化，不重启会报：Error: unable to perform an operation on node 'rabbit@rabbitmq-3'，让rabbit重新加载一下erlang的cookie
[root@rabbitmq-2 ~]# systemctl restart rabbitmq-server.service

[root@rabbitmq-2 ~]# rabbitmqctl stop_app
Stopping rabbit application on node rabbit@rabbitmq-2 ...

[root@rabbitmq-3 ~]# systemctl restart rabbitmq-server.service
[root@rabbitmq-3 ~]# rabbitmqctl stop_app
Stopping rabbit application on node rabbit@rabbitmq-3 ...
```

```
#清空节点的数据(包括队列、交换器和绑定)，使节点进入初始化状态，但仍然属于同一个集群
[root@rabbitmq-2 rabbitmq]# rabbitmqctl reset	#如果有数据需要重置，没有则不用
Resetting node rabbit@rabbitmq-2 ...
```

注意查看回显，如果不是以上。就是错误；**如果报错，重启rabbitmq服务**

```
#将两个节点加入集群，指定角色
#添加到内存节点 --ram
[root@rabbitmq-2 ~]# rabbitmqctl join_cluster --ram rabbit@rabbitmq-1  
Clustering node 'rabbit@rabbitmq-2' with 'rabbit@rabbitmq-1' ...

[root@rabbitmq-2 ~]# rabbitmqctl start_app  #启动节点
Starting node 'rabbit@rabbitmq-2' ...
 completed with 3 plugins.
==============================================================================
[root@rabbitmq-3 ~]# rabbitmqctl stop_app
Stopping node 'rabbit@rabbitmq-3' ...
[root@rabbitmq-3 ~]# rabbitmqctl reset
Resetting node 'rabbit@rabbitmq-3' ...
[root@rabbitmq-3 ~]# rabbitmqctl join_cluster --ram rabbit@rabbitmq-1
Clustering node 'rabbit@rabbitmq-3' with 'rabbit@rabbitmq-1' ...
[root@rabbitmq-3 ~]# rabbitmqctl start_app
Starting node 'rabbit@rabbitmq-3' ...
 completed with 3 plugins.

#（1）默认rabbitmq启动后是磁盘节点，在这个cluster命令下，mq-2和mq-3是内存节点，mq-1是磁盘节点。
#（2）如果要使mq-2、mq-3都是磁盘节点，去掉--ram参数即可。
#（3）如果想要更改节点类型，可以使用命令rabbitmqctl change_cluster_node_type {disc|ram} node_name	#disc 就是表示磁盘类型的标签。执行该命令后，该节点会不再存储数据在内存中，而是将队列和交换器持久化到磁盘；节点类型的改变需要满足几个条件：节点当前没有客户连接、节点当前没有未完成的任务；前提是必须停掉rabbitmq应用

#注:
#如果有需要使用磁盘节点加入集群
 [root@rabbitmq-2 ~]# rabbitmqctl join_cluster  rabbit@rabbitmq-1
 [root@rabbitmq-3 ~]# rabbitmqctl join_cluster  rabbit@rabbitmq-1
```

**4、查看集群状态**

```
#在 RabbitMQ 集群【任意节点】上执行 rabbitmqctl cluster_status来查看是否集群配置成功。
#在mq-1磁盘节点上面查看
[root@rabbitmq-3 ~]# rabbitmqctl cluster_status
Cluster status of node rabbit@rabbitmq-3 ...	#当前节点
[{nodes,[{disc,['rabbit@rabbitmq-1']},	#磁盘节点
         {ram,['rabbit@rabbitmq-3','rabbit@rabbitmq-2']}]},		#内存节点
 {running_nodes,['rabbit@rabbitmq-2','rabbit@rabbitmq-1','rabbit@rabbitmq-3']},		#集群节点都分别有谁
 {cluster_name,<<"rabbit@rabbitmq-1">>},	#集群名称
 {partitions,[]},
 {alarms,[{'rabbit@rabbitmq-2',[]},
          {'rabbit@rabbitmq-1',[]},
          {'rabbit@rabbitmq-3',[]}]}]
```

![null](assets\1685633092986.jpg)

**每台机器显示出三台节点，表示已经添加成功！**

**5、登录rabbitmq web管理控制台，创建新的队列**

```
打开浏览器输入http://192.168.17.133:15672	任意一个节点的IP和端口都可以打开

输入默认的Username：guest

输入默认的Password:guest 

登录后出现如图所示的界面。
```

![null](assets\1685633468321.jpg)

**根据界面提示创建一条队列**

![null](assets\1685633842758.jpg)

![null](assets\1685633948674.jpg)

![null](assets\1685634064539.jpg)

**至此，一般集群模式配置成功！！！但是它不是真正的高可用集群，因此，我们还要继续配置镜像模式才能做到真正意义上的高可用集群！**

# 四、RabbitMQ镜像集群配置

![null](assets\1685634621637.jpg)

- 上面已经完成RabbitMQ默认集群模式，**但并不保证队列的高可用性，【队列内容不会复制】。如果队列节点宕机直接导致该队列无法应用，只能等待重启，所以要想在队列节点宕机或故障也能正常应用，就要复制队列内容到集群里的每个节点，必须要创建镜像队列。**


- **镜像集群模式是基于普通的集群模式的！！！**


- **rabbitmq set_policy ：设置策略**

```
#创建镜像集群：在任意一台机器操作

[root@rabbitmq-1 ~]#  rabbitmqctl set_policy  ha-all "^" '{"ha-mode":"all"}'
Setting policy "ha-all" for pattern "^" to "{"ha-mode":"all"}" with priority "0" for vhost "/" ...

# "^"匹配所有的队列，ha-all：策略名称为ha-all， '{"ha-mode":"all"}' ：策略模式为 all 即复制到所有节点，包含新增节点。

#设置策略介绍:
#rabbitmqctl set_policy [-p Vhost] Name Pattern Definition
#-p Vhost： 可选参数，针对指定vhost下的queue进行设置
#Name: policy的名称，可以定义
#Pattern: queue的匹配模式(正则表达式)，也就是说会匹配一组。
#Definition：镜像定义，包括三个部分ha-mode， ha-params， ha-sync-mode
#    ha-mode:指明镜像队列的模式，有效值为 all/exactly/nodes
#        all：表示在集群中所有的节点上进行镜像
#        exactly：表示在指定个数的节点上进行镜像，节点的个数由ha-params指定（表示使用确切镜像模式，根据ha-params的值来定到底几个的，如果ha-params为2那也就是说两个节点(指定数量 2)上创建镜像队列，实现高可用）
#        nodes：表示在指定的节点上进行镜像，节点名称通过ha-params指定
#    ha-params：ha-mode模式需要用到的参数
#    ha-sync-mode：进行队列中消息的同步方式，有效值为automatic（automatic自动同步，当一个新镜像加入时，队列会自动同步。队列同步是一个阻塞操作。）和manual手动<默认模式>.新的队列镜像将不会收到现有的消息，它只会接收新的消息。

#案例:
#例如，对队列名称以hello开头的所有队列进行镜像，并在集群的两个节点上完成镜像，policy的设置命令为： 
# rabbitmqctl set_policy hello-ha “^hello” ‘{“ha-mode”:”exactly”，”ha-params”:2，”ha-sync-mode”:”automatic”}’

#ha-params：镜像队列数量为 2
```

**再次查看队列已经同步到其他两台节点:**

![null](assets\1685634991336.jpg)

- **则此时镜像队列设置成功。**


- **已经部署完成**


- **将所有队列设置为镜像队列，即队列会被复制到各个节点，各个节点状态保持一致。**

**做了集群模式后，发现之前创建的admin用户都不见了，因为我们在将rabbimq-2/3添加到集群 的时候，做了rabbitmqctl reset 重置节点时，清除了所有用户**

![null](assets\1685698553636.jpg)