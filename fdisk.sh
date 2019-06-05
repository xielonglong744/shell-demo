#!/bin/bash
for i in `seq $1`
do
a=$(lsblk |awk '/vdb/{print $1}'|wc -l)
if [ $a -eq 4 ];then
fdisk /dev/vdb <<EOF
n




w
EOF
fi
b=$(lsblk  |sed -rn 's/.*(vdb$i).*/\1/p')
if [ ! -z $b ];then
echo "vdb$i已存在"
continue
else
fdisk /dev/vdb << EOF
n
p
$i

+1G
w
EOF
fi

c=$(blkid | sed -n '/vdb$i/p')
if [ -n $c ];then
echo "vdb$i文件系统已经存在"
fi
mkfs.xfs /dev/vdb$i &> /dev/null
mkdir /xll$i   &> /dev/null
echo "/dev/vdb$i /xll$i  xfs defaults 0 0" >> /etc/fstab
mount -a  &> /dev/null
partprobe
done
