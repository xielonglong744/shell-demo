#!/bin/bash
now=`date +%Y%m%d%H%M`
read -p "are you sure delete the file or directory $1? yes|or:" input
if [ $input == "yes" -o $input == "y" ];then
   mkdir /data/.$now
   cp  -r  $1  /data/.$now/$1/
   rm -rf $1
elif [ $input == "no" -o $input == "n" ];then
   exit 0
else
   echo  "only input yes or no"
   exit 
fi
