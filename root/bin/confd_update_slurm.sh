#!/bin/bash

DAEMON=$(/bin/supervisorctl status|grep ^slurm|awk '{print $1}')

function fetch_value {
   KEY=$(echo "/${1}"|sed -e 's#//#/#g')
   VALUE=$(curl -s -4 -L http://etcd:4001/v2/keys${KEY}| python -mjson.tool|grep value|head -n1)
   RESULT=$(echo ${VALUE}|awk -F\: '{print $2}'|sed -s 's/"//g'|sed -e 's/ //g')
   if [ "X${RESULT}" == "X" ];then
      return 1
   fi
   echo ${RESULT}
}

function update_slurm {
   # since ipv6 messes with confd resolve the IP
   ETCD_IP=$(dig etcd +short)
   confd -node=http://${ETCD_IP}:4001 -onetime -config-file=/etc/confd/conf.d/slurm.conf.toml
   FILE_TS=$(date --utc --reference=/usr/local/etc/slurm.conf +%s)
   echo "RESTART ${DAEMON}"
   /bin/supervisorctl restart ${DAEMON}
}


FILE_TS=$(date --utc --reference=/usr/local/etc/slurm.conf +%s)
UPDATE_TS=$(fetch_value /slurm/conf/last_update)
if [ ${FILE_TS} -lt ${UPDATE_TS} ];then
   update_slurm
fi

while [ true ];do
   UPDATE_TS=$(/bin/timeout 1m /root/bin/wait_timeout.sh /slurm/conf/last_update?wait=true)
   if [ "X${UPDATE_TS}" == "X" ];then
      UPDATE_TS=$(fetch_value /slurm/conf/last_update)
   fi
   sleep 5
   CHECK_UPDATE_TS=$(fetch_value /slurm/conf/last_update)
   if [ ${UPDATE_TS} -eq ${CHECK_UPDATE_TS} ];then
      if [ ${FILE_TS} -lt ${UPDATE_TS} ];then
         echo "FILE_TS:${FILE_TS} < ${UPDATE_TS}:UPDATE_TS"
         update_slurm
      fi
   fi
done
