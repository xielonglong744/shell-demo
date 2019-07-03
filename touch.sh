#!/bin/bash
path=/www
[ -d $path ] || mkdir $path
for i in {1..10}
do 
  char=$(echo $RANDOM |md5sum |cut -c 3-12|tr [0-9] [a-k])
  touch $path/${char}_oldwww.html
done
