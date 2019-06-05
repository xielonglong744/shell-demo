#!/bin/bash
#进度条显示
while :
do
  clear
  a=" |-->"
  for i in {1..50}
  do
    echo -ne "\033[${i}G $a" ;echo -ne "\033[56G ${i}%"
    echo -e "\033[8;${i}H*"
    echo -e "\033[1;${i}H*"
    sleep 0.1
  done
  a="<--| "
  for i in {50..1}
  do
     echo -ne "\033[${i}G $a"
     sleep 0.2
  done
done
