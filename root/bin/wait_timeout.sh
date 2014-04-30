#!/bin/bash


function fetch_value {
   KEY=$(echo "/${1}"|sed -e 's#//#/#g')
   VALUE=$(curl -s -4 -L http://etcd:4001/v2/keys${KEY}| python -mjson.tool|grep value|head -n1)
   RESULT=$(echo ${VALUE}|awk -F\: '{print $2}'|sed -s 's/"//g'|sed -e 's/ //g')
   if [ "X${RESULT}" == "X" ];then
      return 1
   fi
   echo ${RESULT}
}

## MAIN
fetch_value $1
