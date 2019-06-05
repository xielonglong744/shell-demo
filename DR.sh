#!/bin/bash
read -p "请输入要修改的主机ip地址："　ip
read -p "请输入虚拟ip地址："　vr
ssh $ip >/dev/null 2>&1 << EOF
cd /etc/sysconfig/network-scripts
cp ifcfg-lo ifcfg-lo:0
sed -ri '/DEVICE/s/(.*)=.*/\1=lo:0/' ifcfg-lo:0
sed -ri '/IPADDR/s/(.*)=.*/\1=${vr}/' ifcfg-lo:0
sed -ri '/NETMASK/s/(.*)=.*/\1=255.255.255.255/' ifcfg-lo:0
sed -ri '/NETWORK/s/(.*)=.*/\1=${vr}/' ifcfg-lo:0
sed -ri '/BROADCAST/s/(.*)=.*/\1=${vr}/' ifcfg-lo:0
sed -ri '/NAME/s/(.*)=.*/\1=lo:0/' ifcfg-lo:0
echo 'net.ipv4.conf.all.arp_ignore=1
      net.ipv4.conf.lo.arp_ignore=1
      net.ipv4.conf.lo.arp_announce=2
      net.ipv4.conf.all.arp_announce=2' >> /etc/sysctl.conf
sysctl -p
systemctl stop NetworkManager
systemctl restart network
EOF
