#!/bin/bash
read -p "Please enter the ip of host you want to configure :" IP
read -p "Please enter the port of host you want to configure :" PORT
read -p "Please enter the password of host you want to configure :" PASS
ssh $IP<< EOF
if [ -f redis-4.0.8.tar.gz ];then
   yum -y install gcc
   tar -xf redis-4.0.8.tar.gz
   cd redis-4.0.8
   make && make install
   cd /root/redis-4.0.8
   echo | ./utils/install_server.sh
   redis-cli shutdown
   sed -ri "/^# requirepass/c  requirepass $PASS" /etc/redis/6379.conf
   sed -ri "/^bind 127.0.0.1/c  bind $IP" /etc/redis/6379.conf
   sed -ri "/^port 6379/c  port $PORT" /etc/redis/6379.conf
   sed -ri "/$CLIEXEC -p $REDISPORT shutdown/c  $CLIEXEC -p $PORT -h $IP shutdown"  /etc/init.d/redis_6379
   /etc/init.d/redis_6379 start
else
  echo "没有redis源码包"
fi
EOF
