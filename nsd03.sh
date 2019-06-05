#!/bin/bash

ff=$( sudo virsh domify nsd03 2> /dev/null | grep running )
if [ -n  $ff ];then
   sudo virsh destroy nsd03 &> /dev/null
fi
sudo virsh undefine nsd03 2>/dev/null

if [ -e /var/lib/libvirt/images/nsd03.qcow2 ];then
  rm -rf /var/lib/libvirt/images/nsd03.qcow2 &>/dev/null
fi
echo '系统正在还原'

sleep  2

qemu-img create -f qcow2 -b /var/lib/libvirt/images/nsd01.qcow2  /var/lib/libvirt/images/nsd03.qcow2 10G &>/dev/null
cp /etc/libvirt/qemu/nsd.xml  /etc/libvirt/qemu/nsd03.xml
sudo virsh define /etc/libvirt/qemu/nsd03.xml &>/dev/null
echo '系统还原成功'
sleep  2
exit

