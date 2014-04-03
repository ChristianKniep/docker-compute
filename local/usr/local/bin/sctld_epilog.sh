#!/bin/bash

/bin/send_event.py --server graphite -t "job${SLURM_JOBID},epilog" "Epilog for job ${SLURM_JOBID} triggered"

