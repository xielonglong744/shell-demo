#!/bin/bash
#下载软件包
lnmp_soft(){
scp student@192.168.4.254:/linux-soft/02/lnmp_soft.tar.gz  /root
}
#lnmp_soft

#安装nginx软件包
nginx(){
tar -xf lnmp_soft.tar.gz
cd lnmp_soft
tar -xf nginx-1.12.2.tar.gz
cd nginx-1.12.2
yum -y install gcc pcre-devel openssl-devel
useradd -s /sbin/nologin nginx
./configure --user=nginx --group=nginx --with-http_ssl_module
make && make install
/usr/local/nginx/sbin/nginx &> /dev/null
}
# -xf nginx-1.15.8.tar.gz
cd nginx-1.15.8
./configure --user=nginx --group=nginx --with-http_ssl_module
make
mv /usr/local/nginx/sbin/nginx  /usr/local/nginx/sbin/nginxold
cp objs/nginx  /usr/local/nginx/sbin/
killall nginx
/usr/local/nginx/sbin/nginx
}
#newnginx

#添加用户认证
userlogin(){
conf="/usr/local/nginx/conf/nginx.conf"
sed -ri 's/(server_name).*/\1 www.tt.com;/' ${conf}
sed -i  "/charset koi8-r/i auth_basic "123456";\nauth_basic_user_file "/usr/local/nginx/${file}";" ${conf}
/usr/local/nginx/sbin/nginx -s reload
yum -y install httpd-tools
htpasswd -c /usr/local/nginx/${file}  ${user}
}
#userlogin

#生成HTTPS加密网站
nginxkey(){
cd /usr/local/nginx/conf
openssl  genrsa > secr.key
openssl req -new -x509 -key secr.key -subj "/CN=commom"> secr.pem
sed -ri '/HTTPS/,/#}/s/#//' /usr/local/nginx/conf/nginx.conf
sed -ri '/HTTPS/s/HTTPS/#HTTPS/' /usr/local/nginx/conf/nginx.conf
/usr/local/nginx/sbin/nginx -s reload
}
#nginxkey
#安装搭建lnmp
lnmp_php(){
yum -y install mariadb mariadb-server mariadb-devel
yum -y install php php-fpm php-mysql
systemctl restart mariadb
systemctl restart php-fpm
sed -ri '/pass the PHP/,+9s/#//' /usr/local/nginx/conf/nginx.conf
sed -ri 's/pass the PHP/#pass the PHP/;s/(fastcgi_param)/#fastcgi_param/' /usr/local/nginx/conf/nginx.conf
sed -ri 's/(include) fastcgi_params/\1 fastcgi.conf;/' /usr/local/nginx/conf/nginx.conf
echo '<?php 
$i=33;
echo $i;
?>'   >/usr/local/nginx/html/dc.php
/usr/local/nginx/sbin/nginx -s reload
systemctl restart php-fpm
}
#lnmp_php

read -p "请输入您的选择,如(create:创建nginx服务,upgrade:升级现有版本, HTTPS:加密网站,userlogin:实现用户认证, lnmp:搭建lnmp+fastcgi服务):" var
if [ $var == "userlogin" ];then
   read -p "请输入要创建的用户名:" user
   read -p "请输入存放用户的文件名:" file
fi
case $var in
create)
       lnmp_soft
       nginx;;
upgrade)
       lnmp_soft
       nginx
       newnginx;;
HTTPS)
       lnmp_soft
       nginx
       nginxkey;;
userlogin)
       lnmp_soft
       nginx
       userlogin;;
lnmp)  lnmp_soft
       nginx
       newnginx
       lnmp_php;;
*)
        echo error;;
esac

