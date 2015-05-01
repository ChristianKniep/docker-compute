#!/bin/bash
#SBATCH --job-name=GeMM
#SBATCH --workdir=/scratch/
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err

KVAL=${1-16384}
SLEEP=${2-250}
ERR_NODE=${3-noerrornode}
JOBID=${SLURM_JOBID}
NLIST=${SLURM_NODELIST}
START_TIME=$(date +%s)
NODES=$(python -c "from ClusterShell.NodeSet import NodeSet;print ' '.join(NodeSet('${SLURM_NODELIST}'))")
CMD="/opt/qnib/bin/gemm_block_mpi_${SLEEP}ms -K ${KVAL}"
logger -t slurm_${JOBID}  "Job ${JOBID} starts. K:${KVAL}"
echo "####################################################"
echo "################ JOBRUN ############################"
echo "####################################################"
logger -t slurm_${JOBID}  "mpirun -q ${CMD}"
if [ $(echo ${NODES}|grep -c ${ERR_NODE}) -ne 0 ];then
    # let job fail after 30sec
    sleep 30
    logger -t slurm_${JOBID}  "Job failed (tell you a secret: due to error node trigger)"
    exit 42
fi
mpirun -q ${CMD}
echo "####################################################"
echo "################ \JOBRUN ############################"
echo "####################################################"
WTIME=$(echo "$(date +%s) - ${START_TIME}"|bc)
logger -t slurm_${JOBID} "Job ${JOBID} ends K:${KVAL}; wall:${WTIME}"
exit 0
