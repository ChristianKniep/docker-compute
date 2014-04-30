#!/bin/bash
SLEEP="250"
KVAL=${1-16384}
JOBID=${SLURM_JOBID}
NLIST=${SLURM_NODELIST}
CMD="/usr/local/bin/gemm_block_mpi_${SLEEP}ms -K ${KVAL}"
send_event.py --server graphite \
              -t "job${JOBID},start,k${KVAL}" \
              -d "NODES: ${NLIST} CMD: ${CMD}" \
              "Job ${JOBID} starts. K:${KVAL}"
echo "####################################################"
echo "################ JOBRUN ############################"
echo "####################################################"
mpirun -q ${CMD}
echo "####################################################"
echo "################ \JOBRUN ############################"
echo "####################################################"
send_event.py --server graphite \
              -t "job${JOBID},end,k${KVAL}" \
              -d "Some more info" \
              "Job ${JOBID} ends K:${KVAL}"
