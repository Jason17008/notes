https://blog.csdn.net/weixin_46887489/article/details/134676450?spm=1001.2014.3001.5502





附：
VPA https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler

KEDA基于自定义api接口伸缩
https://keda.sh/docs/2.12/scalers/metrics-api/

KEDA基于Prometheus指标伸缩

https://keda.sh/docs/2.12/scalers/prometheus/





### **一、基于自定义 API 接口的伸缩（链接1）**

#### **原理**

1. **自定义指标提供者**
   KEDA 通过用户提供的自定义 API 接口获取指标数据。该 API 需要返回特定格式的指标值（如 JSON 或数值），例如当前队列长度、任务积压量等。
2. **指标适配器**
   KEDA 内置的 `Metrics Server` 会周期性地调用自定义 API 接口，将获取的指标转换为 Kubernetes 标准的 `External Metrics`，供 Horizontal Pod Autoscaler (HPA) 使用。
3. **触发伸缩**
   用户在 KEDA 的 `ScaledObject` 或 `ScaledJob` 中定义触发条件（如指标阈值）。当指标超过阈值时，KEDA 自动调整 Deployment 或 Job 的副本数。

#### **实现效果**

- **动态伸缩**：根据业务逻辑的实时指标（如任务积压、请求队列长度）自动扩容/缩容。
- **从零扩展（Scale to Zero）**：当指标为零时，副本数可缩容到零，节省资源。
- **灵活集成**：适用于任何可通过 API 提供指标的自定义系统（如数据库、消息队列、内部监控系统）。



### **二、基于 Prometheus 指标的伸缩（链接2）**

#### **原理**

1. **Prometheus 查询**
   KEDA 直接查询 Prometheus 服务（通过 PromQL），获取用户定义的指标（如 HTTP 请求速率、CPU 使用率、自定义业务指标）。
2. **指标标准化**
   KEDA 将 Prometheus 返回的指标转换为 Kubernetes 的 `External Metrics`，并传递给 HPA。
3. **条件触发**
   用户在 `ScaledObject` 中配置 Prometheus 查询语句和阈值。例如：
   - 当 HTTP 请求速率超过 100 QPS 时扩容。
   - 当自定义业务指标（如订单处理延迟）超过阈值时触发扩容。

#### **实现效果**

- **无缝集成监控系统**：直接利用 Prometheus 生态的丰富指标，无需额外开发。
- **高精度弹性**：基于实时监控数据（如请求延迟、错误率）实现秒级响应。
- **复杂条件支持**：通过 PromQL 支持多维度、聚合指标的复杂伸缩策略（如按分位数或滑动窗口计算指标）。

