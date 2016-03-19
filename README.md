docker-compute
==============

Docker image to spawn a compute node running slurmd (+munge), diamond (metric-gathering), sshd, supervisord, logstash-forwarder


### MPI HelloWorld

To fire up a small mpi script one needs

- consul to bound tem all together (DNS wise and in regards of the slurm.conf)
- slurmctld as master
- at least to slurmd to have a cluster (otherwise it would be only one :)

##### fig

The fig file within this directory holds exactly this.

```
consul:
    image: qnib/consul
    *snip*

slurmctld:
    image: qnib/slurmctld
    *snip*

compute:
    # inherits from qnib/slurmd
    image: qnib/compute
    *snip*
```

Let's fire it up and scale the nodes to 2.

```
➜  docker-compute git:(master) docker-compose up -d                                                                                                                                                                                                                                                                                      git:(master|)
Creating dockercompute_consul_1
Creating dockercompute_slurmctld_1
Creating dockercompute_compute_1
➜  docker-compute git:(master) docker-compose scale compute=5                                                                                                                                                                                                                                                                            git:(master|)
Creating and starting 2 ... done
Creating and starting 3 ... done
Creating and starting 4 ... done
Creating and starting 5 ... done
➜  docker-compute git:(master)
```

Now we connect to the first node.

```
$ docker exec -ti dockercompute_compute_1 bash
[root@1df2666e8a45 /]#
```

After some time sinfo should show all nodes. The names are random, because I use the scale feature of fig (docker-compose), which 
is not able to use different hostnames (as to my knowledge).

```
# sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
all*         up   infinite      5   idle 0de19bd8d851,4e29f3aa87c5,5fe0838dcbf4,8ecf49402404,954c9649bacc
odd          up   infinite      3   idle 0de19bd8d851,4e29f3aa87c5,954c9649bacc
even         up   infinite      2   idle 5fe0838dcbf4,8ecf49402404
```

### mpi the thing

Now we compile the little mpi program `hello_mpi.c`.
```
# mpicc -o /scratch/hello_mpi /opt/qnib/src/hello_mpi.c
# mpirun -n 1 /scratch/hello_mpi
Process 0 on 1df2666e8a45 out of 1
```

To run it in parallel SLURM comes to the rescue and provides all the environment needed, we just have to run it.

```
# salloc -N2 bash
salloc: Granted job allocation 2
# mpirun /scratch/hello_mpi
Process 7 on cdf11fef8b1e out of 8
Process 4 on cdf11fef8b1e out of 8
Process 6 on cdf11fef8b1e out of 8
Process 5 on cdf11fef8b1e out of 8
Process 3 on 647c9ef10a16 out of 8
Process 2 on 647c9ef10a16 out of 8
Process 0 on 647c9ef10a16 out of 8
Process 1 on 647c9ef10a16 out of 8
```

Or even easier....

```
#
srun -N5 mpirun /scratch/hello_mpi
Process 0 on 8ecf49402404 out of 5
Process 4 on 954c9649bacc out of 5
Process 2 on 4e29f3aa87c5 out of 5
Process 1 on 0de19bd8d851 out of 5
Process 3 on 5fe0838dcbf4 out of 5
Process 4 on 954c9649bacc out of 5
Process 1 on 0de19bd8d851 out of 5
Process 2 on 4e29f3aa87c5 out of 5
Process 3 on 8ecf49402404 out of 5
Process 0 on 5fe0838dcbf4 out of 5
Process 3 on 8ecf49402404 out of 5
Process 1 on 4e29f3aa87c5 out of 5
Process 0 on 0de19bd8d851 out of 5
Process 2 on 5fe0838dcbf4 out of 5
Process 4 on 954c9649bacc out of 5
Process 0 on 954c9649bacc out of 5
Process 4 on 8ecf49402404 out of 5
Process 2 on 4e29f3aa87c5 out of 5
Process 3 on 5fe0838dcbf4 out of 5
Process 1 on 0de19bd8d851 out of 5
Process 0 on 4e29f3aa87c5 out of 5
Process 2 on 5fe0838dcbf4 out of 5
Process 1 on 0de19bd8d851 out of 5
Process 3 on 8ecf49402404 out of 5
Process 4 on 954c9649bacc out of 5
#
```
