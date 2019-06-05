#!/bin/bash
a=$(uptime | awk '{print $(NF-2)}')
echo "cpu每分钟的负载量为:" $a
b=$(ifconfig eth0 |awk '/RX p/{print $5}')
echo "网卡流量为:" $b
c=$(free | awk '/Mem/{print $4}')
echo "内存剩余量为:" $c
d=$(df -h |awk '/\/$/{print $4}')
echo "磁盘剩余量为:" $d
e=$(cat /etc/passwd |wc -l)
echo "计算机当前账户数量:" $e
f=$(who |wc -l)
echo "当前登录账户数量:" $f
g=$(ps -elf |wc -l)
echo "当前开启进程数:" $g
h=$(rpm -qa |wc -l)
echo "本机已经安装的软件包:" $h
