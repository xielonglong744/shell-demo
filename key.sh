#!/bin/bash
ssh-keygen -f /root/.ssh/id_rsa -N ''
for i in 5 100 200 201
do
set timeout -1
expect  << EOF
spawn ssh-copy-id root@192.168.2.$i
expect "password"  {send  "123456\r"}
expect "#"         {send  "exit\r"}
EOF
done


