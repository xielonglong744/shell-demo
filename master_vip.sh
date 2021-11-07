#!/bin/bash

###############################
#                             #
#  配置master node节点ip      #
#                             #
###############################
export MASTER_IP=(192.168.28.98 192.168.28.45 192.168.28.50)
export NODE_IP=(192.168.28.52 192.168.28.61 192.168.28.62)
export OLD_VIP=192.168.28.109
export NEW_VIP=192.168.28.108
export DIR_CERT=/root/pki

###############################
#                             #
#   重新生成apiserver.crt     #
#                             #
###############################
create_apiserver(){
EXTRA_SANS=(
    IP:$1
    IP:10.96.0.1
    IP:$NEW_VIP
    DNS:api.k8s.io
    DNS:${HOSTNAME}
    DNS:kubernetes
    DNS:kubernetes.default
    DNS:kubernetes.default.svc
    DNS:kubernetes.default.svc.cluster.local
  )

SANS=$(echo "${EXTRA_SANS[@]}" | tr ' ' ,)

echo subjectAltName = $SANS  > extfile.cnf
openssl req -new -key apiserver.key -nodes -days 3650 -out apiserver-req -subj "/CN=kube-apiserver"
openssl x509 -req -days 3650 -in apiserver-req -CA ca.crt -CAkey ca.key \
        -CAcreateserial -out apiserver.crt -extfile extfile.cnf
rm -rf extfile.cnf ca.srl apiserver-req
}

#################################
#                               #
#   重新生成etcd的server.crt    #
#                               #
#################################
create_etcd_server(){
EXTRA_SANS=(
    IP:$1
    IP:$NEW_VIP
    IP:127.0.0.1
    IP:10.96.0.1
    IP:0:0:0:0:0:0:0:1
    DNS:api.k8s.io
    DNS:${HOSTNAME}
    DNS:localhost
  )

SANS=$(echo "${EXTRA_SANS[@]}" | tr ' ' ,)
echo subjectAltName = $SANS  > extfile.cnf
openssl req -new -key server.key -nodes -days 3650 -out server-req -subj "/CN=etcd-ca"
openssl x509 -req -days 3650 -in server-req -CA ca.crt -CAkey ca.key \
        -CAcreateserial -out server.crt -extfile extfile.cnf
rm -rf extfile.cnf ca.srl server-req
}

#################################
#                               #
#   重新生成etcd的peer.crt      #
#                               #
#################################
create_etcd_peer(){
EXTRA_SANS=(
    IP:$1
    IP:127.0.0.1
    IP:0:0:0:0:0:0:0:1
    DNS:${HOSTNAME}
    DNS:localhost
  )

SANS=$(echo "${EXTRA_SANS[@]}" | tr ' ' ,)
echo subjectAltName = $SANS  > extfile.cnf
openssl req -new -key peer.key -nodes -days 3650 -out peer-req -subj "/CN=etcd-ca"  
openssl x509 -req -days 3650 -in peer-req -CA ca.crt -CAkey ca.key \
        -CAcreateserial -out peer.crt -extfile extfile.cnf
rm -rf extfile.cnf ca.srl peer-req
}

#################################
#                               #
#   替换配置master节点证书      #
#                               #
#################################
for i in ${MASTER_IP[*]}
do
if [ "$i" == "192.168.28.98" ];then
    export HOSTNAME=v41-master1
fi
if [ "$i" == "192.168.28.45" ];then
    export HOSTNAME=v41-master2
fi
if [ "$i" == "192.168.28.50" ];then
    export HOSTNAME=v41-master3
fi

ssh root@$i > /dev/null 2>&1 << EOF
if [ -d "/root/certs" ];then
   rm -rf /root/certs
fi
mkdir -p /root/k8s/pki
cp -rfp /etc/kubernetes/  /root/certs/

sed -i "s/${OLD_VIP}/${NEW_VIP}/g" /etc/kubernetes/*.conf
sed -i "s/${OLD_VIP}/${NEW_VIP}/g" /etc/kubernetes/keepalived.env
EOF

if [ -d "$DIR_CERT" ];then
   rm -rf /root/pki
fi

mkdir -p $DIR_CERT
mkdir -p $DIR_CERT/etcd
scp root@$i:/etc/kubernetes/pki/ca.*  $DIR_CERT/
scp root@$i:/etc/kubernetes/pki/apiserver.key  $DIR_CERT/
scp -r root@$i:/etc/kubernetes/pki/etcd/*  $DIR_CERT/etcd
cd $DIR_CERT/
create_apiserver $i
scp apiserver.crt root@$i:/etc/kubernetes/pki/
cd etcd/
rm -rf server.crt peer.crt
create_etcd_server $i
scp server.crt root@$i:/etc/kubernetes/pki/etcd/
create_etcd_peer $i
scp peer.crt root@$i:/etc/kubernetes/pki/etcd/

done

#################################
#                               #
#   替换完证书后重启master节点  #
#                               #
#################################

for i in ${MASTER_IP[*]}
do 
ssh root@$i >/dev/null 2>&1 << EOF
reboot
EOF
done

#################################
#                               #
#   修改配置node节点            #
#                               #
#################################
for i in ${NODE_IP[*]}
do
ssh root@$i > /dev/null 2>&1 << EOF
if [ -d "/root/certs" ]; then
    rm -rf /root/certs
fi
mkdir  -p /root/certs
cp -fpr /etc/kubernetes/*  /root/certs/
sed -i "s/${OLD_VIP}/${NEW_VIP}/g" /etc/kubernetes/kubelet.conf
systemctl restart kubelet
EOF
done

#################################
#                               #
#   master节点重启后修改        #
#   calico和kube-proxy          #
#   配置及重启相应的pod         #
#                               #
#################################
for i in ${MASTER_IP[*]}
do
while true
do
sleep 10
nc -z -w 10 $i 22  >/dev/null  2>&1
if [ $? == 0 ];then
ssh  root@$i >/dev/null 2>&1 << EOF
sleep 120
if [ -f "/root/calico-config.yaml" ];then  
     rm -rf /root/calico-config 
fi
if [ -f "/root/kube-proxy.yaml" ];then
    rm -rf /root/kube-proxy
fi
kubectl get cm calico-config -n kube-system -o yaml > /root/calico-config.yaml
sed -i -e "/creationTime/d"  -e "/resourceVersion/d" -e "/uid/d" -e "s/${OLD_VIP}/${NEW_VIP}/g" /root/calico-config.yaml
kubectl get cm kube-proxy -n kube-system -o yaml > /root/kube-proxy.yaml
sed -i -e "/creationTime/d"  -e "/resourceVersion/d" -e "/uid/d" -e "s/${OLD_VIP}/${NEW_VIP}/g" /root/kube-proxy.yaml
kubectl delete -f /root/kube-proxy.yaml
kubectl apply -f /root/kube-proxy.yaml
kubectl delete -f /root/calico-config.yaml
kubectl apply -f /root/calico-config.yaml
nohup kubectl get pods -n kube-system | egrep "calico-node|kube-proxy|kube-controller" |awk '{print $1}' |xargs kubectl delete pods -n kube-system &
sleep 30
EOF
break
fi
done
break
done
