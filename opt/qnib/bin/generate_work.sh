#!/bin/bash
users=(alice bob carol dave eve john jane)
nodes=$(scontrol show partition|egrep -o "TotalNodes=[0-9]+"|head -n1|egrep -o "[0-9]+")
for x in {1..10};do
    num=$(shuf -i 2-${nodes} -n 1)
    user=${users[$[ $RANDOM % ${#users[@]} ]]}
    echo ">> su -c 'sbatch -N${num} /opt/qnib/jobscripts/ping_pong.sh' ${user}"
    su -c "sbatch -N${num} /opt/qnib/jobscripts/ping_pong.sh" ${user}
done
