#!/bin/bash

echo "### Fetch MASTER_IP"
MASTER_IP=$(cat /etc/resolv.conf |grep nameserver|head -n1|awk '{print $2}')
echo "MASTER_IP=${MASTER_IP}"
export no_proxy=${MASTER_IP}
echo "### Fetch MY_IP"
MY_IP=$(ip -o -4 addr|grep eth0|awk '{print $4}'|awk -F/ '{print $1}')
echo "MY_IP=${MY_IP}"
echo "### Send IP to etcd"
echo "# curl -s -XPUT http://${MASTER_IP}:4001/v2/keys/helix/$(hostname)/A -d value=${MY_IP}"
curl -s -XPUT http://${MASTER_IP}:4001/v2/keys/helix/$(hostname)/A -d value="${MY_IP}"
MY_PTR=$(echo ${MY_IP}|sed -e 's#\.#/#g')
echo "MY_IP=${MY_IP}"
echo "### Send IP to etcd"
echo "# curl -s -XPUT http://${MASTER_IP}:4001/v2/keys/helix/arpa/in-addr/${MY_PTR}/PTR -d value=$(hostname)."
curl -s -XPUT http://${MASTER_IP}:4001/v2/keys/helix/arpa/in-addr/${MY_PTR}/PTR -d value="$(hostname)."

exit 0
