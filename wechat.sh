#!/bin/bash
#其中corpid，secret，partyid根据具体企业号自己设定
corpid="ww4e0c1a7dc5f1c968"
secret="JcLxHJPkLdikEAWKvRpi4gcJLhQulk88BJUeNj6gDgQ"
access_token=$(curl -s -G "https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=ww4e0c1a7dc5f1c968&corpsecret=JcLxHJPkLdikEAWKvRpi4gcJLhQulk88BJUeNj6gDgQ" |awk -F: '{print $4}'|awk -F\" '{print $2}')
purl=" https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=$access_token"
comment(){
    local int Agentid=1000002
    local userid=$1
    local partyid=1
    local msg=$(echo $* | cut -d" " -f3)
    printf '{\n'
    printf '\t"touser":"'$userid'",\n'
    printf '\t"toparty":"'$partyid'",\n'
    printf '\t"msgtype":"text",\n'
    printf '\t"agentid":"'$Agentid'",\n'
    printf '\t"text":{\n'
    printf '\t"content":"'$msg'",\n'
    printf '\t},\n'
    printf '\t"safe":"0",\n'
    printf '}\n'
}
curl -d "$(comment $1 $2 $3)" $purl

