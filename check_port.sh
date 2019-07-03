#!/bin/bash
nc -zv -w 10 80 &> /dev/null
if [ $? -ne 0 ];then
   nmap 192.168.2.100 -p 80 |grep '80/tcp open'
   if [ $? -ne 0 ];then
       echo "your server is already stopd" |mail -s "192.168.2.100" root@localhost 
   if
fi
nc -zv -w 10 443 &> /dev/null
if [ $? -ne 0 ];then
   nmap 192.168.2.100 -p 443 |grep '443/tcp open'
   if [ $? -ne 0 ];then
       echo "your server is already stopd" |mail -s "192.168.2.100" root@localhost
   if
fi
 
