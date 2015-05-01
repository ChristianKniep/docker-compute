#!/bin/bash
#SBATCH --job-name=PingPong
#SBATCH --workdir=/scratch/
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err
#SBATCH --ntasks-per-node=1

ERR_NODE=${1-noerrornode}
mkdir -p /scratch/${SLURM_JOBID}/
cd /scratch/${SLURM_JOBID}/
DOMAIN=node.consul
BW_LIMIT=3000
NODES=$(python -c "from ClusterShell.NodeSet import NodeSet;print ' '.join(NodeSet('${SLURM_NODELIST}'))")
for node in ${NODES};do
    if [ ${node} == ${ERR_NODE} ];then
        logger -t slurm_${JOBID}  "Job failed (tell you a secret: due to error node trigger)"
        exit 42
    fi
    if [ ${node} != ${SLURMD_NODENAME} ];then
        logger --tag slurm_${SLURM_JOBID} "fallocate -l 60M /tmp/test_${SLURM_JOBID}.dd"
        srun --exclusive -n1 fallocate -l 60M /tmp/test_${SLURM_JOBID}.dd
        sleep 15
        logger --tag slurm_${SLURM_JOBID} "mkdir -p /scratch/${SLURM_JOBID}/"
        mkdir -p /scratch/${SLURM_JOBID}/
        sleep 15
        logger --tag slurm_${SLURM_JOBID} "rsync --bwlimit=${BW_LIMIT} -aP /tmp/test_${SLURM_JOBID}.dd ${node}.${DOMAIN}:/scratch/${SLURM_JOBID}/"
        srun --exclusive -n1 rsync --bwlimit=${BW_LIMIT} -aP /tmp/test_${SLURM_JOBID}.dd ${node}.${DOMAIN}:/scratch/${SLURM_JOBID}/
        logger --tag slurm_${SLURM_JOBID} "Delete local file and file within /scratch/${SLURM_JOBID}/"
        srun --exclusive -n1 rm -f /scratch/${SLURM_JOBID}/test_${SLURM_JOBID}.dd /tmp/test_${SLURM_JOBID}.dd
        sleep 15
    fi
done
exit 0
