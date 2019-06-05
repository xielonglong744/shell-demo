#!/bin/bash
#防止远程ssh暴力破解
a=$(awk '/Failed/{A[$11]++}END{for(i in A)print A[i],i }' /var/log/secure |awk '{if($1 >= 3)print $2}')
echo "Denyusers "*@"${a}" >>/etc/ssh/sshd_config
