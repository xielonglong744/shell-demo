#!/bin/bash
read -p "请输入虚拟机的名称:" name
if virsh dominfo $name |grep running ;then
   echo "虚拟机需关闭"
　 virsh destroy $name 
fi
mountpoint="/mnt/www"
[ ! -d $mountpoint ] && mkdir $mountpoint
if mount |grep -q $mountpoint ;then
   umount $mountpoint
fi
guestmount -d $name  -i  $mountpoint
read -p "请输入要修改的网卡：" dev
read -p "请输入虚拟机的网关:" gateway
read -p "请输入虚拟机的IP:" ip
if grep -q "IPADDR" $mountpoint/etc/sysconfig/network-scripts/ifcfg-$dev ;then
   sed -ri "/IPADDR/s/=.*/=$ip/" $mountpoint/etc/sysconfig/network-scripts/ifcfg-$dev
else
   echo "IPADDR=${ip}" >> $mountpoint/etc/sysconfig/network-scripts/ifcfg-$dev 
fi
if grep -i -q "Gateway" $mountpoint/etc/sysconfig/network-scripts/ifcfg-$dev ;then
   sed -ri "/Gateway/s/=.*/=$gateway/" $mountpoint/etc/sysconfig/network-scripts/ifcfg-$dev
else
   echo "Gateway=${gateway}" >> $mountpoint/etc/sysconfig/network-scripts/ifcfg-$dev
fi
awk -F= -v x=$ip '$2==x{print "完成配置"}' $mountpoint/etc/sysconfig/network-scripts/ifcfg-$dev

