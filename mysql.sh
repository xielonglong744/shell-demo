#!/bin/bash
mysql_conn="mysql -uroot -p123qqq...A"
$mysql_conn -e "show processlist" > /tmp/myslq_pro.log 2>/tmp/mysql_log.err
n=$(wc -l /tmp/mysql_log.err | awk '{print $1}')
if [ $n -gt 1 ];then
    echo -e "your mysql service is \033[31m wrong \033[0m"
fi
$mysql_conn -e "show slave status" > /tmp/mysql_log.slave  2>/dev/null
n1=$(wc -l /tmp/mysql_log.slave |awk '{print $1}')
if [ ${n1}  -gt  0 ];then
    echo -e "\033[32m The databases is slave \033[0m"
else
    echo -e  "\033[32m The databases is master \033[0m"
    exit 0
fi
Y=`$mysql_conn -e "show slave status\G" 2>/dev/null | awk  '/IO_Running:/{print $2}'`
X=`$mysql_conn -e "show slave status\G" 2>/dev/null | awk  '/SQL_Running:/{print $2}'`
if [ "$Y" == "Yes" ] && [ "$X" == "Yes" ];then
    echo -e  "\033[32m slave status good \033[0m"   
elif [ "$Y" == "Connecting" ] && [ "$X" == "Yes" ];then
    echo -e "\033[31m the Slave_IO is bad \033[0m"
elif [ "$Y" == "Yes" ] && [ "$X" == "No" ];then
    echo -e "\033[31m Slave_SQL is bad \033[0m"
else
    echo -e "\033[31m The slave down \033[0m"
fi
