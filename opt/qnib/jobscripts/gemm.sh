#!/bin/bash
KVAL=${1-16384}
SLEEP=${2-250}
JOBID=${SLURM_JOBID}
NLIST=${SLURM_NODELIST}
START_TIME=$(date +%s)
CMD="/opt/qnib/bin/gemm_block_mpi_${SLEEP}ms -K ${KVAL}"
logger -t slurm_out  "Job ${JOBID} starts. K:${KVAL}"
echo "####################################################"
echo "################ JOBRUN ############################"
echo "####################################################"
mpirun -q ${CMD}
echo "####################################################"
echo "################ \JOBRUN ############################"
echo "####################################################"
WTIME=$(echo "$(date +%s) - ${START_TIME}"|bc)
logger -t slurm_out "Job ${JOBID} ends K:${KVAL}; wall:${WTIME}"
