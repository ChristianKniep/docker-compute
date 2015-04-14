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
$ fig up -d
Creating dockercompute_consul_1...
Creating dockercompute_slurmctld_1...
Creating dockercompute_compute_1...
$ fig scale compute=2
Starting dockercompute_compute_2...
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
qnib*        up   infinite      2   idle 1df2666e8a45,f8d22e88943a
```

### mpi the thing

Now we compile the little mpi program `hello_mpi.c`.
```
# mpicc -o /chome/cluser/hello_mpi /opt/qnib/src/hello_mpi.c
# mpirun -n 1 /chome/cluser/hello_mpi
Process 0 on 1df2666e8a45 out of 1
```

To run it in parallel SLURM comes to the rescue and provides all the environment needed, we just have to run it.

```
# salloc -N2 bash
salloc: Granted job allocation 2
# mpirun /chome/cluser/hello_mpi
Process 7 on cdf11fef8b1e out of 8
Process 4 on cdf11fef8b1e out of 8
Process 6 on cdf11fef8b1e out of 8
Process 5 on cdf11fef8b1e out of 8
Process 3 on 647c9ef10a16 out of 8
Process 2 on 647c9ef10a16 out of 8
Process 0 on 647c9ef10a16 out of 8
Process 1 on 647c9ef10a16 out of 8
```
