lear
read -p "请输入虚拟机名称:" name
if [ ! -d /xll/dc ];then
mkdir -p /xll/dc
fi
if mount |grep -q /xll/dc ;then
umount /xll/dc
fi
guestmount -r -d $name -i /xll/dc
dev=$(ls /xll/dc/etc/sysconfig/network-scripts/ifcfg-* |awk -F"[/-]" '{print $9}')
echo -e  "\033[32m 网卡列表信息如下:\033[0m"
echo $dev
echo
echo
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo -e "\033[32m 网卡ip地址如下 \033[0m"
for i in $dev
do
echo -n "$i:"
  grep -q "IPADDR" /xll/dc/etc/sysconfig/network-scripts/ifcfg-$i || echo "未配置ip地址"
  awk -F= '/IPADDR/{print $2}' /xll/dc/etc/sysconfig/network-scripts/ifcfg-$i
done
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
