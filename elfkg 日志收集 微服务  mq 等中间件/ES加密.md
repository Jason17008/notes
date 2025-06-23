生成证书

键入：

cd elasticsearch/bin

./elasticsearch-certutil ca

执行上述命令需要输入ca文件名，直接回车则为默认名称(elastic-stack-ca.p12)

Please enter the desired output file [elastic-stack-ca.p12]:

同时需要给ca文件键入密码

Enter password for elastic-stack-ca.p12 :

输入密码后回车，则会在elasticsearch目录中生成elastic-stack-ca.p12文件，将该文件移动至elasticsearch/config目录中

mv elastic-stack-ca.p12 ./config

键入：

cd ./bin

./elasticsearch-certutil cert --ca config/elastic-stack-ca.p12

执行上述命令需要输入ca文件设置的密码，即上一步设置的密码

Enter password for CA (config/test-ca.p12) :

输入密码后需要输入ca证书文件名，直接回车则为默认名称(elastic-certificates.p12)

Please enter the desired output file [elastic-certificates.p12]:

同时需要给ca证书文件键入密码

Enter password for elastic-certificates.p12 :

输入密码后回车，则会在elasticsearch目录中生成test-certificates.p12文件，将该文件移动至elasticsearch/config目录中

mv test-certificates.p12 ./config

键入：

cd ./bin

./elasticsearch-keystore add xpack.security.transport.ssl.keystore.secure_password

执行上述命令需要输入"y"确认创建。

The elasticsearch keystore does not exist. Do you want to create it? [y/N]

输入ssl.keystore的密码

Enter value for xpack.security.transport.ssl.keystore.secure_password:

键入：

./elasticsearch-keystore add xpack.security.transport.ssl.truststore.secure_password

执行上述命令需要输入ssl.truststore密码

Enter value for xpack.security.transport.ssl.truststore.secure_password:

将elasticsearch/config目录下的elasticsearch.keystore、elastic-certificates.p12、elastic-stack-ca.p12文件传到es其他的节点上的elasticsearch/config。

启动es

sudo systemctl restart elasticsearch.service

键入：

./elasticsearch-setup-passwords interactive

执行上述命令，需要键入y

Please confirm that you would like to continue [y/N]

之后需要键入密码以及确认密码

Enter password for [elastic]: 

Reenter password for [elastic]: 

Enter password for [apm_system]: 

Reenter password for [apm_system]: 

Enter password for [kibana_system]: 

Reenter password for [kibana_system]: 

Enter password for [logstash_system]: 

Reenter password for [logstash_system]: 

Enter password for [beats_system]: 

Reenter password for [beats_system]: 

Enter password for [remote_monitoring_user]: 

Reenter password for [remote_monitoring_user]:

重启Elasticsearch

sudo systemctl restart elasticsearch