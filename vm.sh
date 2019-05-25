#!/bin/bash
read -p "enter vm number": vmnum
if [ ${vmnum} -le 9 ];then
    vmnum=0${vmnum}
fi
if [ -z " ${vmnum}" ];then
    echo "you must input a number"
    exit
elif [ ${vmnum} -lt 1 -o ${vmnum} -gt 99 ];then
    echo "input out of range"
    exit 67
elif [[ ${vmnum} =~ [a-Z] ]];then
    echo "you must input a number"
    exit 68    
fi
qemu-img create -f qcow2 -b /var/lib/libvirt/images/server-1.qcow2 /var/lib/libvirt/images/www${vmnum}.qcow2 &>  /dev/null
echo -e "\e[32;1m[OK]\e[0m"
cat /etc/libvirt/qemu/server.xml  >/tmp/myvm.xml
sed -i "/<name>server/s/server/www${vmnum}/" /tmp/myvm.xml
sed -i "/rh254-server-vdb.ovl/s/rh254-server-vdb.ovl/www${vmnum}.qcow2/" /tmp/myvm.xml
sed -i "/<uuid>/d" /tmp/myvm.xml
sed -i "/<mac address/d" /tmp/myvm.xml
virsh define /tmp/myvm.xml &> /dev/null
echo -e "\e[32;1m[OK]\e[0m"
