[TOC]



# 一.配置角色的方式发生改变

## 1.角色的定义方式发生改变

```
	在Elastic Stack 7.9之后的发布中，我们可以直接在Elasticsearch的配置文件中配置Node的角色 （node roles）。

	这是一个新的变化。在 7.9 发布版之前，我们使用 node.master: true 这样的方式来定义一个 master 节点，但是从 7.9 开始之后，我们也可以使用另外一个方法来定义一个 master 节点。我们可以通过 node.roles 来定义一个 master 节点。
	
	但是这两种方法只可以选其一，不能两种方法同时使用。从 7.9 发布后，建议使用  node.roles 来定义 node 的角色。在今天的文章中，我来介绍 node.roles。
	
	
	原文链接：
		https://blog.csdn.net/UbuntuTouch/article/details/110947372

```



## 2.什么是node

```
	每当你启动Elasticsearch实例时，你都在启动节点。连接的节点的集合称为群集。如果你正在运行 Elasticsearch的单个节点，那么你将拥有一个节点的集群。

	默认情况下，群集中的每个节点都可以处理HTTP和Transport流量。 Transport层专门用于节点之间的通信。 HTTP 层由 REST 客户端使用。

	所有节点都知道群集中的所有其他节点，并且可以将客户端请求转发到适当的节点。

	默认情况下，节点为以下所有类型：master-eligible, data, ingest 和（如果可用）machine learning。 所有 data 节点也是 transform 节点。

	友情提示：
		随着集群的增长，特别是如果你有大量机器学习工作或连续转换，请考虑将专用于 master-eligible 节点与专用 data 节点，machine learning 节点和 transform 节点分离。

```





# 二.集群角色

## 1.角色概述

```
你可以通过设置 node.roles 来定义节点的角色。 如果你未配置此设置，则该节点默认具有以下角色：
	master
	data
	data_content
	data_hot
	data_warm
	data_cold
	ingest
	ml
	remote_cluster_client

注意：
	如果你设置 node.roles，那么 node 将被分配为指定的角色。
```



## 2.Master-eligible node

```
	具有 master role（默认）的节点，这使其有资格被选作控制群集的主节点。

	主节点负责集群范围内的轻量级操作，例如创建或删除索引，跟踪哪些节点是集群的一部分以及确定将哪些shard分配给哪些节点。 拥有稳定的主节点对于群集健康非常重要。

	任何一个非 voting-only 节点且具有 master-eligible 属性的节点可以通过 master election process，使其成为主节点。

	重要提示：
		主节点必须有权访问 data/ 目录（就像数据节点一样），因为这是节点重新启动之间保持群集状态的位置。


Dedicated master-eligible node
	一旦一个 master-eligible 节点被选举为 master 节点，它需要履行其职责以保持资源集群的健康。如果当选主节点因为其他繁重的任务使之超负荷运行，那么集群可能不能很好地工作。 特别是，建立索引数据和搜索数据可能会占用大量资源，因此，在大型或高吞吐量群集中，最好避免使用 master-eligible 节点来执行诸如索引和搜索之类的任务。 
	你可以通过将三个节点配置为专用 master-eligible 节点来完成此操作。 专用 master-eligible 节点仅具有 master role，从而使他们可以专注于管理集群。 
	尽管主节点还可以充当协调节点，并将搜索和索引请求从客户端路由到数据节点，但最好不要为此目的使用专用的 master 节点。
	要创建专用的符合主机资格的节点，请设置：node.roles: [ master ]


Voting-only master-eligible node
	仅投票的 master-eligible 节点是参与master选举但不会充当集群的主节点。 特别是，仅投票节点可以在选举中充当决胜局。
	使用术语 “master eligible” 来描述仅投票的节点似乎令人困惑，因为这样的节点实际上根本没有资格成为主机。这个术语是历史的一个不幸后果：主节点资格是那些参加选举，并在集群状态发布执行某些任务，只有投票节点具有相同的责任，即使他们永远不能成为当选的主节点。
	要将符合条件的主节点配置为仅投票节点，请在角色列表中包括 master 和 voting_only。 例如，创建 voting_only 以及数据节点：node.roles: [ data, master, voting_only ]

	重要提示：
		voting_only需要Elasticsearch的默认发布版，并且在OSS发布中不支持该角色。 如果使用 OSS 发行版并添加voting_only角色，则该节点将无法启动。 还要注意，只有具有master节点才能被标记为具有voting_only角色。

	高可用性（HA）群集至少需要三个主节点，其中至少两个不是 voting_only 节点。即使其中一个节点发生故障，这样的群集也将能够选举一个主节点。

	由于 voting_only 节点从来不会担任集群主节点，和真正的主节点相比较，他们可能需要需要较少的堆和一个不太强大的 CPU。但是，所有 master-eligible 节点（包括 voting_only 节点）都需要相当快的持久性存储以及到集群其余部分的可靠且低延迟的网络连接，因为它们位于发布集群状态更新的关键路径上。

	具有voting_only的master-eligible节点也可以充当群集中的其他角色。例如，一个节点既可以是数据节点，又可以是voting_only的master-eligible节点。专用的voting_only master-eligible是不具备群集中的其他任何角色。
	要在默认发布中，创建专用的voting_only  master-eligible 节点，请设置：node.roles: [ master, voting_only ]
	
	推荐阅读:
		https://www.elastic.co/guide/en/elasticsearch/reference/7.x/modules-node.html#master-node
	
```



## 3.Data node

```
	具有 data role 的节点（默认）。数据节点包含包含你已建立索引的文档的分片。 数据节点处理与数据相关的操作，例如 CRUD，搜索和聚合。 具有数据角色的节点可以填充任何专门的数据节点角色。

	这些操作是 I/O，内存和 CPU 密集型的。 监视这些资源并在过载时添加更多数据节点非常重要。具有专用数据节点的主要好处是将 master 和 data 角色分开。
	
	具有专用数据节点的主要好处是将 master 和 data 角色分开。要创建专用数据节点，请设置：node.roles: [ data ]

	在多层（multi-tier）部署体系结构中，你可以使用专门的数据角色将数据节点分配给特定的层：data_content，data_hot，data_warm 或 data_cold。 一个节点可以属于多个层，但是具有专用数据角色之一的节点不能具有通用数据角色。

	推荐阅读:
		https://www.elastic.co/guide/en/elasticsearch/reference/7.x/modules-node.html#data-node

```



## 4.Ingest node

```
	具有 ingest role 的节点（默认）。 摄入节点能够将提取管道应用于文档，以便在建立索引之前转换和丰富文档。 在繁重的摄取负载下，使用专用的摄取节点并且不包含具有master role 或 data role 的节点中的摄取角色是有意义的。

	推荐阅读:
        https://www.elastic.co/guide/en/elasticsearch/reference/7.x/modules-node.html#node-ingest-node

```



## 5.Remote-eligible node

```
	具有 remote_cluster_client 角色（默认）的节点，这使其有资格充当远程客户端。 
	
	默认情况下，集群中的任何节点都可以充当跨集群客户端并连接到远程集群。
	
	连接后，你可以使用跨集群搜索来搜索远程集群。 你还可以使用跨集群复制在集群之间同步数据。设置方法为："node.roles: [ remote_cluster_client ]"
	
	
	推荐阅读:
		https://www.elastic.co/guide/en/elasticsearch/reference/7.x/modules-node.html#remote-node

```



## 6.Machine learning node

```
	具有 xpack.ml.enabled 和 ml 角色的节点，这是 Elasticsearch 默认发布中的默认行为。 
		
	如果要使用机器学习功能，则集群中必须至少有一个机器学习节点。 有关机器学习功能的更多信息，请参阅 Elastic Stack 中的机器学习。

	机器学习功能提供了机器学习节点，该节点运行作业并处理机器学习 API 请求。 如果 xpack.ml.enabled 设置为 true，并且该节点不具有 ml 角色，则该节点可以处理 API 请求，但不能运行作业。

	如果要在群集中使用机器学习功能，则必须在所有符合主机资格的节点上启用机器学习（将 xpack.ml.enabled 设置为true）。 如果要在客户端（包括 Kibana）中使用机器学习功能，则还必须在所有协调节点上启用它。 如果你只有 OSS 发行版，请不要使用这些设置。

	要在默认发布中创建专用的机器学习节点，请设置："node.roles: [ ml ]"和"xpack.ml.enabled: true" 
	
	在默认的情况下， xpack.ml.enabled 已经被启动。

	重要提示：
		如果你使用 OSS（out of specification，检验结果偏差） 发布版，千万不要添加 ml 角色，否则该节点将无法启动。

	推荐阅读:
		https://www.elastic.co/guide/en/elasticsearch/reference/7.x/modules-node.html#ml-node

```



## 7.Transform node

```
	具有transform role 的节点。 如果要使用转换，则群集中至少有一个转换节点。 有关更多信息，请参见变换设置和变换数据。

	注意：Coordnating node - 协调节点。

	诸如搜索请求或批量索引请求之类的请求可能涉及保存在不同数据节点上的数据。 例如，搜索请求在两个阶段中执行，这两个阶段由接收客户请求的节点（即协调节点）协调。

	在分散阶段，协调节点将请求转发到保存数据的数据节点。 每个数据节点在本地执行该请求，并将其结果返回到协调节点。 在收集阶段，协调节点将每个数据节点的结果缩减为单个全局结果集。

	转换节点运行转换并处理转换 API 请求。 如果你只有 OSS 发行版，请不要使用这些设置。 要在默认分发中创建专用的变换节点，请设置："node.roles: [ transform ]"

	推荐阅读:
		https://www.elastic.co/guide/en/elasticsearch/reference/7.x/modules-node.html#transform-node

```



## 8.Content data node

```
	Content data 节点容纳用户创建的内容。 它们启用 CRUD，搜索和聚合之类的操作。

	要创建专用的 content 节点，请设置：node.roles: [ data_content ]

```



## 9.Hot data node

```
	Hot data 数据节点在输入 Elasticsearch 时会存储时间序列数据。 热层必须能够快速进行读写操作，并且需要更多的硬件资源（例如 SSD 驱动器）。

	要创建专用的 hot 节点，请设置：node.roles: [ data_hot ]
```



## 10.Warm data node

```
	Warm data 节点存储的索引不再定期更新，但仍在查询L中。 查询量通常比索引处于热层时的频率低。 性能较低的硬件通常可用于此层中的节点。

	要创建专用的 Warm 节点，请设置：node.roles: [ data_warm ]
```



## 11.Cold data node

```
	Cold data 节点存储只读索引，该索引的访问频率较低。 该层使用性能较低的硬件，并且可能会利用可搜索的快照索引来最大程度地减少所需的资源。

	要创建专用的 cold 节点，请设置：node.roles: [ data_cold ]
```



## 12.Coordinating only node

```
	如果一个节点不担任 master 节点的职责，不保存数据，也不预处理文档，那么这个节点将拥有一个仅可路由请求，处理搜索缩减阶段并分配批量索引的协调节点。 本质上，仅协调节点可充当智能负载平衡器。

	仅协调节点可以通过从 data 和 master-eligible 节点上分担大量的协调角色从而使大型集群受益。 他们加入群集并像其他所有节点一样接收完整的群集状态，并且使用群集状态将请求直接路由到适当的位置。

	警告：在集群中添加过多的仅协调节点会增加整个集群的负担，因为选择的主节点必须等待每个节点的集群状态更新确认！ 仅协调节点的好处不应被夸大-数据节点可以很高兴地达到相同的目的。

	每个节点都隐式地是一个协调节点。 这意味着通过 node.roles 具有明确的空角色列表的节点将仅充当协调节点，无法禁用。 
	
	结果，这样的节点需要具有足够的内存和 CPU 才能处理收集阶段。
	
	要创建专用的协调节点，请设置：node.roles: [ ]

```



# 三.通过 API 来获得 node roles

```
	发送请求:
		curl -X GET http://elk101.oldboyedu.com:9200/_cat/nodes?v
	
	返回数据:
        ip            heap.percent ram.percent cpu load_1m load_5m load_15m node.role   master name
        172.200.3.101           58          29   0    0.03    0.03     0.05 cdfhilmrstw -      elk101.oldboyedu.com
        172.200.3.102           55          57   0    0.07    0.03     0.05 cdfhilmrstw *      elk102.oldboyedu.com
        172.200.3.103           70          28   0    0.00    0.01     0.05 cdfhilmrstw -      elk103.oldboyedu.com


	如下图所示，在node.role 中，我们可以看到这个 node 的角色。根据链接，上面的字母的意思是：
		c : 
			code node
		d : 
			data node
		f : 
			frozen node
		h : 
			hot node
		i : 
			ingest node
		l : 
			machine learning node
		m : 
			master eligible node
		r : 
			remote cluster client node
		s : 
			content node
		t : 
			transform node
		v : 
			voting-only node
		w : 
			warm node
		-  : 
			coordinating node only

	在上面的node role中，我们可以看出来，它同时具有多种角色。在实际的使用中，我们可以根据自己的需要为某些 node 定义特定的角色。

```



