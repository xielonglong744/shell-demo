#!/bin/bash

set -e 

. ./mysql_config.sh

# database connection variable
export docker_connect_local="docker exec -i ${mysql_local_name} mysql -h${mysql_local_host} -u${mysql_user} -p${mysql_password} -P${mysql_port}"
export docker_connect_remote="docker exec -i ${mysql_local_name} mysql -h${mysql_remote_host} -u${mysql_user} -p${mysql_password} -P${mysql_port}"

####################################################################
#
#               output install result information    
#
####################################################################
function successInfo()
{
	echo -e "\033[32m ========== $1 ========== \033[0m"
}

function failInfo()
{
	echo -e "\033[31m ========== $1 ========== \033[0m"
}

function startInfo()
{
	echo -e "\033[34m ========== $1 ========== \033[0m"
	echo 
}

####################################################################
#
#               configure password-free login    
#
####################################################################

function secretFree()
{
	yum -y install expect >> /dev/null  2>&1
	if [ -f tmp ];then
		rm -rf tmp*
	fi
	
	ssh-keygen -f  tmp  -N '' 

	for i in $@
	do
		
		expect  << EOF  
		set timeout -1
		spawn ssh-copy-id -i ./tmp.pub root@$i
		expect {
			   "yes/no"      {send   "yes\n"}
			   "password"    {send   "$mysql_host_password\n"}
		}
		expect "#"           {send   "exit\n"}
EOF
	done
	
	if [ $? -eq 0 ];then
		successInfo "password-free login successful"    
	else 
	    failInfo "password-free login failed"
		exit 1
	fi	
}

####################################################################
#
#               backup database     
#
####################################################################
function backupData()
{
	for i in $@
	do
		ssh -i ./tmp ${mysql_host_usr}@$i   >/dev/null  2>&1 << EOF
		if [ -d /root/mysql_backup ];then
			rm -rf /root/mysql_backup
		fi
		mkdir -pv /root/mysql_backup
		
		cp -a /var/lib/mysql /root/mysql_backup/
EOF
	done
	if [ $? -eq 0 ];then
		successInfo "backup mysql data successful"
	else 
	    failInfo "backup mysql data failed"
		exit 2
	fi
}

####################################################################
#
#            test wthether database can be connection 
#
####################################################################
function mysqlConnect()
{
	${docker_connect_local} -e 'show databases' 
	if [ $? -eq 0 ]; then
		successInfo "local connection is success!"
	else
		failInfo "Please check local user name, password and authorization。"
		exit 3
	fi

	${docker_connect_remote} -e 'show databases' 

	if [ $? -eq 0 ]; then
		successInfo "remote connection is success!"
	else
		failInfo "Please check remote user name, password and authorization。"
		exit 4
	fi
}

####################################################################
#
#            export database data
#
####################################################################
function deriveData()
{
	if [ -f ./mysqldata.sql ];then
		rm -rf ./mysqldata.sql
	fi
	docker exec ${mysql_local_name} bash -c "mysqldump  -h${mysql_local_host} -u${mysql_user} -p${mysql_password} -P${mysql_port} --all-databases" > ./mysqldata.sql  
	if [ $? -eq 0 ];then
		successInfo "export database data successful"
	else 
	    failInfo "export database data failed"
		exit 5
	fi
}

####################################################################
#
#            delete remote database data
#
####################################################################
function deleteData()
{
	ssh -i ./tmp root@${mysql_remote_host} << EOF
		docker stop ${mysql_remote_name}
		rm -rf /var/lib/mysql
		docker start ${mysql_remote_name}
EOF
	if [ $? -eq 0 ];then
		successInfo "delete database data successful"
	else 
	    failInfo "delete database data failed"
		exit 6
	fi
	sleep 60s
}

####################################################################
#
#            recovery remote database data
#
####################################################################
function recoverData()
{
	${docker_connect_remote} < ./mysqldata.sql &
	wait
	if [ $? -eq 0 ];then
		successInfo "recovery database data successful"
	else 
	    failInfo "recovery database data failed"
		exit 7
	fi

}

####################################################################
#
#           reconfigure master and slave
#
####################################################################
function reConfigure()
{
    ${docker_connect_local} -e "flush logs;" 
	${docker_connect_remote} -e "FLUSH PRIVILEGES;"
	export log_file=`${docker_connect_local} -e "show master status\G" |awk '/File/{print $2}'`     >/dev/null 2>&1
	export log_pos=`${docker_connect_local} -e "show master status\G" |awk '/Position/{print $2}'`  >/dev/null 2>&1
	${docker_connect_remote} -e "stop slave"
	${docker_connect_remote} -e "change master to master_host=\"${mysql_local_host}\", master_user=\"${mysql_repl_user}\", master_password=\"${mysql_repl_password}\", master_port=3306, master_log_file=\"$log_file\", master_log_pos=$log_pos;"
	${docker_connect_remote} -e "start slave"
	export Slave_IO_Running=`${docker_connect_remote}  -e "show slave status\G;" |awk  '/Slave_IO_Running:/{print $2}'`   >/dev/null 2>&1
	export Slave_SQL_Running=`${docker_connect_remote} -e "show slave status\G;" |awk  '/Slave_SQL_Running:/{print $2}'`  >/dev/null 2>&1
	
	if [ "${Slave_IO_Running}" == "Yes"  -a  "${Slave_SQL_Running}" == "Yes" ];then 
		successInfo "database rsynchronization successful"
	else
		failInfo "database rsynchronization failed"
		exit 8
	fi
}

####################################################################
#
#           reconfigure master to master
#
####################################################################
function materToConfig()
{
	${docker_connect_remote} -e "flush logs;"
	export log_file=`${docker_connect_remote} -e "show master status\G" |awk '/File/{print $2}'`       >/dev/null 2>&1
	export log_pos=`${docker_connect_remote} -e "show master status\G" |awk '/Position/{print $2}'`   >/dev/null 2>&1
	${docker_connect_local} -e "stop slave;"
	${docker_connect_local} -e "reset slave;"
	${docker_connect_local} -e "change master to master_host=\"${mysql_remote_host}\", master_user=\"${mysql_repl_user}\", master_password=\"${mysql_repl_password}\", master_port=3306, master_log_file=\"$log_file\", master_log_pos=$log_pos;"
	${docker_connect_local} -e "start slave"
	export Slave_IO_Running=`${docker_connect_local}  -e "show slave status\G;" |awk  '/Slave_IO_Running:/{print $2}'`   >/dev/null 2>&1
	export Slave_SQL_Running=`${docker_connect_local} -e "show slave status\G;" |awk  '/Slave_SQL_Running:/{print $2}'`  >/dev/null 2>&1
	
	if [ "${Slave_IO_Running}" == "Yes"  -a  "${Slave_SQL_Running}" == "Yes" ];then 
		successInfo "database rsynchronization successful"
	else
		failInfo "database rsynchronization failed"
		exit 9
	fi
}

####################################################################
#
#           1.配置两台数据库之间的免密登录
#           2.在操作之前备份/var/lib/mysql目录
#           3.测试数据库连接是否正常
#           4.导出local mysql数据库里面的所有数据并复制到remote mysql 主机上
#           5.删除remote mysql 数据库中的所有数据
#			6.将local mysql里面的数据导入到remote mysql数据库里面
#           7.重新配置remote mysql的主库为local mysql并查看同步情况
#           8.配置local mysql的主库为remote mysql 实现主主同步        
#
####################################################################

function main()
{
	startInfo "1.start configure secret-free login"
	secretFree ${mysql_local_host} ${mysql_remote_host}
	
	startInfo "2.backup mysql data"	
	backupData ${mysql_local_host} ${mysql_remote_host} 
	
	startInfo "3.test database connection "	
	mysqlConnect
	
	startInfo "4.export database data  "
	deriveData

	startInfo "5.delete database data "
	deleteData
	
	startInfo "6.recovery database data "
	recoverData
	
	startInfo "7.reConfigure database data "
	reConfigure
	
	startInfo "8.master to master database data "
	reConfigure
}
main
