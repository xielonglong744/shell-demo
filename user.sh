#!/bin/bash
n=$(cat $1 | wc -l)
read -p "pleaes input group:" name
group=$(cat /etc/group | grep $name) >> /dev/null
if [ -z $group ];then
    groupadd $name
    echo "$name已创建"
else
for i in `cat $1`
do
    a=$[$RANDOM%10]
    b=$[RANDOM%10]
    c=$[RANDOM%10]
    useradd -g $name $i$a$b$c
    echo " $i$a$b$c用户创建成功"
    echo 123456 |passwd --stdin $i$a$b$c
    echo "初始密码123456已设置成功"
　　chage -d 0 $i$a$b$c
    chage -m 90 $i$a$b$c
    chage -W 3 $i$a$b$c
done
fi
    
