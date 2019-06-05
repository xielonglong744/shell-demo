#!/bin/bash
read -p "请输入需要安装的主机ip地址："　ip
ssh 192.168.4.$ip >/dev/null 2>&1 << EOF
cd /root/lnmp_soft
yum -y install java-1.8.0-openjdk.x86_64
tar -xf apache-tomcat-8.0.30.tar.gz 
mv apache-tomcat-8.0.30 /usr/local/tomcat
mv /dev/random  /dev/random.bak  
ln -s /dev/random /dev/urandom
/usr/local/tomcat/bin/startup.sh
EOF
