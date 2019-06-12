#!/bin/bash
url=http://172.25.0.11/index.html
check_http(){
   status_code=$(curl -m 5 -o /dev/null -s -w %{http_code} $url)
}

while :
do
   check_http
   tt=$(date +%Y%m%d-%H:%M:%S)
   echo "当前时间为：$tt
   $url 服务器异常，状态吗为${status_code}
   请尽快排查异常" > /tmp/http$$.pid
   if [ ${status_code} -ne 200 ];then
     mail -s Warning root < /tmp/http$$.pid
   else
     echo "$url链接正常"　>> /var/log/http.log
  fi
  sleep 5
done
