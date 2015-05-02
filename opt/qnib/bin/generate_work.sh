#!/bin/bash
gem_delays=(50 250 500)
gem_ks=(32768 65536)
nodelist=($(scontrol show partition=all|grep " Nodes"|awk -F\= '{print $2}'|sed -e 's/,/ /g'))
rand_node=${nodelist[$[ $RANDOM % ${#nodelist[@]} ]]}
err_node=${2-${rand_node}}
users=(alice bob carol dave eve john jane)
nodes=$(scontrol show partition|egrep -o "TotalNodes=[0-9]+"|head -n1|egrep -o "[0-9]+")
sjobs=(ping_pong gemm)
for x in $(seq 1 ${1-5});do
    num=$(shuf -i 2-${3-${nodes}} -n 1)
    user=${users[$[ $RANDOM % ${#users[@]} ]]}
    if [ "X${2}" == "X" ];then
        job=${sjobs[$[ $RANDOM % ${#sjobs[@]} ]]}
    else
        job=${2}
    fi
    if [ ${job} == "gemm" ];then
        gem_k=${gem_ks[$[ $RANDOM % ${#gem_ks[@]} ]]}
        gem_delay=${gem_delays[$[ $RANDOM % ${#gem_delays[@]} ]]}
        exp=$(shuf -i 1-$(echo "sqrt(${nodes})"|bc) -n 1)
        num=$(echo "2^${exp}"|bc)
        echo ">> su -l -c 'sbatch -N${num} /opt/qnib/jobscripts/gemm.sh ${gem_delay} ${gem_k} ${err_node}' ${user}"
        su -l -c "sbatch -N${num} /opt/qnib/jobscripts/gemm.sh" ${user}
    else
        echo ">> su -l -c 'sbatch -N${num} /opt/qnib/jobscripts/ping_pong.sh ${err_node}' ${user}"
        su -l -c "sbatch -N${num} /opt/qnib/jobscripts/ping_pong.sh" ${user}
    fi
done
