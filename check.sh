#!/bin/bash
#ip根据实际情况自己调整
vip=192.168.4.15:80
rip1=192.168.4.100
rip2=192.168.4.200
while :
do
  for i in $rip1 $rip2
  do
      curl http://$i &>/dev/null
  if [ $? -eq 0 ];then
      ipvsadm -Ln |grep -q $i || ipvsadm -a -t $vip -r $i　
  else
      ipvsadm -Ln |grep -q $i && ipvsadm -d -t $vip -r $i
  fi
  done
sleep 1
done

