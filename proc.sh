#!/bin/bash
#统计进程数量信息
running=0
stoped=0
sleeping=0
zombie=0
procs=0
stat=
for i in /proc/[1-9]*
do
  procs=$[procs+1]
  stat=$(awk '{print $3}' $i/stat)
  case $stat in
  R)
    let running++ ;;
  T)
    let stoped++ ;;
  S)
    let sleeping++ ;;

  Z)
    let zombie++ ;;
  esac
done
echo "进程统计信息如下"
echo "总进程数量":$procs
echo "running进程数量为":$running
echo "stoped进程数量为:"$stoped
echo "sleeping进程数量:"$sleeping
echo "zombie进程数量:"$zombie
