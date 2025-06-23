安全秒级监控



- Falco是什么:一个容器和Kubernetes的运行时安全监控工具
- Falco的主要功能:实时检测异常活动和配置问题,输出警报



其他的操作  需要网络好



```toml
# helm3 install(可选项)
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
```

离线安装

```toml
# 创建namespace
kubectl create ns falco

# 下载好离线 helm chart包
wget https://github.com/falcosecurity/charts/releases/download/falco-3.8.7/falco-3.8.7.tgz

# 一键式helm命令安装Falco
# 正式安装需要去掉  --dry-run --debug
helm -n falco install falco ./falco-3.8.7.tgz --set falco.jsonOutput=true --set falco.json_output=true --set falco.http_output.enabled=true --set falco.http_output.url=http://falco-falcosidekick:2801/ --set falcosidekick.enabled=true --set falcoctl.artifact.install.enabled=false --set falcoctl.artifact.follow.enabled=false --dry-run --debug
##安装命名空间为falco     安装的包为 falco-3.8.7.tgz  #开启输出日志为json    #需要http发送出来  ##falco-falcosidekick 指定信息中心 端口 以及开启                                                                                                  ##紧张更新安全规则  因为网络拉取问题 失败会报错 默认的安全规则够用                                        
helm -n falco install falco ./falco-3.8.7.tgz --set falco.jsonOutput=true --set falco.json_output=true --set falco.http_output.enabled=true --set falco.http_output.url=http://falco-falcosidekick:2801/ --set falcosidekick.enabled=true --set falcoctl.artifact.install.enabled=false --set falcoctl.artifact.follow.enabled=false

安装的过程中镜像难拉 正式安装服务的时候 镜像1g 拉取过慢 可以下载导入尝试 
docker.io/falcosecurity/falcosidekick:2.28.0
想办法 这个拉到每一个节点上 


# 用nc启动一个webhook模拟服务端(可选项)
nc -l 6666

# 配置 falcosidekick 报警输出的 webhook 地址:
kubectl -n falco edit secrets falco-falcosidekick
  #在下面配置(内容是base64编码 http://172.16.15.110:6666)
  WEBHOOK_ADDRESS: aHR0cDovLzEwLjAuMS4yMDE6NjY2Ng==

##配置完成之后删除下falco-falcosidekisck 这个pod
kubectl -n falco delete pod falco-falcosidekick

然后开启logs -f  falco-falcosidekick

 随便 exec -it 进去一个pod  

 这个时候查看 nc -l 6666 那个终端
 可以查看接收到的信息 

##博哥的视频里面取到数据 jq取出来  gin开发 然后实行转发  

# 卸载
helm -n falco uninstall falco

##如果发送没找到发送的消息 可以开启debug模式  
helm -n falco install falco ./falco-3.8.7.tgz --set falco.jsonOutput=true --set falco.json_output=true --set falco.http_output.enabled=true --set falco.http_output.url=http://falco-falcosidekick:2801/ --set falcosidekick.enabled=true --set falcoctl.artifact.install.enabled=false --set falcoctl.artifact.follow.enabled=false
```



```toml
kubectl -n falco edit secrets falco-falcosidekick


echo -n "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=0c4db933-cd88-4817-914a-bdb98be9eaf0" |base64
aHR0cHM6Ly9xeWFwaS53ZWl4aW4ucXEuY29tL2NnaS1iaW4vd2ViaG9vay9zZW5kP2tleT0wYzRk
YjkzMy1jZDg4LTQ4MTctOTE0YS1iZGI5OGJlOWVhZjA=

WEBHOOK_ADDRESS: "不换行"
```



博哥是转发到自己的告警端口里面了

我要做到的是转发给自己的webhook里面 





不行的话 就得学博哥的视频里面转发  采集 然后转发到webhook

```toml
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// 企业微信Markdown消息结构体
type WeComMarkdownMessage struct {
	MsgType  string `json:"msgtype"`
	Markdown struct {
		Content string `json:"content"`
	} `json:"markdown"`
}

// 配置信息
type Config struct {
	Port        string `json:"port"`         // 监听端口
	WebhookURL  string `json:"webhook_url"`  // 企业微信Webhook地址
	MessageTemplate string `json:"message_template"` // 消息模板
}

func main() {
	// 初始化配置
	config := Config{
		Port:        ":6666",
		WebhookURL:  "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY",
		MessageTemplate: `# 收到新消息\n> **来源**: faclo工具\n> **时间**: %s\n> **内容**: \n%s`,
	}

	// 创建Gin引擎
	r := gin.Default()

	// 设置路由，接收POST请求
	r.POST("/", func(c *gin.Context) {
		// 读取请求体
		body, err := io.ReadAll(c.Request.Body)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "读取请求体失败"})
			return
		}

		// 格式化消息内容
		message := fmt.Sprintf(config.MessageTemplate, time.Now().Format("2006-01-02 15:04:05"), string(body))

		// 构建企业微信消息
		wecomMsg := WeComMarkdownMessage{
			MsgType: "markdown",
		}
		wecomMsg.Markdown.Content = message

		// 发送到企业微信
		if err := sendToWeCom(config.WebhookURL, wecomMsg); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "发送到企业微信失败"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"status": "消息已转发"})
	})

	// 启动服务
	fmt.Printf("服务已启动，监听端口 %s\n", config.Port)
	if err := r.Run(config.Port); err != nil {
		panic(fmt.Sprintf("启动服务失败: %v", err))
	}
}

// 发送消息到企业微信
func sendToWeCom(webhookURL string, msg WeComMarkdownMessage) error {
	// 序列化消息
	jsonData, err := json.Marshal(msg)
	if err != nil {
		return fmt.Errorf("序列化消息失败: %v", err)
	}

	// 发送HTTP POST请求
	resp, err := http.Post(webhookURL, "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("HTTP请求失败: %v", err)
	}
	defer resp.Body.Close()

	// 检查响应状态
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("企业微信返回错误状态码: %d", resp.StatusCode)
	}

	return nil
}
```