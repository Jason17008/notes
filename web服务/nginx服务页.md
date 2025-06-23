详情页配置

```
  server {
        listen       80;
        server_name  www.zedongaaa.com;
        location / {
	    root /opt/iso ; #指定访问目录
            autoindex on;             #开启索引功能
            autoindex_exact_size off; # 关闭计算文件确切大小（单位bytes），只显示大概大小（单位kb、mb、gb）
            autoindex_localtime on;   # 显示本机时间而非 GMT 时间
            charset utf-8; # 避免中文乱码
        }
	}
```

