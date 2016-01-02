#!/bin/bash

if [ "X${SENSU_CEHCK_IB}" != "Xtrue" ];then
    rm -f /etc/sensu/conf.d/check_ib.json   
fi
