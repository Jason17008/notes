server {

        listen       443 ssl;
        # 域名
        server_name  travel-test.aixxxx.com;
        # 站点字符集设定
        charset uft-8;
        # 证书路径
        ssl_certificate      cert/__aixxxx_com.crt;
        # 私钥路径
        ssl_certificate_key  cert/__aixxxx_com.key;
        # SSL会话缓存时间
        ssl_session_cache shared:SSL:1m;
        # SSL会话超时时间
        ssl_session_timeout  10m;
        # SSL握手协议版本限定
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        # SSL加密算法列表
        ssl_ciphers ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS;
        ssl_prefer_server_ciphers on;
    
        #limit_req zone=lhang burst=8 nodelay;
        #access_log  /var/log/nginx/log/host.access.log  main;
    
        # 匹配根
        location /
        {
                # 添加防止页面嵌入的头
                add_header X-Frame-Options SAMEORIGIN;
                # proxy_pass   https://xx.xx.xx.xx:10443/;
                # 代理到哪里，这里也可以配置为upstream名称
                proxy_pass   https://xx.xx.xx.xx:22443/;
                # nginx控制器类L4 LB
                #proxy_pass   https://xx.xx.xx.xx:24443/;
                proxy_redirect off;
                proxy_intercept_errors on;
                proxy_next_upstream error timeout http_500 http_502 http_503 http_504 http_404;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header REMOTE-HOST $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
               # 连接超时时间设定
               # proxy_connect_timeout 30;
               # 发送超时设定
               # proxy_send_timeout 30;
               # 接收超时设定
               # proxy_read_timeout 60;
               # 代理服务器缓冲区大小
               # proxy_buffer_size 256k;
               # proxy_buffers 4 256k;
               # proxy_busy_buffers_size 256k;
               # proxy_temp_file_write_size 256k;
               # proxy_max_temp_file_size 128m;
        }
}



# [Lyer4反向代理]

通常情况下，我们更多的使用Nginx做L7代理(HTTP)，但是在某些情况下，我们也可以使用它的stream模块来做L4代理，主要区别在于：

L7反向代理：

     80&443端口下，多域名复用端口，可根据server_name和location的配置来将流量代理到不同的后端

L4反向代理：

     在L4代理的情况下，一个监听端口只能给一个后端用，不能共用；类似于端口到端口的NAT转发，L4也可以用iptablets或ipvs转发规则实现。



对于L7的配置，通常在nginx.conf中的http{}作用域中包含，一贯做法是在nginx.conf中使用include关键字包含其他配置，此法可以使得配置文件层次分明、美观。

对于L4的配置，需要写在http{}的外面，需要写在stream{}作用域



下面是一个典型的L4反向代理配置，在nginx.conf中，花括号限定配置作用域，配置项均已分号结尾，字符串可以使用单引号和双引号括起；变量可以使用$符号开头



#进程启动所使用的操作系统账户

user nginx;

#工作进程数，auto为根据CPU核心数创建工作进程，你也可以自己根据情况调整
worker_processes auto;

#错误日志输出的位置和错误日志的输出级别

error_log /var/log/nginx/error.log warn;

#进程PID文件的存放位置和名称，可以理解为进程句柄的概念，通过它可以找到进程ID，从而可向进程发送一些信号
pid /var/run/nginx.pid;

#事件域
events {

      #工作进程连接数设定，服务器最大连接数计算方法：worker_processes * worker_connections = max_connections
      worker_connections 1024;
}

#流---L4反向代理配置写在该处

stream {

    #新建一个server
    server {
    
        #监听443端口
        listen 443;
    
        #将443端口流量转发到本机回环地址的5601端口
        proxy_pass localhost:5601;
    }
}

#HTTP服务配置作用域

http {

    #包含其它配置
    include /etc/nginx/mime.types;
    
    #服务器默认Content-Type设定
    default_type application/octet-stream;
    
    #访问日志格式模板定义
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                                '$status $body_bytes_sent "$http_referer" '
                                '"$http_user_agent" "$http_x_forwarded_for"';
    
    #访问日志存放位置和访问日志格式模板引用
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    #tcp_nopush on;
    
    #连接保持时间，较短的话，握手次数会增加；较大的话，连接不能及时释放，会造成资源浪费
    
    keepalive_timeout 65;
    
    #开启压缩，会占用CPU资源，但可提升传输速度
    
    gzip on;
    
    #关闭nginx版本号显示
    server_tokens off;
    
    #一个服务定义
    server {
    
        #监听本机所有IP的80端口
        listen 80;
    
        #匹配的域名，多个域名的时候必须指定该值
        server_name logs-live.jidouauto.com;
    
        #返回302状态码，非永久跳转至https://logs-live.jidouauto.com，简单地说，就是用户使用HTTP访问本站时，强制用户使用HTTPS访问
        return 302 https://$server_name/$request_uri;
    }
}