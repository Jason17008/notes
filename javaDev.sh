#!/bin/bash

#=================在 Linux 采用 Shell 脚本自动化部署 Java EE 开发环境==================

# EOF 是文件结束的标记，+-------+ 是分割线，用于将文件的开头和结尾分开
cat <<-EOF
+-------------------------------------------------------------------------+
| 在 Linux 采用 Shell 脚本自动化部署 Java EE 开发环境 |
+-------------------------------------------------------------------------+
| a. 部署 Mysql 服务 |
| b. 部署 Openjdk 服务 |
| c. 部署 Apache Tomcat 服务 |
| d. 部署 Apache 服务 |
| e. 一键部署 Java EE 开发环境 |
| q. 按 q 键退出程序 |
+-------------------------------------------------------------------------+
EOF

# ------------------------部署 Mysql 服务-----------------------
install_mysql()
{
    echo "---------正在删除 Linux 系统下自带的 mariadb 依赖（因为会与 mysql 冲突）----------"
    mariaLibs=$(rpm -qa | grep mariadb)
    yum -y remove "$mariaLibs"
    if [ ! -f "$mariaLibs" ];then
        echo "------------开始安装mysql------------------"
        echo "------------正在安装编译环境，请稍等---------------"
        yum -y install ncurses ncurses-devel openssl-devel bison gcc gcc-c++ make cmake libaio &> /dev/null

        # if [ $? -eq 0 ] 表示 shell 传递到脚本的参数等于 0（表示上一个命令运行成功）则执行 then 中的语句，否则执行 else 中的语句
        if [ $? -eq 0 ];then
            echo "编译环境准备成功"
        else
            echo "编译环境准备失败"
            exit
        fi
        echo "-----------------正在下载 mysql 源码包，请稍等-----------------"

        : '
            mysql-linux-glibc 是 MySQL 的 Linux 发行版，它使用 GNU C 库（glibc）作为基础库，而 mysql-boost 是 MySQL 的非官方发行版，它
            使用 boost 库作为其基础库。两者最大的区别是底层库的不同，而表现出来的差异主要体现在性能和稳定性方面。mysql-linux-glibc 具有更好
            的性能。但 mysql-boot 提供更高的稳定性，因此可以根据实际需要进行选择。
        '
        # wget 下载 mysql 软件包
        cd ~ || exit
        wget https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.38-linux-glibc2.12-x86_64.tar.gz
        
        # 将 mysql 软件包解压后移动到 /usr/local 目录下重命名为 mysql
        tar -zxvf mysql-5.7.38-linux-glibc2.12-x86_64.tar.gz
        mv mysql-5.7.38-linux-glibc2.12-x86_64 /usr/local/mysql

        #  创建 mysql 用户组和用户并修改权限
        groupadd mysql
        
        # useradd -r -g mysql -s /bin/nologin mysql 表示在系统中创建一个名为 mysql 的用户，并将其分配到组 mysql ，并
        # 设置其登录 shell 为 /bin/nologin ，这意味着该用户不能通过 shell 登录到系统，而只能通过程序的方式登录到系统。
        # -r 参数表示创建的用户是系统用户，不能使用 /bin/bash 登录。

        useradd -r -g mysql -s /bin/nologin mysql

        # 创建数据目录并赋予权限
        mkdir -p /usr/local/data/mysql
        chown mysql:mysql -R /usr/local/data/mysql
              
        # echo "-------------正在通过 cmake 配置 mysql --------------"

        #     mysql 编译选项说明
        #     -DWITH_BOOST=boost/boost_1_59_0/ \

        #     # 指定安装路径，指定的目录为 MySQL 安装之后的根目录
        #     -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
            
        #     #  MySQL 配置文件所在目录
        #     -DSYSCONFDIR=/etc \

        #     # MySQL 数据库文件存放目录
        #     -DMYSQL_DATADIR=/usr/local/data/mysql \

        #     # 指定安装 man 手册文件目录
        #     -DINSTALL_MANDIR=/usr/share/man \

        #     # 指定 mysql 服务器使用的 TCP 端口号，默认为3306
        #     -DMYSQL_TCP_PORT=3306 \

        #     # 指定 mysql.sock 位置
        #     # mysql.sock 是 mysql 服务器生成的套接字文件，它提供了客户端与 mysql 服务器之间的连接。
        #     # 它有助于客户端和 mysql 服务器之间的通信，也允许客户端发送命令和查询给 mysql 服务器，以及接受响应。
        #     -DMYSQL_UNIX_ADDR=/tmp/mysql.sock \

        #     # 设置 Mysql 默认字符集为 utf-8
        #     -DDEFAULT_CHARSET=utf8 \

        #     # 使 MySQL 支持所有的扩展字符
        #     -DEXTRA_CHARSETS=all \

        #     # 设置默认字符集校对规则
        #     -DDEFAULT_COLLATION=utf8_general_ci \

        #     # 使用 readline 功能，即方便在命令行复制和粘贴命令
        #     -DWITH_READLINE=1 \

        #     # 使用系统上的自带的SSL库
        #     -DWITH_SSL=system \

        #     # mysql 服务器将以嵌入式模式运行，即 mysql 服务器将作为应用程序的一部分而不是单独运行的服务器进程
        #     -DWITH_EMBEDDED_SERVER=1 \

        #     # 允许从本地文件加载数据，从而提高 mysql 的性能
        #     -DENABLED_LOCAL_INFILE=1 \

        #     # 添加 lnnoDB 引擎支持
        #     -DWITH_INNOBASE_STORAGE_ENGINE=1

        # # mysql-glibc 为二进制版本，无需 cmake 编译安装；mysql-boost 版本才需要 cmake 编译安装
        # cmake . \
        # -DWITH_BOOST=boost/boost_1_59_0/ \
        # -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
        # -DSYSCONFDIR=/etc \
        # -DMYSQL_DATADIR=/usr/local/data/mysql \
        # -DINSTALL_MANDIR=/usr/share/man \
        # -DMYSQL_TCP_PORT=3306 \
        # -DMYSQL_UNIX_ADDR=/tmp/mysql.sock \
        # -DDEFAULT_CHARSET=utf8 \
        # -DEXTRA_CHARSETS=all \
        # -DDEFAULT_COLLATION=utf8_general_ci \
        # -DWITH_READLINE=1 \
        # -DWITH_SSL=system \
        # -DWITH_EMBEDDED_SERVER=1 \
        # -DENABLED_LOCAL_INFILE=1 \
        # -DWITH_INNOBASE_STORAGE_ENGINE=1

        # if [ $? -eq 0 ]
        # then
        #     echo "mysql配置成功"
        # else
        #     echo "mysql配置失败"
        #     exit
        # fi

        # echo "----------正在编译安装 Mysql 请稍等-----------"
        # make &> /dev/null && make install /dev/null

        # if [ $? -eq 0 ]
        # then
        #     echo "mysql编译安装成功"
        # else
        #     echo "mysql编译安装失败"
        #     exit
        # fi
        

        echo "----------正在配置 my.cnf -----------"
        path="/etc/my.cnf"
        cat > ${path} <<EOF
        [mysqld]
        bind-address=0.0.0.0
        port=3306
        user=mysql
        basedir=/usr/local/mysql
        datadir=/usr/local/data/mysql
        socket=/tmp/mysql.sock
        log-error=/usr/local/data/mysql/mysql.err
        pid-file=/usr/local/data/mysql/mysql.pid
        #character config
        character_set_server=utf8mb4
        symbolic-links=0
        explicit_defaults_for_timestamp=true
EOF
        
        echo "mysql配置文件successed"

        echo "-------------正在初始化 Mysql 请稍等--------------"

        # &> 表示将标准输出和标准错误输出都重定向
        /usr/local/mysql/bin/mysqld --defaults-file=/etc/my.cnf --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/data/mysql
                
        if [ $? -eq 0 ]
        then
            echo "mysql初始化成功"
        else
            echo "mysql初始化失败"
            exit
        fi

        cat /usr/local/data/mysql/mysql.err &> mima.txt
        mima=$(cat mima.txt | grep "temporary password" | awk '{print $NF}')
        echo "临时密码为：$mima"

        # mysql_ssl_rsa_setup 是 mysql 的一个安全性脚本，用于生成 RSA 公钥和私钥，并将其存储在 mysql 数据库中，用于 SSL 连接的加密
        /usr/local/mysql/bin/mysql_ssl_rsa_setup --datadir=/usr/local/data/mysql
        
        # 创建 mysqld 软链接
        ln -s /usr/local/mysql/bin/mysql /usr/bin

        # 将 mysql.server 复制到/etc/init.d/mysql 中
        cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
        
        # 启动 mysql
        service mysql start

        if [ $? -eq 0 ]
        then
            echo "mysql启动成功"
            # 设置开机自启 mysql
            chkconfig --add mysql
            chkconfig mysql on
            if [ $? -eq 0 ]
            then
                echo "mysql开机自启成功"
            else
                echo "mysql开机自启失败"
                exit
            fi
        else
            echo "mysql启动失败"
            exit
        fi

        echo "----------修改数据库初始密码----------"

        # 因为安装的 mysql 是二进制版，所以要设置此环境变量才能找到 mysqladmin 命令
        echo "export PATH=$PATH:/usr/local/mysql/bin" >> /etc/profile
        source /etc/profile

        stty erase '^H'
        read -p "请输入你要设置的数据库密码：" new_mima
        mysqladmin -uroot -p${mima} password "$new_mima"

        if [ $? -eq 0 ]
        then
            echo "mysql初始密码修改成功，mysql部署完成"
        else
            echo "mysql初始密码修改失败"
            exit
        fi
    fi    
}

# -------------------部署 openjdk --------------------------
install_openjdk()
{
    # 检查系统是否已安装 openjdk
    java -version
    if [ $? -eq 0 ]; then
        echo "openjdk已安装"
    else
        echo "-------正在安装 openjdk ------"
        # 查看 openjdk 有哪些版本
        echo "------- openjdk 的版本如下---------"
        yum --showduplicates list java-1.8.0-openjdk-devel

        stty erase '^H'
        read -p "请输入你想要安装的版本：" openjdkver
        yum -y install $openjdkver
        if [ $? -eq 0 ]
        then
            echo "openjdk安装成功"
            echo "-------查看 openjdk 版本------"
            echo ""
            java -version
        else
            echo "openjdk安装失败"
            exit
        fi
    fi    
}

# -------------------部署 Apache Tomcat 服务--------------------------
install_apacheTomcat()
{
    # 设置变量 TOMCATVER 来接收 tomcat 版本
    TOMCATVER=apache-tomcat-8.5.84

    # 设置变量 TOMCATDIR 来接收 tomcat 的存放目录
    TOMCATDIR=/usr/local/tomcat-8.5.84
    if [ ! -f $TOMCATVER.tar.gz ]; then
        echo "---------tomcat不存在，正在下载 tomcat 软件包-------------"
        wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.84/bin/apache-tomcat-8.5.84.tar.gz
        echo "---------tomcat下载完成-------------"
    else
        echo "-------tomcat已存在，请勿重复安装-------"
        exit 1
    fi

    # 如果当前目录中不存在 $TOMCATVER 文件夹，就解压 $TOMCATVAR.tar.gz 文件，然后解压查来的 $TOMCATVER 文件夹拷贝到 $TOMCATDIR 目录下
    # -d 在判断中表示文件存在且为目录则为真
    # cp -r 表示拷贝文件夹
    [ ! -d $TOMCATVER ] && tar -zxvf $TOMCATVER.tar.gz && cp -r $TOMCATVER $TOMCATDIR

    # chown -R 表示修改一个文件夹的所有者和所属组
    chown -R root.root $TOMCATDIR && chmod -R 755 $TOMCATDIR

    echo "-----------正在配置 tomcat -----------"

    # 注意创建 shell 文件并写入内容时，使用内部变量要加转义符号 “\” ，如 \$CATALINA_HOME
    touch $TOMCATDIR/bin/setenv.sh
    SETENV="$TOMCATDIR/bin/setenv.sh"
    cat > ${SETENV} <<EOF
#!/bin/sh
CATALINA_PID="\$CATALINA_HOME/tomcat.pid"
JAVA_OPTS="-server -Xms768m -Xmx1536m -XX:PermSize=128m -XX:MaxPermSize=256m"
EOF

    echo "--------正在备份 server.xml -------------"
    cp $TOMCATDIR/conf/server.xml $TOMCATDIR/conf/server.xml.bak

    echo "--------正在覆盖 server.xml 的内容-------------"
    echo '<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<!-- Note:  A "Server" is not itself a "Container", so you may not
     define subcomponents such as "Valves" at this level.
     Documentation at /docs/config/server.html
 -->
<Server port="8005" shutdown="SHUTDOWN">
  <Listener className="org.apache.catalina.startup.VersionLoggerListener" />
  <!-- Security listener. Documentation at /docs/config/listeners.html
  <Listener className="org.apache.catalina.security.SecurityListener" />
  -->
  <!-- APR library loader. Documentation at /docs/apr.html -->
  <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />
  <!-- Prevent memory leaks due to use of particular java/javax APIs-->
  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />

  <!-- Global JNDI resources
       Documentation at /docs/jndi-resources-howto.html
  -->
  <GlobalNamingResources>
    <!-- Editable user database that can also be used by
         UserDatabaseRealm to authenticate users
    -->
    <Resource name="UserDatabase" auth="Container"
              type="org.apache.catalina.UserDatabase"
              description="User database that can be updated and saved"
              factory="org.apache.catalina.users.MemoryUserDatabaseFactory"
              pathname="conf/tomcat-users.xml" />
  </GlobalNamingResources>

  <!-- A "Service" is a collection of one or more "Connectors" that share
       a single "Container" Note:  A "Service" is not itself a "Container",
       so you may not define subcomponents such as "Valves" at this level.
       Documentation at /docs/config/service.html
   -->
  <Service name="Catalina">

    <!--The connectors can use a shared executor, you can define one or more named thread pools-->
    <!--
    <Executor name="tomcatThreadPool" namePrefix="catalina-exec-"
        maxThreads="150" minSpareThreads="4"/>
    -->


    <!-- A "Connector" represents an endpoint by which requests are received
         and responses are returned. Documentation at :
         Java HTTP Connector: /docs/config/http.html
         Java AJP  Connector: /docs/config/ajp.html
         APR (HTTP/AJP) Connector: /docs/apr.html
         Define a non-SSL/TLS HTTP/1.1 Connector on port 8080
    -->

    # 修改如下
    <Connector port="8080" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443"
               URIEncoding="UTF-8" />
    <!-- A "Connector" using the shared thread pool-->
    <!--
    <Connector executor="tomcatThreadPool"
               port="8080" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" />
    -->
    <!-- Define an SSL/TLS HTTP/1.1 Connector on port 8443
         This connector uses the NIO implementation. The default
         SSLImplementation will depend on the presence of the APR/native
         library and the useOpenSSL attribute of the AprLifecycleListener.
         Either JSSE or OpenSSL style configuration may be used regardless of
         the SSLImplementation selected. JSSE style configuration is used below.
    -->
    <!--
    <Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol"
               maxThreads="150" SSLEnabled="true">
        <SSLHostConfig>
            <Certificate certificateKeystoreFile="conf/localhost-rsa.jks"
                         type="RSA" />
        </SSLHostConfig>
    </Connector>
    -->
    <!-- Define an SSL/TLS HTTP/1.1 Connector on port 8443 with HTTP/2
         This connector uses the APR/native implementation which always uses
         OpenSSL for TLS.
         Either JSSE or OpenSSL style configuration may be used. OpenSSL style
         configuration is used below.
    -->
    <!--
    <Connector port="8443" protocol="org.apache.coyote.http11.Http11AprProtocol"
               maxThreads="150" SSLEnabled="true" >
        <UpgradeProtocol className="org.apache.coyote.http2.Http2Protocol" />
        <SSLHostConfig>
            <Certificate certificateKeyFile="conf/localhost-rsa-key.pem"
                         certificateFile="conf/localhost-rsa-cert.pem"
                         certificateChainFile="conf/localhost-rsa-chain.pem"
                         type="RSA" />
        </SSLHostConfig>
    </Connector>
    -->

    <!-- Define an AJP 1.3 Connector on port 8009 -->
    
    # 去掉 protocal 协议的注释并修改如下（AJP1.3 是实现 apache 和 tomcat 之间通信的协议，secretRequired 是否需要密码）
    <Connector protocol="AJP/1.3"
               address="0.0.0.0"
               port="8009"
               redirectPort="8443"
               secretRequired="false"
               URIEncoding="UTF-8" />
    

    <!-- An Engine represents the entry point (within Catalina) that processes
         every request.  The Engine implementation for Tomcat stand alone
         analyzes the HTTP headers included with the request, and passes them
         on to the appropriate Host (virtual host).
         Documentation at /docs/config/engine.html -->

    <!-- You should set jvmRoute to support load-balancing via AJP ie :
    <Engine name="Catalina" defaultHost="localhost" jvmRoute="jvm1">
    -->
    <Engine name="Catalina" defaultHost="localhost">

      <!--For clustering, please take a look at documentation at:
          /docs/cluster-howto.html  (simple how to)
          /docs/config/cluster.html (reference documentation) -->
      <!--
      <Cluster className="org.apache.catalina.ha.tcp.SimpleTcpCluster"/>
      -->

      <!-- Use the LockOutRealm to prevent attempts to guess user passwords
           via a brute-force attack -->
      <Realm className="org.apache.catalina.realm.LockOutRealm">
        <!-- This Realm uses the UserDatabase configured in the global JNDI
             resources under the key "UserDatabase".  Any edits
             that are performed against this UserDatabase are immediately
             available for use by the Realm.  -->
        <Realm className="org.apache.catalina.realm.UserDatabaseRealm"
               resourceName="UserDatabase"/>
      </Realm>

      <Host name="localhost"  appBase="webapps"
            unpackWARs="true" autoDeploy="true">

        <!-- SingleSignOn valve, share authentication between web applications
             Documentation at: /docs/config/valve.html -->
        <!--
        <Valve className="org.apache.catalina.authenticator.SingleSignOn" />
        -->

        <!-- Access log processes all example.
             Documentation at: /docs/config/valve.html
             Note: The pattern used is equivalent to using pattern="common" -->
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="localhost_access_log" suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />

      </Host>
    </Engine>
  </Service>
</Server> ' > $TOMCATDIR/conf/server.xml

    # 创建 tomcat.service 以至于 tomcat 可使用 systemctl 命令
    touch /usr/lib/systemd/system/tomcat.service
    sysTom="/usr/lib/systemd/system/tomcat.service"
    cat >> "$sysTom" <<EOF
[Unit]
Description=Apache Tomcat 8
After=syslog.target network.target

[Service]
Type=forking
PIDFile=/usr/local/tomcat-8.5.84/tomcat.pid
ExecStart=/usr/local/tomcat-8.5.84/bin/startup.sh
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

    #  执行 tomcat 开机自启
    systemctl enable tomcat

    echo "-------------测试 tomcat 是否能访问------------"
    curl http://localhost:8080
    if [ $? -eq 0 ];then
        echo "---------访问 tomcat 成功-------"
    else
        echo "---------访问 tomcat 失败，尝试把 tomcat 的 8080 端口改成 8081 再 curl 一次-------"
        sed -i 's/Connector port="8080"/Connector port="8081"/' $TOMCATDIR/conf/server.xml
        echo "-------------改好端口正在重启 tomcat ------------"
        systemctl restart tomcat
        echo "-------------用 8081 端口再 curl 一次 ------------"
        curl http://localhost:8081
        echo "---------把 tomcat 的 8080 端口改成 8081 后访问 tomcat 成功-------"
        exit
    fi

}

# -------------------部署 Apache --------------------------

install_Apache()
{
    echo "---------查看是否存在 epel 库--------"
    rpm -qa | grep epel
    if [ $? -eq 0 ]; then
        echo "--------- epel 库已安装--------"
    else
        echo "---------正在安装 epel 库-----------"
        yum install -y epel-release
        echo "--------- epel 库安装成功，版本为：--------"
        rpm -qa | grep epel
    fi 
    
    echo "---------正在安装 CodeIT 库-----------"

    VERSION_ID=$(cat /etc/redhat-release | sed -r 's/.* ([0-9]+)\..*/\1/')
    echo $VERSION_ID
    cd /etc/yum.repos.d && wget https://repo.codeit.guru/codeit.el$VERSION_ID.repo --no-check-certificate
    echo "--------- CodeIT 库安装成功--------"

    # 检查系统是否已安装 openjdk
    httpd -v
    if [ $? -eq 0 ]; then
        echo "httpd-devel已安装"
    else
        echo "-------正在安装 httpd-devel ------"
        # 查看 httpd-devel 有哪些版本
        echo "------- httpd-devel 的版本如下---------"
        yum --showduplicates list httpd-devel | expand

        stty erase '^H'
        read -p "请输入你想要安装的版本：" httpdver
        yum -y install $httpdver
        if [ $? -eq 0 ]
        then
            echo "httpd-devel安装成功"
            echo "-------查看 httpd-devel 版本------"
            echo ""
            httpd -v
        else
            echo "httpd-devel安装失败"
            exit
        fi
    fi

    echo "--------正在安装所需的依赖包--------"
    yum -y install gcc gcc-c++ openssl openssl-devel expat-devel make libtool zlib zlib-devel pcre pcre-devel &> /dev/null
    if [ $? -eq 0 ]
    then
        echo "依赖包安装成功"
    else
        echo "依赖包安装失败"
        exit
    fi
    
    systemctl start httpd
    if [ $? -eq 0 ]
    then
        echo "Apache安装成功并启动"
    else
        echo "Apache启动失败"
        exit
    fi

    stty erase '^H'
    read -p "是否需要配置 tomcat 和 apache 的连接，需要按y，不需要按n：" para
    case $para in
    [Yy])

        # 设置变量 CONNVER 来接收 tomcat-connectors 版本
        CONNVER=tomcat-connectors-1.2.48-src

        # 设置变量 CONNDIR 来接收 tomcat 的存放目录
        CONNDIR=/usr/local/tomcat-connectors-1.2.48-src

        if [ ! -f $CONNVER.tar.gz ]; then
            echo "--------- tomcat-connectors 不存在，正在下载 tomcat-connectors 软件包-------------"
            wget https://archive.apache.org/dist/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.48-src.tar.gz
            echo "--------- tomcat-connectors 下载完成-------------"
        else
            echo "------- tomcat-connectors 已存在，请勿重复安装-------"
            exit 1
        fi

        # 如果当前目录中不存在 $CONNVER 文件夹，就解压 $CONNVER.tar.gz 文件，然后解压查来的 $CONNVER 文件夹拷贝到 $CONNDIR 目录下
        # -d 在判断中表示文件存在且为目录则为真
        # cp -r 表示拷贝文件夹
        [ ! -d $CONNVER ] && tar -zxvf $CONNVER.tar.gz && cp -r $CONNVER $CONNDIR

        echo "--------进入 native 目录下进行编译和安装 apache 连接器--------"
        # --with-apxs=指定 apache 的配置程序路径，java 编译程序会通过这个程序查找 apache 的相关路径
        # 将使用给定的 apxs 应用程序构建连接器，apxs 是一个应用程序扩展支持（ Apache 扩展工具套件）
        $CONNDIR/native/configure --with-apxs=/usr/bin/apxs && make && make install

        if [ $? -eq 0 ]; then
            echo "-------- 检查是否编译安装成功 ---------"
            ll /etc/httpd/modules/mod_jk.so
        else            
            echo "-------- 编译安装失败---------"
            exit            
        fi
        
        echo "---------正在创建 workers.properties---------"
        touch /etc/httpd/conf/workers.properties
        workers="/etc/httpd/conf/workers.properties"
        cat >> "$workers" <<EOF
worker.list=tomcat
worker.tomcat.type=ajp13
worker.tomcat.host=localhost
worker.tomcat.port=8009
EOF

        if [ $? -eq 0 ]; then
            echo "-------- workers.properties 创建成功---------"
        else            
            echo "-------- workers.properties 创建失败---------"
            exit            
        fi

        echo "---------正在创建 mod_jk.conf ---------"
        touch /etc/httpd/conf/mod_jk.conf
        mod="/etc/httpd/conf/mod_jk.conf"
        cat >> "$mod" <<EOF
LoadModule jk_module /etc/httpd/modules/mod_jk.so
<IfModule jk_module>
JkWorkersFile /etc/httpd/conf/workers.properties
JkLogFile /etc/httpd/logs/mod_jk.log
JkLogLevel warn
</IfModule>
EOF

        if [ $? -eq 0 ]; then
            echo "-------- mod_jk.conf 创建成功---------"
        else            
            echo "-------- mod_jk.conf 创建失败---------"
            exit            
        fi

        echo "---------正在创建 vhost.conf ---------"
        touch /etc/httpd/conf/vhost.conf
        vhost="/etc/httpd/conf/vhost.conf"
        cat >> "$vhost" <<EOF
<VirtualHost *:80>
DocumentRoot "/var/www/html/test"
ServerName localhost
 JkMount /cms2 tomcat
 JkMount /cms2/* tomcat
</VirtualHost>
EOF

        if [ $? -eq 0 ]; then
            echo "-------- vhost.conf 创建成功---------"
        else            
            echo "-------- vhost.conf 创建失败---------"
            exit            
        fi

        echo "-----------修改 httpd.conf -------------"
        httpdConf="/etc/httpd/conf/httpd.conf"
        echo "Include /etc/httpd/conf/mod_jk.conf" >> $httpdConf
        echo "Include /etc/httpd/conf/vhost.conf" >> $httpdConf
        echo "重启Apache"
        systemctl restart httpd
        if [ $? -eq 0 ]; then
            echo "-------- httpd 重启成功---------"
        else            
            echo "-------- httpd 重启失败---------"
            exit            
        fi

        echo "-----------启动 tomcat 和 mysql --------------"
        service mysql start
        systemctl start tomcat

        echo ""
        echo "---------请用 FinalShell 从本地将 cms2.war 文件上传至 /usr/local/tomcat-8.5.84/webapps/ 下----------"
        echo "---------请用 FinalShell 从本地将 metaarchit.lic 文件上传至 /root/ 下---------------------------"
        ;;
    [Nn])
        echo "退出执行，请重新运行 sh 脚本"
        exit 1
        ;;
    esac
    
}

# while : 表示持续执行命令，直到终止循环
while :
do
    read -p "请输入你要选择的参数: " var
    case $var in
    a)
        install_mysql
        ;;
    b)
        install_openjdk
        ;;
    c)
        install_apacheTomcat
        ;;
    d)
        install_Apache
        ;;
    e)
        install_mysql
        install_openjdk
        install_apacheTomcat
        install_Apache        
        ;;
    q)
        exit
        ;;
    *)
        printf "请按照上方提供的选项输入!!!\n"
        ;;
    esac
done
