#!/bin/bash
#自动创建逻辑卷
clear
echo -e "\033[32m        !!!!!警告(warning)!!!!!!\033[0m"
echo
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "脚本会将整个磁盘转换为逻辑卷会删除数据"
echo "this script will destory all data on the disk"
echo
read -p "请问是否继续y/n?:" sure
[ $sure !=  y ]&& exit
read -p "请输入磁盘名称,如/dev/vdb:" disk
[ -z $disk ]&& echo "您没有磁盘名称" && exit
read -p "请输入卷组名称:" vg_name
[ -z $vg_name ]&& echo "没有输入卷组名称" && exit
read -p "请输入逻辑卷名称:" lv_name
[ -z $lv_name ] && echo "请输入逻辑卷名称" && exit
read -p "请输入逻辑卷大小:" lv_size
[ -z $lv_size ]&& echo "没有输入逻辑卷大小"&& exit
vgcreate  $vg_name $disk
lvcreate  -L ${lv_size}M  -n $lv_name $vg_name
