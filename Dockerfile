###### compute node
# runs slurmd, sshd and is able to execute jobs via mpi
FROM qnib/slurm
MAINTAINER "Christian Kniep <christian@qnib.org>"

# Install dependencies
RUN yum install -y openmpi

# slurmd
ADD root/bin/start_slurmd.sh /root/bin/start_slurmd.sh
ADD etc/supervisord.d/slurmd.ini /etc/supervisord.d/slurmd.ini

# Application libs
RUN yum install -y gsl libgomp

ADD usr/local/bin/gemm_block_mpi_50ms /usr/local/bin/
ADD usr/local/bin/gemm_block_mpi_250ms /usr/local/bin/
ADD usr/local/bin/gemm_block_mpi_500ms /usr/local/bin/
ADD usr/local/bin/gemm.sh /usr/local/bin/gemm.sh
ADD etc/supervisord.d/confd_update_slurm.ini /etc/supervisord.d/confd_update_slurm.ini

CMD /bin/supervisord -c /etc/supervisord.conf
