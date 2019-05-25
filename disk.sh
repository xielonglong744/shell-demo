#!/bin/bash
#实时监控本机内存和硬盘剩余空间,剩余内存小于 500M、根分区剩余空间小于 1000M 时,>发送报警邮件给
root 管理员
disk_size=$(df |awk '/\//{print $(NF-3)}')
mem_size=$(free|awk '/Mem/{print $4}')
while :
do
if [ ${disk_size} -le 512000 -a ${men_size} -le 1024000 ];then
mail -s Warning root <<EOF  #只是一个分界符可以是ABC等遇到下一个分界符时结束
insufficient resource,资源不足
EOF
fi
done
