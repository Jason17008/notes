在Kubernetes中运行的应用应具备心跳接口，Kubernetes会定期使用GET方法请求服务的这个接口以确保服务始终是准备好且可用的状态；health接口应放到代码初始化的最后阶段，这样我们的Ready探针可以在应用的启动阶段循环请求/health这个接口，根据返回的状态码（200）来判断应用是否准备好，没有准备好的应用，流量不会被放行进来；另外一个活性探针是在Ready探针真正就绪后开始探测，超时范围内失败次数达到预设值后，该服务实例(Pod)会被强制重启。





## 示例代码

```plain
package main

import (
   "github.com/gin-gonic/gin"
   "net/http"
)

func HealthCheck(c *gin.Context) {
   // 比较简陋，你可以实现自己代码的心跳检测逻辑，尝试返回不同的状态码
   // 最理想的状态是将这部分代码放到业务逻辑的初始化结束部分
   c.JSON(http.StatusOK, gin.H{
      // 这些返回内容无关紧要，服务的就绪与否取决于返回的状态码
      // 正常范围：2xx - 3xx
      // 异常范围：404 - 5xx
      "status": http.StatusOK,
      "msg": "Up",
   })
}

func main() {
   r := gin.New()

   // 路由，按照惯例，心跳接口统一使用这个path
   r.GET("/health", HealthCheck)

   r.Run(":8080")
}
```