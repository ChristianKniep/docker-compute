###### compute node
# runs slurmd, sshd and is able to execute jobs via mpi
FROM qnib/terminal
MAINTAINER "Christian Kniep <christian@qnib.org>"

##### USER
# Set (very simple) password for root
RUN echo "root:root"|chpasswd
ADD root/ssh /root/.ssh
RUN chmod 600 /root/.ssh/authorized_keys
RUN chown -R root:root /root/*

# cluser
RUN mkdir -p /chome
RUN useradd -u 2000 -d /chome/cluser -m cluser
RUN echo "cluser:cluser"|chpasswd
ADD cluser/.ssh /chome/cluser/.ssh
RUN chmod 600 /chome/cluser/.ssh/authorized_keys
RUN chmod 600 /chome/cluser/.ssh/id_rsa
RUN chmod 644 /chome/cluser/.ssh/id_rsa.pub
RUN chown cluser -R /chome/cluser

# Install dependencies
RUN yum install -y openmpi

# munge
RUN yum install -y munge
RUN chown root:root /var/lib/munge/
RUN chown root:root /var/log/munge/
RUN chown root:root /run/munge/
RUN chown root:root /etc/munge/
ADD etc/munge/munge.key /etc/munge/munge.key
RUN chmod 600 /etc/munge/munge.key
RUN chown root:root /etc/munge/munge.key
ADD etc/supervisord.d/munge.ini /etc/supervisord.d/

# Put slurm-rpm
ADD yum-cache/slurm /tmp/yum-cache/slurm
RUN rpm -i /tmp/yum-cache/slurm/slurm-2.6.7-1.x86_64.rpm
RUN useradd -u 2001 -d /chome/slurm -m slurm
RUN rm -rf /tmp/yum-cache/slurm
ADD usr/local/etc/slurm.conf /usr/local/etc/slurm.conf
ADD root/bin/start_slurmd.sh /root/bin/start_slurmd.sh
ADD etc/supervisord.d/slurmd.ini /etc/supervisord.d/slurmd.ini

### SSHD
RUN yum install -y openssh-server
RUN mkdir -p /var/run/sshd
RUN sshd-keygen
RUN sed -i -e 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
ADD root/ssh /root/.ssh/
ADD etc/supervisord.d/sshd.ini /etc/supervisord.d/sshd.ini


# Application libs
RUN yum install -y gsl libgomp

# We do not care about the known_hosts-file
RUN echo "        StrictHostKeyChecking no" >> /etc/ssh/ssh_config
RUN echo "        UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config
RUN echo "        AddressFamily inet" >> /etc/ssh/ssh_config

## confd
# bc needed within /root/bin/confd_update_slurm.sh
RUN yum install -y bc bind-utils
ADD usr/local/bin/confd /usr/local/bin/confd
ADD etc/confd/conf.d/slurm.conf.toml /etc/confd/conf.d/slurm.conf.toml
ADD etc/confd/templates/slurm.conf.tmpl /etc/confd/templates/slurm.conf.tmpl
ADD root/bin/confd_update_slurm.sh /root/bin/confd_update_slurm.sh
ADD root/bin/wait_timeout.sh /root/bin/wait_timeout.sh
ADD etc/supervisord.d/confd_update_slurm.ini /etc/supervisord.d/confd_update_slurm.ini

ADD usr/local/bin/gemm_block_mpi_50ms /usr/local/bin/
ADD usr/local/bin/gemm_block_mpi_250ms /usr/local/bin/
ADD usr/local/bin/gemm_block_mpi_500ms /usr/local/bin/
ADD usr/local/bin/gemm.sh /usr/local/bin/gemm.sh
CMD /bin/supervisord -c /etc/supervisord.conf
