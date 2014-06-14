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

ADD etc/supervisord.d/confd_update_slurm.ini /etc/supervisord.d/confd_update_slurm.ini
RUN touch /usr/local/etc/slurm.conf

RUN echo "source /etc/profile" >> /etc/bashrc
RUN echo "module load mpi" >> /etc/bashrc

CMD /bin/supervisord -c /etc/supervisord.conf
