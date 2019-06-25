#!/bin/bash
#定义变量
mountpoint="/var/www/html/centos"
[ ! -d $mountpoint ] && mkdir $mountpoint
if mount |grep -q $mountpoint ;then
   umount $mountpoint
fi
#挂载镜像
mount /dev/cdrom  $mountpoint
#配置yum源
yum_check()
{
yum clean all &> /dev/null
num=$(yum list | wc -l)
if [ $num -lt 3000 ];then
    if [ -d /etc/yum.repos.d/bak ];then
        mv /etc/yum.repos.d/*.repo  /etc/yum.repos.d/bak
    else 
        mkdir /etc/yum.repos.d/bak
        mv /etc/yum.repos.d/*.repo  /etc/yum.repos.d/bak
    fi
cat << EOF > /etc/yum.repos.d/local.repo
[local]
name=local
baseurl=file:///var/www/html/centos
enabled=1
gpgcheck=0
EOF
else
    echo "your yum is ok"
fi

}
#安装所需要的软件包
rpm_check()
{
backages=(httpd tftp-server dhcp syslinux)
for i in ${backages[@]}
do 
   if ! rpm -qa |grep -q $i ;then
       yum -y install $i > /dev/null
   fi
     
done

}

#生成应答文件系统最小安装root密码为123456
ks_cfg()
{
read -p "请输入无人值守http地址：" http
cat << EOF >/var/www/html/ks.cfg
install
url --url="http://$http/centos"
keyboard 'us'
lang en_US
rootpw  --iscrypted  $1$ttrrddww$NCFsDuoyDZJpbttnNQqsH/
auth  --useshadow  --passalgo=sha512
text
firstboot  --disabled
selinux   --disabled
firewall  --disabled
network  --bootproto=dhcp  --device=eth0
reboot
zerombr
timezone Asia/Shanghai
bootloader --location=mbr
clearpart --all --initlabel
part / --fstype="xfs" --grow --size=1

%packages
@base

%end
EOF
}

#搭建dhcp服务
dhcp()
{
read -p "请输入分配网段subnet,掩码netmask，网关gateway:" subnet netmask gateway
read -p "请输入IP范围：" start_ip end_ip
read -p "请输入NDS服务器" DNS
read -p "请输入next-server的地址:" next_ip
cat << EOF > /etc/dhcp/dhcpd.conf
subnet $subnet netmask $netmask {
range $start_ip $end_ip;
option domain-name-servers $DNS;
option routers $gateway;
default-lease-time 600;
max-lease-time 7200;
next-server ${next_ip};
filename "pxelinux.0";
}
EOF
}

#生成菜单文件及搭建tftp服务
tftp()
{
read -p "请输入应答文件的主机地址：" ip
if [ ! -d /var/lib/tftpboot/pxelinux.cfg ];then
    mkdir /var/lib/tftpboot/pxelinux.cfg
fi
cp /usr/share/syslinux/pxelinux.0  /var/lib/tftpboot
cp $mountpoint/isolinux/isolinux.cfg  /var/lib/tftpboot/pxelinux.cfg/default
cp $mountpoint/isolinux/vesamenu.c32 $mountpoint/isolinux/initrd.img $mountpoint/isolinux/vmlinuz  $mountpoint/isolinux/splash.png /var/lib/tftpboot

sed -ri '/menu label \^Install CentOS 7/a menu default' /var/lib/tftpboot/pxelinux.cfg/default
sed -ri "/x20x86_64 quiet/c  append initrd=initrd.img ks=http://${ip}/ks.cfg" /var/lib/tftpboot/pxelinux.cfg/default

}


#调用函数及设置服务为开机自启
yum_check
rpm_check
systemctl restart httpd
systemctl enable httpd
ks_cfg
dhcp
systemctl restart dhcpd
systemctl enable dhcpd

tftp
systemctl restart tftp
systemctl enable tftp















   


