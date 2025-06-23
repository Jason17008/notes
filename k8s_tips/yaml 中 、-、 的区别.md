### 对比表格

| **符号** | **换行符处理**   | **末尾换行符** | **典型用途**             |
| -------- | ---------------- | -------------- | ------------------------ |
| `        | `                | 保留所有换行符 | 保留                     |
| `        | -`               | 保留换行符     | 删除                     |
| `>`      | 换行符替换为空格 | 删除           | 长段落文本（如文档描述） |







### 使用场景示例

#### 场景 1：Kubernetes 中的脚本（需保留换行）

```plain
yaml

复制
apiVersion: v1
kind: ConfigMap
metadata:
  name: script-config
data:
  script.sh: |
    #!/bin/bash
    echo "Hello World"
    echo "This is a script."
```

#### 场景 2：日志消息（无需末尾空行）

```plain
yaml

复制
error_message: |-
  Error 404: Not Found.
  The requested resource was not available.
```

#### 场景 3：长描述文本（折叠为段落）

```plain
yaml

复制
description: >
  This is a long description that spans
  multiple lines but should be read as
  a single paragraph.

  Another paragraph starts here.
```