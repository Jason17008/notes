golang项目 配置中心apollo



```
统一使用包：

github.com/shima-park/agollo


代码示例：：
package config

import (
   "github.com/shima-park/agollo"
)

var (
   NewApollo agollo.Agollo
   valStauct *valueStauct
)


func init() {
   var err error
   //获取环境变量
   cluster_env := os.Getenv("PROFILES")
   //获取环境变量 根据环境变量获取 对应apolloURL
   apolloUrl := configUrl(cluster_env)
   //链接apollo
   NewApollo, err = agollo.New(apolloUrl, "bi-dcss", agollo.AutoFetchOnCacheMiss())
   if err != nil {
      panic(err)
   }
   //链接当前apollo下对应的 namespace
   NewApollo.GetNameSpace("application")
   //获取对应key里面的信息
   value := NewApollo.Get("key")

   //获取 json 格式的配置信息
   valueJson := NewApollo.GetNameSpace("key.json")
   //判断配置信息里面是否为空
   if len(appKeyConfig) <= 0{
      panic("获取库表配置为空")
   }
   //转换成结构体数据
   err = valueTurnJson(valueJson["content"].(string))
   if err != nil {
      panic(err)
   }
   //开启动态更新配置
   errorCh := NewApollo.Start()
   watchCh := NewApollo.Watch()
   go func() {
      for{
         select{
         case err := <- errorCh:
            // handle error
            fmt.Println("配置更新失败",err)
         case resp := <-watchCh:
            if resp.Error != nil {
               log.Println("apollo修改失败")
               continue
            }
            //根据namespace 更新对应的配置
            switch resp.Namespace {
            case "application":
               
               //resp.Changes[0].Key  //跟新的key
               //resp.Changes[0].Value.(string) //更新的value
            case "key.json":
               //resp.Changes[0].Value.(string) //json 跟新的全部数据
            }
            if err != nil {
               fmt.Println("更新数据时",err.Error())
            }
         }
      }
   }()
}

func configUrl(cluster_env string) string {
   url := "https://cfg-dev.aixxx.com"
   switch {
   case cluster_env == "dev":
      url = "https://cfg-dev.aixxx.com"
   case cluster_env == "test":
      url = "https://cfg-test.aixxx.com"
   }
   return url
}

func valueTurnJson(jsonStr string) error {
   err := json.Unmarshal([]byte(jsonStr), &valStauct) //解析json格式数据
   return err
}

```