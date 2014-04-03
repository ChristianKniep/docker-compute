#!/bin/bash

env > /scratch/prolog_job${SLURM_JOBID}.env
/bin/send_event.py --server graphite -t "job${SLURM_JOBID},prolog" "Prolog for job ${SLURM_JOBID} triggered"
