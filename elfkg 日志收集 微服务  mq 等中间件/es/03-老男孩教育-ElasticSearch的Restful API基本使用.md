[TOC]





# [前置知识]

## 1.RESTful风格程序

```
	REST(英文全称为:"Representational State Transfer")指的是一组架构约束条件和原则。它是一种软件架构风格（约束条件和原则的集合，但并不是标准）。 

	REST通过资源的角度观察网络，以URI对网络资源进行唯一标识，响应端根据请求端的不同需求，通过无状态通信，对其请求的资源进行表述。

	满足REST约束条件和原则的架构或接口，就被称为是RESTful架构或RESTful接口。

	Web应用程序最重要的REST原则是:
		(1)客户端和服务器之间的交互在请求之间是无状态的;
		(2)从客户端到服务器的每个请求都必须包含理解请求所必需的信息;
		(3)如果服务器在请求之间的任何时间点重启，客户端不会得到通知;
		(4)无状态请求可以由任何可用服务器回答，这十分适合云计算之类的环境，客户端可以缓存数据以改进性能。

	在服务器端，应用程序状态和功能可以分为各种资源。资源是一个有趣的概念实体，它向客户端公开。资源的例子有：应用程序对象、数据库记录、算法等等。

	每个资源都使用URI(Universal Resource Identifier)得到一个唯一的地址。
	
	所有资源都共享统一的接口，以便在客户端和服务器之间传输状态。使用的是标准的HTTP方法，比如GET、PUT、POST和DELETE等。

	我们可以向Elasticsearch发送数据或者其返回数据均是JSON(英文全称为:"JavaScript Object Notation")格式。

```



## 2.JSON快速入门

```
什么是JSON:
	JSON是一种轻量级的文本数据交换格式而非编程语言，其语法只支持字符串，数值，布尔值及null以及在此基础上的对象和数组。

举个例子:
	基础数据类型(支持的基础数据类型参考下表):
		name = "oldboy"
		age = 43
	数组:
		teachers = ["oldboy", "苍老师","加藤鹰","小园梨央"]
	对象:
		obs = {
			"name": "oldboy",
			"age":43,
			"habby":"linux，象棋，跑步"
		}
		
推荐阅读：
	https://www.w3cschool.cn/json/json-intro.html

```

| 数据类型 | 举例       | 说明                                                        |
| -------- | ---------- | ----------------------------------------------------------- |
| 字符串   | "oldboy"   | 使用双引号引用字符串                                        |
| 数值     | 2021       | 值得注意的是，如果使用双引号"2021"，则其为字符串而非数字哟~ |
| 布尔值   | true/false | 只有真(true)和假(false)两个值。                             |
| 空值     | null       | 表示一个空值。                                              |



# 一.ElasticSearch相关术语介绍

## 1.文档（Document）

```
	文档就是用户存在ElasticSearch的一些数据，它是ElasticSearch中存储数据的最小单元。
	
	文档类似于MySQL数据库中表中的一行数据。每个文档都有唯一的"_id"标识，我们可以自定义"_id"（不推荐），如果不指定ES也会自动生成。
	
	一个文档是一个可被索引的基础信息单元，也就是一条数据。在一个"index/_doc"里面，我们可以存储任意多的文档。
	
	文档是以JSON（Javascript Object Notaion)格式来表示，而JSON是一个到处存在的互联网数据交互格式。
	
	JSON比XML更加轻量级，目前JSON已经成为互联网事实的数据交互标准了，几乎是所有主流的编程语言都支持。

```





## 2.字段（Filed）

```
	相当于数据库表的字段，对文档数据根据不同属性进行的分类标识。
	
	在ES中，Document就是一个Json Object，一个json objec其实是由多个字段组成的，每个字段它由不同的数据类型。

  推荐阅读：
        https://www.elastic.co/guide/en/elasticsearch/reference/7.12/mapping-types.html

```



## 3.索引(index)

```
	一个索引就是一个拥有相似特征的文档（Document）的集合。假设你的公司是做电商的，可以将数据分为客户，产品，订单等多个类别，在ES数据库中就对应多个索引。
   
	ES索引、文档、字段关系小结：
		一个索引里面存储了很多的Document 文档，一个文档就是一个json object，一个json object是由多个不同的filed字段组成；

	Elasticsearch索引的精髓：一切设计都是为了提高搜索的性能。换句话说，在ES存储的数据，万物皆索引，如果数据没有索引则无法查询数据。
```





## 4.分片（Shards）----> (先讲解上面3个概念)

```
	我们假设平均1个文档占用2k大小，那么按照utf-8对中文的字符编码，该文档能存储682（2 * 1024 / 3）个汉字。
	
	如果我们要存储30亿条数据，则需要使用5722GB(3000000000 * 2k，不足6T)存储空间，
    
	一个索引可以存储超出单个节点硬件限制的大量数据。比如，一个具有30亿文档数据的索引占据6TB的磁盘空间。
	
	如果一个集群有3台服务器，单个节点的磁盘存储空间仅有4T磁盘空间，很明显某一个节点是无法存储下6TB数据的。或者单个节点处理搜索请求，响应太慢。
	
	为了解决这个问题，elasticsearch提供了将索引划分成多份的能力，每一份都称之为分片。
	
	当你创建一个索引的时候，你可以指定你想要的分片数量。每个分片本身也是一个功能完善并且独立的"索引"，这个"索引"可以被放置到集群中的任何节点上。

	分片很重要，主要有两方面的原因：
		(1)允许你水平分割/扩展你的内容容量，当然你也可以选择垂直扩容；
		(2)允许你在各节点上的分片进行分布式，并行的操作，从而显著提升性能（包括但不限于CPU，内存，磁盘，网卡的使用），最显著的是吞吐量的提升;
		
	至于一个分片怎么分布，它的文档怎样聚合和搜索请求，是完全由elasticsearch管理的，对于作为用户的你来说，这些都是透明的，无需过分关心。
	

温馨提示：
	一个Lucene索引我们在Elasticsearch称作分片。
	一个ElasticSearch索引是分片的集合。
	当ElasticSearch在索引中搜索的时候，她发送查询到每一个属于索引的分片(Lucene索引)，然后合并每个分片的结果到一个全局的结果集。
```



## 5.副本（Replicas）

```
	无论是在公司内部的物理机房，还是在云环境中，节点故障随时都有可能发生，可能导致这些故障的原因包括但不限于服务器掉电，Raid阵列中的磁盘损坏，网卡损坏，同机柜交换机损坏等。

	在某个分片/节点不知为何就处于离线状态，或者由于任何原因消失了，这种情况下，有一个故障转移机制是非常有用并且是强烈推荐的。
	
	为此目的，elasticsearch允许你创建分片的一份或多份拷贝，这些拷贝叫做复制分片（我们也习惯称之为“副本”）。


	副本之所以重要，主要有以下两个原因：
		（1）在分片/节点失败的情况下，提供了高可用性。因为这个原因，注意到复制分片从不与主分片(primary shard)置于同一个节点上是非常重要的;
		(2)扩展你的搜索量/吞吐量，因为搜索可以在所有的副本上并行运行；
	
	总之，每个索引可以被分配成多个分片。一个索引也可以被复制0次(意思是没有副本分片，仅有主分片)或多次。
	
	一旦复制了，每个索引就有了主分片(作为复制源的原来的分片)和复制分片(主分片的拷贝)之别。分片和复制的数量可以在索引创建的时候指定。
	
	在索引创建之后，你可以在任何时候动态地改变复制的数量，但是你事后不能改变分片的数量。
	
	默认情况下，elasticsearch中的每个索引被分片1个主分片和1个复制分片，这样的话一个索引总共就有2个分片，我们需要根据索引需求确定分片个数。

```



## 6.分配（Allocation）

```
	所谓的分配就是将分片分配给某个节点的过程，包括主分片或者副本。如果是副本，还包含从主分片复制数据的过程，这个过程由master节点完成的。
```



## 7.类型（type）

```
	在elasticsearch 5.x及更早的版本，在一个索引中，我们可以定义一种或多种类型。但在ES 7.x版本中，仅支持"_doc"类型。

	一个索引是你的索引的一个逻辑上的分类/分区，其语义完全由你来定，通常，会为具有一组共同字段的文档定义一个类型。
	
```



## 8.映射（Mapping）

```
	mapping是处理数据的方式和规则方面做一些限制，如：某个字段的数据类型，默认值，分析器，是否被索引等等。
	
	这些都是映射里面可以设置的，其它就是处理ES里面数据的一些使用规则设置也叫做映射。
	
	按着最优规则处理数据对性能提高很大，因此才需要建立映射，并且需要思考如何建立映射才能对性能更好。
	
	值得注意的是，课程后面有相应的案例哟~
```



## 9.DSL概述

```
	Elasticsearch提供丰富且灵活的查询语言叫做DSL查询(Query DSL)，它允许你构建更加复杂，强大的查询。
	
	DSL(Domain Specific Language特定领域语言)以JSON请求体的形式出现。
	
	值得注意的是，下面由相关的案例。
```



# 二.管理索引常用的API

## 1.查看现有索引信息

```
查看所有索引信息列表：
	curl -X GET http://elk101.oldboyedu.com:9200/_cat/indices?v

查看某个索引的详细信息:
	curl -x GET http://elk101.oldboyedu.com:9200/linux-2020-10-2

温馨提示: 
	(1)"?v"表示输出表头信息，如下所示:
        health status index           uuid                   pri rep docs.count docs.deleted store.size pri.store.size
        green  open   linux-2020-10-1 JDAp11N8RVqyjGROol3J4Q   1   1          0            0       416b           208b
        green  open   bigdata         3k606BwcTIWZOHG3tRPMNA   5   2          0            0        3kb            1kb
        green  open   linux-2020-10-3 8DJBzgo2Sn2qwe-UDa8_RA   1   1          0            0       416b           208b
        green  open   linux-2020-10-2 NsO3vA-JTZ61W4OH4OqGxw   1   1          0            0       416b           208b
        green  open   linux           I0jNRp0wT8OgvR9Uf6EZow   1   1          0            0       416b           208b
        green  open   bigdata3        h1OS5CX6TomeDY_dcdy-vQ   3   1          0            0      1.2kb           624b
        green  open   bigdata2        egmZVZS6QqCpACPBe2-1LA   1   1          0            0       416b           208b
	(2)curl默认发送的就是GET请求;


以下是对响应结果进行简单的说明:
	health:
		green:
			所有分片均已分配。
		yellow:
			所有主分片均已分配，但未分配一个或多个副本分片。如果群集中的节点发生故障，则在修复该节点之前，某些数据可能不可用。
		red:
			未分配一个或多个主分片，因此某些数据不可用。在集群启动期间，这可能会短暂发生，因为已分配了主要分片。
	status:
		索引状态，分为打开和关闭状态。
	index:
		索引名称。
	uuid:
		索引唯一编号。
	pri:
		主分片数量。
	rep:
		副本数量。
	docs.count:
		可用文档数量。
	docs.deleted:
		文档删除状态(逻辑删除)。
	store.size:
		主分片和副分片整体占空间大小。
	pri.store.size:
		主分片占空间大小。
```



## 2.创建索引

```
curl -X PUT http://elk101.oldboyedu.com:9200/bigdata

可选提交的数据如下:
    {
        "settings": {
            "index": {
                "number_of_replicas": "1",
                "number_of_shards": "3"
            }
        }
    }
    
  
温馨提示:
	(1)对于提交的参数说明:
		"number_of_replicas"参数表示副本数。
		"number_of_shards"参数表示分片数。
	(2)对于返回的参数说明:
		"acknowledged"参数表示响应结果，如果为"true"表示操作成功。
		"shards_acknowledged"参数表示分片结果,如果为"true"表示操作成功。
		"index"表示索引名称。
	(3)创建索引库的分片数默认为1片，在7.0.0之前的Elasticsearch版本中，默认为5片。
	(4)如果重复添加索引，会返回错误信息;

```



## 3.删除索引[生产环境中谨慎操作,建议先使用关闭索引一段时间在进行删除]

```
根据索引模式删除:
	curl -X DELETE http://elk101.oldboyedu.com:9200/linux-2020-11*
	
删除某个特定的索引:
	curl -X DELETE http://elk101.oldboyedu.com:9200/linux-2020-10-2
                                                                                
```



## 4.查看某个索引是否存在

```
curl -X HEAD http://elk101.oldboyedu.com:9200/linux-2020-10-2

温馨提示:
	注意观察返回的状态码，如果返回"200"说明该索引是存在的，如果返回"400"，说明索引是不存在的。
```



## 5.索引别名

```
curl -X POST http://elk101.oldboyedu.com:9200/_aliases

提交数据如下:
	（1）添加别名：
        {
          "actions" : [
            { "add" : { "index" : "linux-2020-10-3", "alias" : "linux2020" } },
            { "add" : { "index" : "linux-2020-10-3", "alias" : "linux2021" } }
          ]
        }
        
	（2）删除别名
        {
          "actions" : [
            { "remove" : { "index" : "linux-2020-10-3", "alias" : "linux2025" } }
          ]
        }

	（3）重命名别名
        {
          "actions" : [
            { 
                "remove" : { "index" : "linux-2020-10-3", "alias" : "linux2023" } 
            },
            {
                "add": { "index" :"linux-2020-10-3" , "alias" : "linux2025" }
            }
          ]
        }
	
	（4）为多个索引同时添加别名
        {
          "actions" : [
            {
                "add": { "index" :"bigdata3" , "alias" : "linux666" }
            },
            {
                "add": { "index" :"bigdata2" , "alias" : "linux666" }
            },
            {
                "add": { "index" :"linux-2020-10*" , "alias" : "linux666" }
            }
          ]
        }


温馨提示:
	(1)索引别名是用于引用一个或多个现有索引的辅助名称。大多数Elasticsearch API接受索引别名代替索引;
	(2)加索引后请结合"elasticsearch-head"的WebUI进行查看;
	(3)一个索引可以关联多个别名，一个别名也能被多个索引关联;
	
```



## 6.关闭索引

```
关闭某一个索引：
	curl -X POST http://elk101.oldboyedu.com:9200/linux-2020-10-1/_close

关闭批量索引：
	curl -X POST http://elk101.oldboyedu.com:9200/linux-2020-*/_close

温馨提示:
	(1)如果将索引关闭，则意味着该索引将不能执行任何打开索引状态的所有读写操作，当然这样也会为服务器节省一定的集群资源消耗；
	(2)生产环境中，我们可以将需要删除的索引先临时关闭掉，可以先关闭7个工作日，然后在执行删除索引，因为光关闭索引尽管能减少消耗但存储空间依旧是占用的;
	(3)关闭索引后，记得查看现有索引信息，并结合"elasticsearch-head"插件的WebUI界面进行查看哟;
	
```



## 7.打开索引

```
打开某一索引:
	curl -X POST  http://elk101.oldboyedu.com:9200/linux-2020-10-3/_open
	
打开批量索引:
	curl -X POST  http://elk101.oldboyedu.com:9200/linux-2020-*/_open
```



## 8.其它操作

```
推荐阅读:
	https://www.elastic.co/guide/en/elasticsearch/reference/current/indices.html
```



# 三.管理文档的基本操作API

## 1.添加文档

```
使用POST方法创建文档，创建文档时会自动生成随机文档的"_id"（推荐方式）：
	curl -X POST http://elk101.oldboyedu.com:9200/shopping/_doc

使用POST方法创建文档，我们也可以自定义文档文档的"_id"：（不推荐使用，因为在数据量比较大的时候，自定义"_id"可能会存在如何去重的情况）
	curl -X POST http://elk101.oldboyedu.com:9200/shopping/_doc/10010

使用PUT方法创建文档姿势一：
	curl -X PUT http://elk101.oldboyedu.com:9200/shopping/_doc/10011
	
使用PUT方法创建文档姿势二：
	curl -X PUT http://elk101.oldboyedu.com:9200/shopping/_create/10012

提交以下数据:
    {
        "title":"戴尔（DELL）31.5英寸 4K 曲面 内置音箱 低蓝光 影院级色彩 FreeSync技术 可壁挂 1800R 电脑显示器 S3221QS",
        "price":3399.00 ,
        "brand": "Dell",
        "weight": "15.25kg",
        "item": "https://item.jd.com/100014940686.html"
    }


温馨提示:
	PUT方法要求幂等性，二POST方法则并不要求幂等性。所谓的幂等性可参考请求的"_id"和响应返回的"_id"是否一致。

```



## 2.查询文档

```
主键查询：
	curl -X GET http://elk101.oldboyedu.com:9200/shopping/_doc/10012
	
全查询:
	curl -X GET http://elk101.oldboyedu.com:9200/shopping/_search
	
判断文档是否存在:（只需要观察响应的状态码，如果为200说明文档存在，如果是404说明文档不存在）
	curl -X HEAD http://elk101.oldboyedu.com:9200/shopping/_doc/x0zdh3kBpj8F95BSQ5Pv
	

一个文档中不仅仅存在数据，它还包含了元数据(metadata)，即关于文档的信息。换句话说，就是描述数据的数据。

三个必须的元数据节点是"_index"，"_type"和"_id"：
	"_index":
		文档添加到的索引名称，即文档存储的地方。
		索引(index)类似于关系型数据库里的"数据库"，它是我们存储和索引关联数据的地方。
		事实上，我们的数据被存储和索引在分片(shards)中，索引是把一个或多个分片分组在一起的逻辑空间。
		然而，这只是一些内部细节，我们的程序完全不用关心分片。对于我们的程序而言，文档存储在索引(index)中。剩下的细节由Elasticsearch关心既可。
	"_type":
		文件类型。Elasticsearch索引现在支持单一文档类型_doc。
		
	"_id":
		添加文档的唯一标识符。
		id仅仅是一个字符串，它与"_index"和"_type"组合时，就可以在Elasticsearch中唯一标识一个文档。
		当创建一个文档时，你可以自定义"_id"，也可以让Elasticsearch帮你自动生成(32位长度)。

温馨提示:
	如果用浏览器查看返回数据可能看起来不太美观，我们可以借助"pretty"参数来使得输出的可读性更强。当然，我们也可以借助插件哟~

```



## 3.更新文档

```
全局更新：（生产环境使用较少）
	curl -X PUT/POST http://elk101.oldboyedu.com:9200/shopping/_doc/10012
        {
            "title": "ALIENWARE外星人新品外设高端键鼠套装AW510K机械键盘cherry轴 RGB/AW610M 610M 无线鼠标+510K机械键盘+510H耳机",
            "price": 5200.00,
            "brand": "ALIENWARE外星人",
            "weight": "1.0kg",
            "item": "https://item.jd.com/10030370257612.html"
        }
        
局部更新：（生产环境经常使用）
	curl -X POST http://elk101.oldboyedu.com:9200/shopping/_update/10012
	curl -X POST http://elk101.oldboyedu.com:9200/shopping/_doc/10012/_update
        {
            "doc":{
                "price": 6000.00,
                "weight": "2.0kg"
            }
        }
        
   

温馨提示：
	更新局部数据时，说明每一次更新数据返回的结果都不相同，因此我们不应该使用PUT方法，而是使用POST方法哟~

```



## 4.删除文档

```
curl -X DELETE http://elk101.oldboyedu.com:9200/shopping/_doc/10012
```



# 四.ElasticSearch的DSL查询语言

## 1.条件查询

```
基于请求路径实现条件查询：
	curl -X GET/POST http://elk101.oldboyedu.com:9200/shopping/_search?q=brand:DELL
	
基于请求体实现条件查询：
	curl -X GET/POST http://elk101.oldboyedu.com:9200/shopping/_search
        {
            "query":{
                "match":{
                    "brand":"DELL"
                }
            }
        }	

基于请求体实现全量查询：
	curl -X GET/POST http://elk101.oldboyedu.com:9200/shopping/_search
	可选的以下请求体：
        {
            "query":{
                "match_all":{

                }
            }
        }
```



## 2.分页查询

```
	假设有20条数据，我们规定每页仅有3条数据，我们想要查看第7页的数据，就可以执行下面的查询语句。
	
    curl -X GET/POST http://elk101.oldboyedu.com:9200/shopping/_search
        {
            "query":{
                "match_all":{

                }
            },
            "from": 18,
            "size": 3
        }

	字段说明：
        from:
            指定跳过的数据偏移量大小，默认是0。
            查询指定页码的from值 = ”(页码 - 1) * 每页数据条数“。
        size:
            指定显示的数据条数大小，默认是10。

	在集群系统中深度分页：
		我们应该当心分页太深或者一次请求太多的结果，结果在返回前会被排序。
		但是记住一个搜索请求常常涉及多个分片。
		每个分片生成排好序的结果，它们接着需要集中起来排序以确保整体排序顺序。
		
	为了理解为什么深度分页是有问题的，让我们假设在一个有5个主分片的索引中搜索:
        (1)当我们请求结果的第一页(结果1到10)时，每个分片产生自己最顶端10个结果然后返回它们给请
        求节点(requesting node)，它在排序这所有的50个结果以筛选出顶端的10个结果；
        (2)现在假设我们请求第1000页，结果10001到10010，工作方式都相同，不同的时每个分片都必须
        产生顶端的10010个结果，然后请求节点排序这50050个结果并丢弃50040个;
        (3)你可以看到在分布式系统中，排序结果的花费随着分页的深入而成倍增长，这也是为什么网络
        搜索引擎中任何语句返回多余1000个结果的原因；
		
```



## 3.只查看返回数据的指定字段

```
	假设有20条数据，我们规定每页仅有3条数据，我们想要查看第7页的数据，并只查看"brand"和"price"这两个字段，就可以执行下面的查询语句。
	
    curl -X GET/POST http://elk101.oldboyedu.com:9200/shopping/_search
        {
            "query":{
                "match_all":{

                }
            },
            "from": 18,
            "size": 3,
            "_source": ["brand","price"]
        }
```



## 4.查看指定字段并排序

```
	假设有20条数据，我们规定每页仅有3条数据，我们想要查看第7页的数据，并只查看"brand"和"price"这两个字段，就可以执行下面的查询语句。
	
    curl -X GET/POST http://elk101.oldboyedu.com:9200/shopping/_search
       {
            "query":{
                "match_all":{

                }
            },
            "from": 18,
            "size": 3,
            "_source": ["brand","price"],
            "sort":{
                "price":{
                    "order":"desc"
                }
            }
        }
        
	温馨提示:
		"desc"表示降序排列，而"asc"表示升序排列。

```



## 5.多条件查询

```
    curl -X GET/POST http://elk101.oldboyedu.com:9200/shopping/_search
    
    使用must查询，则查询结果必须满足所有的匹配要求，缺一不可：
        {
            "query":{
                "bool":{
                    "must":[
                        {
                            "match":{
                             "price": 429
                            }
                        },
                        {
                            "match":{
                                "brand": "罗技"
                            }
                        }
                    ]
                }
            }
        }
        
    使用should查询，则查询结果只须满足其中一个匹配的要求即可：
        {
            "query":{
                "bool":{
                    "should":[
                        {
                            "match":{
                             "price": 429
                            }
                        },
                        {
                            "match":{
                                "brand": "DELL"
                            }
                        }
                    ]
                }
            }
        }

	使用"minimum_should_match"参数实现最少满足需求的文档数查找：
        {
            "query":{
                "bool":{
                    "should":[
                        {
                            "match":{
                             "brand": "华为"
                            }
                        },
                        {
                            "match":{
                                "brand": "小米"
                            }
                        },
                        // {
                        //     "match":{
                        //         "brand": "苹果"
                        //     }
                        // },
                        {
                           "match":{
                                "price": "4699"
                            }
                        }
                    ],
                    "minimum_should_match": 2  // 至少要满足2个should需求才能获取到对应的文档哟~
                }
            }
        }

	使用"minimum_should_match"参数实现最少满足需求的文档数查找，采用百分比案例:
        {
            "query":{
                "bool":{
                    "should":[
                        {
                            "match":{
                             "brand": "华为"
                            }
                        },
                        {
                            "match":{
                                "brand": "小米"
                            }
                        },
                        // {
                        //     "match":{
                        //         "brand": "苹果"
                        //     }
                        // },
                        {
                           "match":{
                                "price": "4699"
                            }
                        }
                    ],
                    "minimum_should_match": "60%"  //可以适当调大，比如调到70%观察命中结果!
                }
            }
        }
        

    温馨提示:
    	bool查询可以用来合并多个条件查询结果的布尔逻辑，这些参数可以分别继承一个查询或者一个查询条件的数组。
    	bool查询包含以下操作符:
    		must:
            	多个查询条件的完全匹配，相当于"and"。
            must_not:
            	多个查询条件的相反匹配，相当于"not"。
            should:
                至少有一个查询条件匹配，相当于"or"。
                
	评分计算规则：
		(1)bool查询会为每个文档计算相关度评分"_score"，再将所有匹配的must和should语句的分数"_score"求和，最后除以must和should语句的总数。
		(2)must_not语句不会影响评分，它的作用只是将不相关的文档排除。
		(3)默认情况下，should中的内容不是必须匹配的，如果查询语言中没有must，那么就会至少匹配其中一个。当然，也可以通过"minimum_should_match"来指定匹配度，该值可以是数字(例如"2")也可以是
百分比(如"65%")。
```



## 6.范围查询

```
    curl -X GET/POST http://elk101.oldboyedu.com:9200/shopping/_search
        {
            "query":{
                "bool":{
                    "must":[
                        {
                            "match":{
                                "brand": "罗技"
                            }
                        }
                    ],
                    "filter":{
                        "range":{
                            "price":{
                                "gt": 100,
                                "lt":300
                            }
                        }
                    }
                }
            }
        }
        
	温馨提示：
		(1)上面的查询条件是匹配"brand"的值"罗技"的数据并按照"price"进行范围过滤;
		(2)常用的范围操作符包含如下所示:
            gt:
            	大于。
            gte:
            	大于等于。
            lt:
            	小于。
            lte:
            	小于等于。

```



## 7.全文检索

```
    curl -X GET/POST http://elk101.oldboyedu.com:9200/shopping/_search
        {
            "query":{
                "match":{
                    "brand":"小华苹"
                }
            }
        }

   温馨提示:
   		(1)尽管我们没有"小华苹"的品牌，但ES在查询的时候会对"小华苹"进行文字拆分，会使用倒排索引技术去查找文档，从而查到小米， 华为，苹果的品牌。
   		(2)match查询会在真正查询之前用分词器先分析，默认的中文分词器并不太适合使用，生产环境建议更换分词器，比如IK分词器等。

```



## 8.完全匹配

```
    curl -X GET/POST http://elk101.oldboyedu.com:9200/shopping/_search
        {
            "query":{
                "match_phrase":{
                    "brand":"小华果"
                }
            }
        }
        
	温馨提示:
		我们可以使用"match_phrase"进行完全匹配，则返回0条匹配结果。
```



## 9.语法高亮

```
    curl -X GET/POST http://elk101.oldboyedu.com:9200/shopping/_search
        {
            "query":{
                "match_phrase":{
                    "brand":"苹果"
                }
            },
            "highlight":{
                "fields":{
                    "brand":{}
                }
            }
        }
```



## 10.精确匹配查询

```
curl -X PUT http://elk101.oldboyedu.com:9200/shopping/_search	

    {
        "query": {
            "term": {
               "price": 4699 // 查询字段的值尽量不要使用中文哟~如果非要用，建议使用特定的分词器!
            }
        }
    }
    
    
    {
        "query": {
            "terms": {
                "price": [299,4066,499]
            }
        }
    }

温馨提示：
	term主要用于精确匹配哪些值，比如数字，日期，布尔值或"not_analyzed"(未经分析的文本数据类型)的字符串。
	terms跟term有点类似，但terms允许指定多个匹配条件，如果某个字段指定了多个值，那么文档需要满足其一条件即可。
```



## 11.查询包含指定字段的文档

```
    curl -X POST http://elk101.oldboyedu.com:9200/teacher/_search
        {
            "query": {
                "exists": {
                    "field": "hobby"  // 只查询含有"hobby"字段的文档。
                }
            }
        }

	温馨提示:
		(1)关于"teacher"索引的数据生成，可直接参考下面的"批量操作"创建数据的案例。
		(2)exists查询可以用于查找文档中是否包含指定字段或没有某个字段，这个查询只是针对已经查出一批数据来，但是想区分出某个字段是否存在的时候使用。

```



## 12.过滤查询

```
    curl -X POST http://elk101.oldboyedu.com:9200/teacher/_search
        {
            "query":{
                "bool":{
                    "filter":{
                        "term":{
                            "hobby":"linux"
                        }
                    }
                }
            }
        }
        
	match和filter查询对比:
        (1)一条过滤(filter)语句会询问每个文档的字段值是否包含着特定值;
        (2)查询(match)语句会询问每个文档的字段值与特定值的匹配程序如何:一条查询(match)语句会计算每个文档与查询语句的相关性，会给出一个相关性评分"_score"，并且按照相关性对匹配到的文档进行排序。这种评分方式非常适用于一个没有完全配置结果的全文本搜索。
        (3)一个简单的文档列表，快速匹配运算并存入内存是十分方便的，每个文档仅需要1个字节。这些缓存的过滤结果集与后续请求的结果使用是非常高效的;
        (4)查询(match)语句不仅要查询相匹配的文档，还需要计算每个文档的相关性，所以一般来说查询语句要比过滤语句更好使，并且查询结果也不可缓存。

	温馨提示:
		做精确匹配搜索时，最好用过滤语句，因为过滤语句可以缓存数据。但如果要做全文搜索，需要通过查询语句来完成。
```



## 13.多词搜索

```
(1)默认基于"or"操作符对某个字段进行多词搜索
curl -X GET http://elk101.oldboyedu.com:9200/shopping/_search

    {
        "query":{
            "bool":{
                "must":{
                    "match":{
                        "title":{
                            "query":"曲面设计",
                            "operator":"or"
                        }
                    }
                }
            }
        },
        "highlight":{
            "fields":{
                "title":{}
            }
        }
    }
    
 
(2)基于"and"操作符对某个字段进行多词搜索
curl -X GET http://elk101.oldboyedu.com:9200/shopping/_search
    {
        "query":{
            "bool":{
                "must":{
                    "match":{
                        "title":{
                            "query":"曲面显示器",
                            "operator":"and"
                        }
                    }
                }
            }
        },
        "highlight":{
            "fields":{
                "title":{}
            }
        }
    }

```



## 14.权重案例(了解即可)

```
	有些时候，我们可能需要对某些词增加权重来影响这条数据的得分。

curl -X GET http://elk101.oldboyedu.com:9200/shopping/_search
    {
        "query": {
            "bool": {
                "must": {
                    "match": {
                        "brand": {
                            "query": "小苹华",
                            "operator": "or"
                        }
                    }
                },
                "should": [
                    {
                        "match": {
                            "title": {
                                "query": "防水",
                                "boost": 2
                            }
                        }
                    },
                    {
                        "match": {
                            "title": {
                                "query": "黑色",
                                "boost": 20
                            }
                        }
                    }
                ]
            }
        },
        "highlight": {
            "fields": {
                "title": {},
                "brand": {}
            }
        }
    }

```



## 15.聚合查询

```
	curl -X GET/POST http://elk101.oldboyedu.com:9200/shopping/_search

	按照brand字段进行分组：
        {
            "aggs": { // 聚合操作
                "oldboyedu_brand_group": { // 该名称可以自定义，我习惯性基于相关字段起名称。
                    "terms": { // 分组
                        "field": "brand.keyword" // 指定用于计算的相关字段，此处指定的时brand字段，但brand字段的fielddata默认值为false，因此此处我们需要写brand.keyword"
                    }
                }
            },
            "size": 0 // 设置显示hits数据的大小，当size的值为0时，表示不查看原始数据!如果设置大于0，则显示指定的数据条数。如果设置为-1，则只显示10条，如果设置小于-1则报错!
        }
        
    按照”price“字段计算所有商品的平均值：
        {
            "aggs": { // 聚合操作
                "oldboyedu_price_avg": { // 该名称可以自定义，我习惯性基于相关字段起名称。
                    "avg": { // 求平均值
                        "field": "price" // 分组字段
                    }
                }
            },
            "size": 0 // 设置显示hits数据的大小，当size的值为0时，表示不查看原始数据!如果设置大于0，则显示指定的数据条数。如果设置为-1，则只显示10条，如果设置小于-1则报错!
        }

    按照”price“字段计算所有商品的最大值：
        {
            "aggs": { // 聚合操作
                "oldboyedu_price_avg": { // 该名称可以自定义，我习惯性基于相关字段起名称。
                    "max": { // 求最大值
                        "field": "price" // 分组字段
                    }
                }
            },
            "size": 0 // 设置显示hits数据的大小，当size的值为0时，表示不查看原始数据!如果设置大于0，则显示指定的数据条数。如果设置为-1，则只显示10条，如果设置小于-1则报错!
        }
    
    按照”price“字段计算所有商品的最小值：
        {
            "aggs": { // 聚合操作
                "oldboyedu_price_avg": { // 该名称可以自定义，我习惯性基于相关字段起名称。
                    "min": { // 求最小值
                        "field": "price" // 分组字段
                    }
                }
            },
            "size": 0 // 设置显示hits数据的大小，当size的值为0时，表示不查看原始数据!如果设置大于0，则显示指定的数据条数。如果设置为-1，则只显示10条，如果设置小于-1则报错!
        }

	计算买下所有的dell品牌的需要多少钱:
        {
            "query": {
                "match": {
                    "brand": "DELL"
                }
            },
            "aggs": { // 聚合操作
                "oldboyedu_price_avg": { // 该名称可以自定义，我习惯性基于相关字段起名称。
                    "sum": { // 求最小值
                        "field": "price" // 分组字段
                    }
                }
            },
            "size": 0
        }
```



## 16.推荐阅读

```
DSL语句:
https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html
        
聚合函数:
https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html
```





# 五.批量操作

## 1.为什么要使用批量操作

```
	有些情况下可以通过批量操作以减少网络请求,也可以实现可重复性的利用率。例如：批量查询，批量插入数据。
```



## 2.批量插入操作

```

	温馨提示:
		元数据最少要写一个在Elasticsearch中，支持批量的插入，修改，删除操作，都是通过"_bulk"的API完成的。

	批量插入请求格式如下:(请求格式不同寻常)
        { action: { metadata }}\n
        { request body }\n
        { action: { metadata }}\n
        { request body }\n
        ...
        
    批量插入数据：
		curl -X POST http://elk101.oldboyedu.com:9200/_bulk
            {"create":{"_index":"teacher","_type":"_doc","_id":9001}}
            {"id":1001,"name":"oldboy","gender":"Male","telephone":"1024","address":"北京沙河","hobby":"linux 象棋 羽毛球 跑步"}
            {"create":{"_index":"teacher","_type":"_doc"}}
            {"id":1002,"name":"吉泽明步","gender":"Female","telephone":"2048"}
            {"create":{"_index":"teacher","_type":"_doc","_id":9002}}
            {"id":1003,"name":"苍老师","gender":"Female","telephone":"4096","address":"日本东京"}
            {"create":{"_index":"teacher"}}
            {"id":1004,"name":"加藤鹰","gender":"Male","telephone":"8192"}
            {"create":{"_index":"teacher","_id":9003}} 
            {"id":1004,"name":"小园梨央","gender":"Female","address":"日本东京","hobby":"自拍、拉拉队"}


	温馨提示:
		从上面的案例可以看出，元数据最少要写一个"_index"。而对应的提交的请求体则可以根据我们的需求自定义即可。

```



## 3.批量查询操作

```
curl -X POST http://elk101.oldboyedu.com:9200/teacher/_mget
    {
        "ids":["9001","9002","9003","9005"] // 查询ID为"9001","9002","9003","9005"的数据。
    }	
    
温馨提示：
	注意观察响应的结果，如果数据没有查询到，则found"的值为false。
	
```



## 4.批量删除数据

```
	在Elasticsearch中，支持批量的插入，修改，删除操作，都是通过"_bulk"的API完成的。
	
	批量删除请求格式如下:(请求格式不同寻常)
        { action: { metadata }}\n
        { action: { metadata }}\n
        { action: { metadata }}\n
        
	批量删除数据:
    	curl -X POST http://elk101.oldboyedu.com:9200/teacher/_doc/_bulk
            {"delete":{"_index":"teacher","_type":"_doc","_id":9001}}
            {"delete":{"_index":"teacher","_id":9002}}
            {"delete":{"_index":"teacher","_id":9003}}
            {"delete":{"_index":"teacher","_id":9005}}

	温馨提示：
		（1）关于URL的"_doc"其实是可以省略不写的，我此处是一个习惯性操作，表示是对文档的操作；
		（2）请求体最后最后一行一定要有一个换行符;
		（3）删除数据的结果查看响应体的"result"字段，如果为"not_found"，则说明数据未删除，因为没有找到该文档；
		
```



## 5.一次性批处理多少性能最高

```
	ES提供了Bulk API支持批量操作，当我们有大量的写任务时，可以使用Bulk来进行批量写入。

	对于批量操作，我们一次性批量多少操作性能最高呢？我们不得不参考以下几点:
		(1)整个批量请求需要被加载到接收我们请求节点的内存里，所以请求越大，给其它请求可用的内存就越小。有一个最佳的bulk请求大小。超过这个大小，性能不能提升而且可能降低;
		(2)最佳大小，当然并不是一个固定的数字，它完全取决于你的硬件，你文档的大小和复杂度以及索引和搜索的负载;
		(3)幸运的是，这个最佳点(sweetspot)还是容易找到的，试着批量索引标准的文档，随着大小的增长，当性能开始降低，说明你批次的大小太大了。开始的数量可以在1000-5000个文档之间，如果你的文档非常大，可以使用较小的批次；
		(4)通常着眼于你请求批次的物理大小是非常有用的，1000个1KB的文档和1000个1MB的文档大不相同，一个好的批次最好保持在5~15MB逐渐增加，当性能没有提示时，把这个数据量作为最大值;
		(5)bulk默认设置批量提交的数据量不能超过100M;

```



# 六.自定义数据类型及关系映射(mapping)概述

## 1.ElasticSearch中支持的类型（了解即可）

```
	前面我们创建的索引以及插入数据，都是由Elasticsearch进行自动判断。

	有些时候我们需要进行明确的字段类型的，否则，自动判断的类型和实际需求是不相符的。

	此处我针对字符串类型做一个简单的说明：（因为上面的案例的确用到了）
        string类型（deprecated，已废弃）:
            在ElasticSearch旧版本中使用较多，从ElasticSearch 5.x开始不再支持string，由text和keyword类型代替。

        text类型:
            当一个字段要被全文搜索的，比如Email内容，产品描述，应该使用text类型。
            设置text类型以后，字段内容会被分析，在生成倒排索引以前，字符串会被分词器分成一个一个词项。
            text类型的字段不用于排序，很少用于聚合。
            换句话说，text类型是可拆分的。

        keyword类型:
            适用于索引结构化的字段，比如email地址，主机名，状态码，标签，IP地址等。
            如果字段需要进行过滤(比如查找已发布博客中status属性为published的文章)，排序，聚合。keyword类型的字段只能通过精确值搜索到。
            换句话说，keyword类型是不可拆分的。

	关于ElasticSearch的详细的数据类型并不是我们运维人员所关心的，因为这些是开发人员去研究的，感兴趣的小伙伴卡自行参考官方文档。

    推荐阅读：
        https://www.elastic.co/guide/en/elasticsearch/reference/7.12/mapping-types.html

```



## 2.数据类型-自定义映射关系案例1-text-keyword

```
推荐阅读:
	https://www.elastic.co/guide/en/elasticsearch/reference/7.12/mapping.html


创建索引:
	curl -X PUT http://elk101.oldboyedu.com:9200/teacher
        {
            "settings": {
                "index": {
                    "number_of_replicas": "1",
                    "number_of_shards": "5"
                }
            }
        }
       
添加索引的映射关系:
	curl -X PUT http://elk101.oldboyedu.com:9200/teacher/_mapping
        {
         "settings": {
                "index": {
                    "number_of_replicas": "2",
                    "number_of_shards": "5"
                }
            },
            "properties":{
                "name":{
                    "type":"text", // 该类型是文本类型，该类型存储的数据是可以被拆分的。
                    "index":true
                },
                "gender":{
                    "type":"keyword",  // 该类型是关键字类型，该类型存储的数据是不可被拆分的
                    "index":true
                },
                "telephone":{
                    "type":"text",
                    "index":false  // 如果字段的"index"为false，则无法使用该字段进行数据查找!
                },
                "address":{
                    "type":"keyword",
                    "index":false
                }
            }
        }

往索引中添加数据:
	curl -X PUT http://elk101.oldboyedu.com:9200/teacher/_create/10001
        {
            "name":"oldboy",
            "gender":"男性的",
            "telephone":"1024",
            "address":"北京沙河"
        }
        
测试各个映射字段是否可以查询数据:
	curl -X GET http://elk101.oldboyedu.com:9200/teacher/_search

	(1)基于"name"字段可以查询到数据:
        {
            "query":{
                "match":{
                    "name":"oldboy"
                }
            }
        }

	(2)基于"gender"字段可以查询到数据:
        {
            "query":{
                "match":{
                    "gender":"男性的"  // 注意，此处必须完全匹配，如果不完全匹配则查询不到数据哟~因为"gender"字段被我们显式定义为"keyword"类型啦~
                }
            }
        }
        
	(3)基于"telephone"字段无法查询到数据：
        {
            "query":{
                "match":{
                    "telephone":1024
                }
            }
        }

	（4）基于"address"字段无法查询到数据:
        {
            "query":{
                "match":{
                    "address":"北京沙河"
                }
            }
        }

```



## 3.数据类型-自定义映射关系案例2-ip

```
创建索引并制定映射关系:
curl -X PUT http://10.0.0.108:9200/oldboyedu_linux77_ip
    {
        "settings": {
            "index": {
                "number_of_replicas": "2",
                "number_of_shards": "5"
            }
        },
        "mappings": {
            "properties": {
                "ip_addr": {
                    "type": "ip"
                }
            }
        }
    }	
    

添加文档:
    {"create":{"_index":"oldboyedu_linux77_ip"}}
    {"ip_addr": "192.168.14.253"}
    {"create":{"_index":"oldboyedu_linux77_ip"}}
    {"ip_addr": "192.168.14.252"}
    {"create":{"_index":"oldboyedu_linux77_ip"}}
    {"ip_addr": "192.168.14.251"}
    {"create":{"_index":"oldboyedu_linux77_ip"}}
    {"ip_addr": "192.168.14.250"}
    {"create":{"_index":"oldboyedu_linux77_ip"}}
    {"ip_addr": "10.0.0.253"}
    {"create":{"_index":"oldboyedu_linux77_ip"}}
    {"ip_addr": "10.0.0.252"}
    {"create":{"_index":"oldboyedu_linux77_ip"}}
    {"ip_addr": "10.0.0.251"}
    {"create":{"_index":"oldboyedu_linux77_ip"}}
    {"ip_addr": "10.0.0.250"}
    
    
基于全文检索的方式查找:
{
    "query":{
        "match":{
            "ip_addr": "192.168.14.253"
        }
    }
}

精确查询:
    {
      "query": {
        "term": {
          "ip_addr": "10.0.0.0/16"   // 注意,此处查询的是一个网段哟~
        }
      }
    }

```





# 七.管理集群常用的API

## 1.查看集群的健康状态信息

```
curl -X GET  http://elk101.oldboyedu.com:9200/_cluster/health?wait_for_status=yellow&timeout=50s&pretty

温馨提示:
	(1)wait_for_status表示等待ES集群达到状态的级别;
	(2)timeout表示指定等待的超时时间;
	(3)pretty表示美观的输出响应体，尤其是在浏览器输入;

以下是对响应结果进行简单的说明:
    cluster_name
        集群的名称。
    status
        集群的运行状况，基于其主要和副本分片的状态。
        常见的状态为：
            green：
                所有分片均已分配。
            yellow：
                所有主分片均已分配，但未分配一个或多个副本分片。如果群集中的节点发生故障，则在修复该节点之前，某些数据可能不可用。
            red：
                未分配一个或多个主分片，因此某些数据不可用。在集群启动期间，这可能会短暂发生，因为已分配了主要分片。
    timed_out：
        如果false响应在timeout参数指定的时间段内返回（30s默认情况下）。
    number_of_nodes：
        集群中的节点数。
    number_of_data_nodes：
        作为专用数据节点的节点数。
    active_primary_shards：
        活动主分区的数量。
    active_shards：
        活动主分区和副本分区的总数。
    relocating_shards：
        正在重定位的分片的数量。
    initializing_shards：
        正在初始化的分片数。
    unassigned_shards：
        未分配的分片数。
    delayed_unassigned_shards：
        其分配因超时设置而延迟的分片数。
    number_of_pending_tasks：
        尚未执行的集群级别更改的数量。
    number_of_in_flight_fetch：
        未完成的访存次数。
    task_max_waiting_in_queue_millis：
        自最早的初始化任务等待执行以来的时间（以毫秒为单位）。
    active_shards_percent_as_number：
        群集中活动碎片的比率，以百分比表示。

```



## 2.获取集群的配置信息（了解即可）

```
查看集群的信息:
	curl -X GET  http://elk101.oldboyedu.com:9200/_cluster/settings?include_defaults

修改集群的信息:
	curl -X PUT http://elk101.oldboyedu.com:9200/_cluster/settings
        {
            "persistent": {
                // "cluster.routing.allocation.enable": "none"  // 不允许主分片和副本分片进行分配
                // "cluster.routing.allocation.enable": "primaries" // 只允许主分片进行分配
                 "cluster.routing.allocation.enable": "all"   // 允许所有类型的分片进行分配.
            }
        }

shard分配策略
	集群分片分配是指将索引的shard分配到其他节点的过程，会在如下情况下触发：
		(1)集群内有节点宕机，需要故障恢复；
		(2)增加副本；
		(3)索引的动态均衡，包括集群内部节点数量调整、删除索引副本、删除索引等情况；

	上述策略开关，可以动态调整，由参数cluster.routing.allocation.enable控制，启用或者禁用特定分片的分配。该参数的可选参数有：
		all(默认值):
			允许为所有类型分片分配分片；
        primaries:
            仅允许分配主分片的分片；
        new_primaries :
            仅允许为新索引的主分片分配分片；
        none:
            任何索引都不允许任何类型的分片；


温馨提示:
	(1)默认情况下，此API调用仅返回已显式定义的设置，包括"persistent"(持久设置)和"transient"(临时设置);
	(2)其中include_defaults表示的是默认设置；

```



## 3.查看集群的统计信息（了解即可）

```
curl -X GET http://elk101.oldboyedu.com:9200/_cluster/stats
curl -X GET http://elk101.oldboyedu.com:9200/_cluster/stats/nodes/<node_filter>


路径参数说明:
https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster.html#cluster-nodes

返回参数说明:
	https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-stats.html#cluster-stats-api-response-body
```



## 4.查看集群shard分配的分配情况（了解即可）

```
curl -X POST  http://elk101.oldboyedu.com:9200/_cluster/allocation/explain

提交的参数如下:
	(1)查看未分配的主分片原因
        {
          "index": "linux-2020-10-3",
          "shard": 0,
          "primary": true
        }

	(2)查看未分配的副本分片原因
        {
          "index": "linux-2020-10-3",
          "shard": 0,
          "primary": false
        }
	
返回的参数说明：
	https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-allocation-explain.html

温馨提示:
	当您试图诊断shard未分配的原因，此API非常有用。
```



## 5.其他操作（了解即可）

```
推荐阅读:
	https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster.html
```





# 八.文档分词器及自定义分词案例（了解即可）

## 1.文档分析

```
	文档分析包含下面的过程:
		(1)将一块文本分成适合于倒排索引的独立的词条;
		(2)将这些词条统一化为标准格式以提高它们的"可搜索性"，或者recall分词器执行上面的工作。分析器实际上是将三个功能封装到了一个package里:
			字符过滤器:
				首先，字符串按顺序通过每个字符过滤器。他们的任务是在分词前整理字符串。一个字符过滤器可以用来去掉HTML，或者将&转化成and。
			分词器:
				其次，字符串被分词器分为单个的词条。一个简单的分词器遇到空格和标点的时候，可能会将文本拆分成词条。
			Token过滤器:
				最后，词条按照顺序通过每个token过滤器。这个过程可能会改变词条(例如，小写化，Quick)，删除词条(例如，像a,and,the等无用词)，或者增加词条(例如，像jump和leap这种同义词)。
```



## 2.内置分析器


	内置分析器:
		ES还附带了可以直接使用的预包装的分析器。接下来我们会列出最重要的分析器。为了证明它们的差异，我们看看每个分析器会从下面的字符串得到哪些词条。
		"Set the shape to semi-transparent by calling set_trans(5)"
	
	标准分析器:
		标准分析器是ES默认使用的分词器。它是分析各种语言文本最常用的选择。它根据Unicode联盟定义的单词边界划分文本。删除部分标点。最后将词条小写。所以它会分析出以下词条:
		set,the,shape,to,semi,transparent,by,calling,set_trans,5
		
	简单分析器:
		简单分析器在任何不是字母的地方分隔文本，将词条小写。所以它会产生以下词条:
		set,the,shape,to,semi,transparent,by,calling,set,trans
		
	空格分析器:
		空格分析器在空格的地方划分文本，所以它会产生以下词条:
		Set,the,shape,to,semi-transparent,by,calling,set_trans(5)
		
	语言分析器:
		特定语言分析器可用于很多语言。它们可以考虑指定语言的特点。例如，英语分析器还附带了无用词(常用单词，例如and或者the，它们对相关性没有多少影响)，它们会被删除。由于理解英语语法的规则，这个分词器可以提取英语单词的词干。所以英语分词器会产生下面的词条:
		set,shape,semi,transpar,call,set_tran,5
		注意看"transparent","calling"和"set_trans"已经变成词根格式。




## 3.分析器使用场景

```
	当我们索引一个文档，它的全文域被分析成词条以用来创建倒排索引。但是，当我们在全文域搜索的时候，我们需要将字符串通过相同的分析过程，以保证我们搜索的词条格式与索引中的词条格式一致。
	
```



## 4.测试分析器-标准分析器("standard")

```
有些时候很难理解分词的过程和实际被存储到索引的词条，特别是你刚接触ES。为了理解发生了上面，你可以使用analyze API来看文本时如何被分析的。

在消息体里，指定分析器和要分析的文本:
curl -X GET/POST http://elk101.oldboyedu.com:9200/_analyze
    {
        "analyzer": "standard",
        "text":"My name is Jason Yin and I'm 18 years old!"
    }
```



## 5.ES内置的中文分词并不友好

```
在消息体里，指定分析器和要分析的文本:
curl -X GET/POST http://elk101.oldboyedu.com:9200/_analyze
    {
        "text":"我爱北京天安门"
    }
```



## 6.中文分词器概述

```
	中文分词的难点在于，在汉语中没有明显的词汇分界点，如在英语中，空格可以作为分隔符，如果分隔符不正确就会造成歧义。常用中文分词器有IK，jieba，THULAC等，推荐使用IK分词器。

	"IK Analyzer"是一个开源的，基于Java语言开发的轻量级的中文分词工具包。从2006年12月推出1.0版本开始，IK Analyzer已经推出了3个大版本。最初，它是以开源项目Luence为应用主体的，结合词典分词和文法分析算法的中文分词组件。

	新版本的IK Analyzer 3.0则发展为面向Java的公用分词组件，独立于Lucene项目，同时提供对Lucene的默认优化实现。采用了特有的"正向迭代最新力度切分算法"，具有"80万字/秒"的高速处理能力。
	
	采用了多子处理器分析模式，支持: 英文字母(IP地址，Email，URL)，数字(日期，常用中文数量词，罗马数字，科学计数法)，中文词汇()姓名，地名处理等分词处理。优化的词典存储，更小的内存占用。

	IK分词器Elasticsearch插件地址:
		https://github.com/medcl/elasticsearch-analysis-ik
```



## 7.安装IK分词器插件

```
解压分词器到集群节点的插件目录即可:
[root@elk103.oldboyedu.com ~]# mkdir -pv /oldboy/softwares/elasticsearch/plugins/ikmkdir: 已创建目录 "/oldboy/softwares/elasticsearch/plugins/ik"
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# ll /oldboy/softwares/elasticsearch/plugins/ik/
总用量 0
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# ll
总用量 4400
-rw-r--r-- 1 root root 4504535 4月  30 21:14 elasticsearch-analysis-ik-7.12.1.zip
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# unzip elasticsearch-analysis-ik-7.12.1.zip -d /oldboy/softwares/elasticsearch/plugins/ik/
Archive:  elasticsearch-analysis-ik-7.12.1.zip
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/elasticsearch-analysis-ik-7.12.1.jar  
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/httpclient-4.5.2.jar  
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/httpcore-4.4.4.jar  
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/commons-logging-1.2.jar  
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/commons-codec-1.9.jar  
   creating: /oldboy/softwares/elasticsearch/plugins/ik/config/
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/config/extra_stopword.dic  
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/config/extra_single_word.dic  
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/config/main.dic  
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/config/surname.dic  
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/config/quantifier.dic  
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/config/preposition.dic  
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/config/extra_single_word_full.dic  
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/config/IKAnalyzer.cfg.xml  
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/config/suffix.dic  
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/config/stopword.dic  
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/config/extra_single_word_low_freq.dic  
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/config/extra_main.dic  
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/plugin-descriptor.properties  
  inflating: /oldboy/softwares/elasticsearch/plugins/ik/plugin-security.policy  
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# ll /oldboy/softwares/elasticsearch/plugins/ik/
总用量 1428
-rw-r--r-- 1 root root 263965 4月  25 16:22 commons-codec-1.9.jar
-rw-r--r-- 1 root root  61829 4月  25 16:22 commons-logging-1.2.jar
drwxr-xr-x 2 root root    299 4月  25 16:16 config
-rw-r--r-- 1 root root  54626 4月  30 21:14 elasticsearch-analysis-ik-7.12.1.jar
-rw-r--r-- 1 root root 736658 4月  25 16:22 httpclient-4.5.2.jar
-rw-r--r-- 1 root root 326724 4月  25 16:22 httpcore-4.4.4.jar
-rw-r--r-- 1 root root   1807 4月  30 21:14 plugin-descriptor.properties
-rw-r--r-- 1 root root    125 4月  30 21:14 plugin-security.policy
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# 


修改权限:
[root@elk103.oldboyedu.com ~]# ll /oldboy/softwares/elasticsearch/plugins/
总用量 0
drwxr-xr-x 3 root root 244 5月  25 17:32 ik
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# ll /oldboy/softwares/elasticsearch/plugins/ik/
总用量 1428
-rw-r--r-- 1 root root 263965 4月  25 16:22 commons-codec-1.9.jar
-rw-r--r-- 1 root root  61829 4月  25 16:22 commons-logging-1.2.jar
drwxr-xr-x 2 root root    299 4月  25 16:16 config
-rw-r--r-- 1 root root  54626 4月  30 21:14 elasticsearch-analysis-ik-7.12.1.jar
-rw-r--r-- 1 root root 736658 4月  25 16:22 httpclient-4.5.2.jar
-rw-r--r-- 1 root root 326724 4月  25 16:22 httpcore-4.4.4.jar
-rw-r--r-- 1 root root   1807 4月  30 21:14 plugin-descriptor.properties
-rw-r--r-- 1 root root    125 4月  30 21:14 plugin-security.policy
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# chown -R oldboy:oldboy /oldboy/softwares/elasticsearch/plugins/ik/
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# ll /oldboy/softwares/elasticsearch/plugins/
总用量 0
drwxr-xr-x 3 oldboy oldboy 244 5月  25 17:32 ik
[root@elk103.oldboyedu.com ~]# 
[root@elk103.oldboyedu.com ~]# ll /oldboy/softwares/elasticsearch/plugins/ik/
总用量 1428
-rw-r--r-- 1 oldboy oldboy 263965 4月  25 16:22 commons-codec-1.9.jar
-rw-r--r-- 1 oldboy oldboy  61829 4月  25 16:22 commons-logging-1.2.jar
drwxr-xr-x 2 oldboy oldboy    299 4月  25 16:16 config
-rw-r--r-- 1 oldboy oldboy  54626 4月  30 21:14 elasticsearch-analysis-ik-7.12.1.jar
-rw-r--r-- 1 oldboy oldboy 736658 4月  25 16:22 httpclient-4.5.2.jar
-rw-r--r-- 1 oldboy oldboy 326724 4月  25 16:22 httpcore-4.4.4.jar
-rw-r--r-- 1 oldboy oldboy   1807 4月  30 21:14 plugin-descriptor.properties
-rw-r--r-- 1 oldboy oldboy    125 4月  30 21:14 plugin-security.policy
[root@elk103.oldboyedu.com ~]# 


# 重启服务使得配置生效:
[root@elk103.oldboyedu.com ~]# su -l oldboy
上一次登录：一 5月 24 10:59:06 CST 2021pts/0 上
[oldboy@elk103.oldboyedu.com ~]$ 
[oldboy@elk103.oldboyedu.com ~]$ jps
1571 Elasticsearch
2613 Jps
[oldboy@elk103.oldboyedu.com ~]$ 
[oldboy@elk103.oldboyedu.com ~]$ kill 1571
[oldboy@elk103.oldboyedu.com ~]$ 
[oldboy@elk103.oldboyedu.com ~]$ jps
2634 Jps
[oldboy@elk103.oldboyedu.com ~]$ 
[oldboy@elk103.oldboyedu.com ~]$ elasticsearch -d
[oldboy@elk103.oldboyedu.com ~]$ 
[oldboy@elk103.oldboyedu.com ~]$ jps
2770 Elasticsearch
2790 Jps
[oldboy@elk103.oldboyedu.com ~]$ 


```



## 8.测试IK分词器

```
curl -X GET/POST http://elk103.oldboyedu.com:9200/_analyze	
    {
        "analyzer": "ik_max_word",
        "text":"我爱北京天安门"
    }
    
curl -X GET/POST http://elk103.oldboyedu.com:9200/_analyze
    {
        "analyzer": "ik_smart",  // 会将文本做最粗粒度的拆分。
        "text":"我爱北京天安门"
    }


IK分词器说明:
	"ik_max_word":
		会将文本做最细粒度的拆分。
	"ik_smart":
		会将文本做最粗粒度的拆分。
		

温馨提示：
	由于我将IK分词器只安装在了elk103节点上，因此我这里指定的ES节点就是按照的结点，生产环境中建议大家同步到所有节点。

```



## 9.自定义词汇

```
自定义词汇，文件名称可自行定义:
[oldboy@elk103.oldboyedu.com ~]$ vim /oldboy/softwares/elasticsearch/plugins/ik/config/oldboy_custom.dic
[oldboy@elk103.oldboyedu.com ~]$ 
[oldboy@elk103.oldboyedu.com ~]$ cat /oldboy/softwares/elasticsearch/plugins/ik/config/oldboy_custom.dic
艾欧里亚
德玛西亚
[oldboy@elk103.oldboyedu.com ~]$ 


将上面自定义词汇的文件名称写入IK分词器的配置文件中:
[oldboy@elk103.oldboyedu.com ~]$ cat /oldboy/softwares/elasticsearch/plugins/ik/config/IKAnalyzer.cfg.xml 
﻿<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
	<comment>IK Analyzer 扩展配置</comment>
	<!--用户可以在这里配置自己的扩展字典 -->
	<entry key="ext_dict"></entry>
	 <!--用户可以在这里配置自己的扩展停止词字典-->
	<entry key="ext_stopwords"></entry>
	<!--用户可以在这里配置远程扩展字典 -->
	<!-- <entry key="remote_ext_dict">words_location</entry> -->
	<!--用户可以在这里配置远程扩展停止词字典-->
	<!-- <entry key="remote_ext_stopwords">words_location</entry> -->
</properties>
[oldboy@elk103.oldboyedu.com ~]$ 
[oldboy@elk103.oldboyedu.com ~]$ vim /oldboy/softwares/elasticsearch/plugins/ik/config/IKAnalyzer.cfg.xml 
[oldboy@elk103.oldboyedu.com ~]$ 
[oldboy@elk103.oldboyedu.com ~]$ cat /oldboy/softwares/elasticsearch/plugins/ik/config/IKAnalyzer.cfg.xml 
﻿<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
	<comment>IK Analyzer 扩展配置</comment>
	<!--用户可以在这里配置自己的扩展字典 -->
	<entry key="ext_dict">oldboy_custom.dic</entry>
	 <!--用户可以在这里配置自己的扩展停止词字典-->
	<entry key="ext_stopwords"></entry>
	<!--用户可以在这里配置远程扩展字典 -->
	<!-- <entry key="remote_ext_dict">words_location</entry> -->
	<!--用户可以在这里配置远程扩展停止词字典-->
	<!-- <entry key="remote_ext_stopwords">words_location</entry> -->
</properties>
[oldboy@elk103.oldboyedu.com ~]$ 


重启ES服务使得配置生效:
[oldboy@elk103.oldboyedu.com ~]$ jps
2770 Elasticsearch
2842 Jps
[oldboy@elk103.oldboyedu.com ~]$ 
[oldboy@elk103.oldboyedu.com ~]$ kill 2770
[oldboy@elk103.oldboyedu.com ~]$ 
[oldboy@elk103.oldboyedu.com ~]$ jps
2860 Jps
[oldboy@elk103.oldboyedu.com ~]$ 
[oldboy@elk103.oldboyedu.com ~]$ elasticsearch -d
[oldboy@elk103.oldboyedu.com ~]$ 
[oldboy@elk103.oldboyedu.com ~]$ jps
2996 Elasticsearch
3016 Jps
[oldboy@elk103.oldboyedu.com ~]$ 


温馨提示:
	(1)建议将IK分词器同步到集群的所有节点;
	(2)修改"IKAnalyzer.cfg.xml"的配置文件时，我只修改了key="ext_dict"这一行配置项目，如下所示:
	"<entry key="ext_dict">oldboy_custom.dic</entry>"

```



## 10.测试自定义词汇是否生效

```
curl -X GET/POST http://elk103.oldboyedu.com:9200/_analyze
    {
        "analyzer":"ik_smart",
        "text": "嗨，兄弟，你LOL哪个区的，我艾欧里亚和德玛西亚都有号"
    }
```





## 11.为某个索引自定义分析器

```
	虽然ElsticSearch带有一些现成的分词器，然而在分析器上ES真正的强大之处在于，你可以通过在一个合适你的特定数据的设置之中组合字符串过滤器，分词器，词汇单元过滤器来创建自定义的分词器。
	在分析与分析器我们说过，一个分析器就是在一个package里面组合了三种函数的包装器，这三种函数按照顺序被执行：
	字符过滤器:
		用来整理一个尚未被分词的字符串。
		例如，如果我们的文本时HTML格式的，它会包含像"<p>"或者"<div>"这样的HTML标签，这些标签时我们不想索引的。我们可以使用HTML清除字符过滤器来移除所有的HTML标签，并且像把"&Aacute;
"转换为相对应的Unicode字符A这样，转换HTML实体。一个分析器可能有0个或者多个字符过滤器。
	分词器:
		一个分词器必须有一个唯一的分词器。分词器把字符串分解成单个词条或者词汇单元。标准分析器里使用的标准分词器把一个字符串根据单词边界分解成单个词条，并且移除大部分的标点符号，然而还有其它不同行为的分词器存在。
		例如，关键词，分词器完整地输出，接收到的同样的字符串，并不做任何分词。空格分词器只根据空格分割文本。正则分词器根据匹配正则表达式来分割文本。
	词单元过滤器：
		经过分词，作为结果的词单元流会按照指定的顺序通过指定的词单元过滤器。
		词单元过滤器可以修改修改，添加或者移除词单元。我们已经提到过lowercase和stop词过滤器，但是在ElasticSearch里面还有很多可供选择的词单元过滤器。词干过滤器把单词遏制为词干。
		ascii_folding过滤器移除变音符。
		ngram和edge_ngram词单元过滤器可以产生适合与部分匹配或者自动补全的词单元。
		

(1)创建索引时自定义分词器
	curl -X PUT http://elk103.oldboyedu.com:9200/oldboyedu_linux77
        {
            "settings":{
                "analysis":{
                    "char_filter":{
                        "&_to_and":{
                            "type": "mapping",
                            "mappings": ["& => and"]
                        }
                    },
                    "filter":{
                        "my_stopwords":{
                            "type":"stop",
                            "stopwords":["the","a","if","are","to","be","kind"]
                        }
                    },
                    "analyzer":{
                        "my_analyzer":{
                            "type":"custom",
                            "char_filter":["html_strip","&_to_and"],
                            "tokenizer": "standard",
                            "filter":["lowercase","my_stopwords"]
                        }
                    }
                }
            }
        }
        
        
analysis自定义分词器核心参数说明如下:
    char_filter:
    	目的是将"&"转换为"and"字符。
    filter:
    	过滤词汇，此处我使用stopwords来过滤掉一些停用词，即"the","a","if","are","to","be","kind"。
    analyzer:
    	自定义分词器。
    type:
    	指定分词器的类型，很明显，我指定的是自定义("custom")类型。
    char_filter:
    	指定字符过滤器，可以指定多个，用逗号分隔。
    tokenizer:
		指定为标准的("standard")分词器。
    filter:
    	指定过滤器。
    	

(2)验证置自定义分词器是否生效
	curl -X GET/POST http://elk103.oldboyedu.com:9200/oldboyedu_linux77/_analyze
    {
        "text":"If you are a person, please be kind to small animals.",
        "analyzer":"my_analyzer"
    }
```







# 九.索引模板(必讲)

## 1.索引模板的作用

```
	索引模板是创建索引的一种方式。将数据写入指定索引时，如果该索引不存在，则根据索引名称能匹配相应索引模板话，会根据模板的配置建立索引。
	
	推荐阅读:
		https://www.elastic.co/guide/en/elasticsearch/reference/master/index-templates.html
```



## 2.查看内置的索引板

```
	查看所有的索引模板信息:
		curl -X GET http://elk101.oldboyedu.com:9200/_template?pretty
		
	查看某个索引模板信息:
		curl -X GET http://elk101.oldboyedu.com:9200/_template/oldboyedu?pretty
```



## 3.创建索引模板

```
curl -X PUT http://elk101.oldboyedu.com:9200/_template/oldboyedu
    {
        "index_patterns": [
            "oldboyedu*"
        ],
        "settings": {
            "index": {
                "number_of_shards": 5,
                "number_of_replicas": 0,
                "refresh_interval": "30s"
            }
        },
        "mappings": {
            "properties": {
                "@timestamp": {
                    "type": "date"
                },
                "name": {
                    "type": "keyword"
                },
                "address": {
                    "type": "text"
                }
            }
        }
    }
```



## 4.删除索引模板

```
curl -X DELETE http://elk101.oldboyedu.com:9200/_template/oldboyedu
```



## 5.修改索引模板(注意修改是覆盖修改哟~)

```
curl -X PUT http://elk101.oldboyedu.com:9200/_template/oldboyedu
    {
        "index_patterns": [
            "oldboyedu*"
        ],
        "settings": {
            "index": {
                "number_of_shards": 10,
                "number_of_replicas": 0,
                "refresh_interval": "30s"
            }
        },
        "mappings": {
            "properties": {
                "id": {
                    "type": "keyword"
                },
                "name": {
                    "type": "keyword"
                },
                "gender": {
                    "type": "keyword"
                }
            }
        }
    }
```



## 6.创建索引进行测试

```
不指定副本和分片创建索引：
	curl -X PUT  http://elk101.oldboyedu.com:9200/oldboyedu
	
指定副本和分片创建索引:
	curl -X PUT  http://elk101.oldboyedu.com:9200/oldboyedu
        {
            "settings":{
                "index":{
                    "number_of_replicas":1,
                    "number_of_shards":3
                }
            }
        }
        
```



# 十.ES的Restful API使用过程中可能存在的问题

## 1.Text fields are not optimised for operations that require per-document field data like aggregations and sorting, so these operations are disabled by default. Please use a keyword field instead. Alternatively, set fielddata=true on [brand] in order to load field data by uninverting the inverted index. Note that this can use significant memory.

```
故障原因：
	基于brand字段进行分组查询，但很遗憾!

解决方案：
	方案一：（不推荐，因为这可能会导致消耗更多的内存空间）
		curl -X PUT http://elk101.oldboyedu.com:9200/shopping/_mapping
            {
              "properties": {
                "brand": {  // 修改我们指定的字段,将"fielddata"修改为true。
                  "type": "text",
                  "fielddata": true
                }
              }
            }
            
	方案二：(推荐!)
    	curl -X POST/GET http://elk101.oldboyedu.com:9200/shopping/_search
            {
                "aggs":{  // 聚合操作
                    "brand_group":{  // 该名称可以自定义，我习惯性基于相关字段起名称。
                        "terms":{  // 分组
                            "field":"brand.keyword"  // 分组字段
                        }
                    }
                }
            }	
```





## 2.