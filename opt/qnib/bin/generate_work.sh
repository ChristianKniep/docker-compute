#!/bin/bash
users=(alice bob carol dave eve john jane)
nodes=$(scontrol show partition|egrep -o "TotalNodes=[0-9]+"|head -n1|egrep -o "[0-9]+")
sjobs=(ping_pong gemm)
for x in $(seq 1 ${1-5});do
    num=$(shuf -i 2-${nodes} -n 1)
    user=${users[$[ $RANDOM % ${#users[@]} ]]}
    if [ "X${2}" == "X" ];then
        job=${sjobs[$[ $RANDOM % ${#sjobs[@]} ]]}
    else
        job=${2}
    fi
    if [ ${job} == "gemm" ];then
        exp=$(shuf -i 1-$(echo "sqrt(${nodes})"|bc) -n 1)
        num=$(echo "2^${exp}"|bc)
        echo ">> su -c 'sbatch -N${num} /opt/qnib/jobscripts/gemm.sh' ${user}"
        su -c "sbatch -N${num} /opt/qnib/jobscripts/gemm.sh" ${user}
    else
        echo ">> su -c 'sbatch -N${num} /opt/qnib/jobscripts/ping_pong.sh' ${user}"
        su -c "sbatch -N${num} /opt/qnib/jobscripts/ping_pong.sh" ${user}
    fi
done
