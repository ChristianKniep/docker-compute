###### compute node
# runs slurmd, sshd and is able to execute jobs via mpi
FROM qnib/fd20:bull
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

## supervisord
RUN yum install -y supervisor
RUN mkdir -p /var/log/supervisor
RUN sed -i -e 's/nodaemon=false/nodaemon=true/' /etc/supervisord.conf

# Install dependencies
RUN yum install -y openmpi munge

# Put slurm-rpm
ADD rpms/slurm-2.6.7-1.x86_64.rpm /tmp/
RUN rpm -i /tmp/slurm-2.6.7-1.x86_64.rpm
RUN useradd -u 2001 -d /chome/slurm -m slurm

RUN chown root:root /var/lib/munge/
RUN chown root:root /var/log/munge/
RUN chown root:root /run/munge/
RUN chown root:root /etc/munge/
ADD etc/munge/munge.key /etc/munge/munge.key
RUN chmod 600 /etc/munge/munge.key
RUN chown root:root /etc/munge/munge.key
ADD etc/supervisord.d/slurmd.ini /etc/supervisord.d/slurmd.ini
### SSHD
RUN yum install -y openssh-server
RUN mkdir -p /var/run/sshd
RUN sshd-keygen
RUN sed -i -e 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
ADD root/ssh /root/.ssh/
ADD etc/supervisord.d/sshd.ini /etc/supervisord.d/sshd.ini
ADD root/bin /root/bin
ADD etc/supervisord.d/setup.ini /etc/supervisord.d/setup.ini

# Diamond
RUN yum install -y python-configobj
ADD rpms /tmp/rpms
RUN yum install -y /tmp/rpms/python-pysensors-*
RUN yum install -y /tmp/rpms/python-diamond-*
RUN rm -rf /etc/diamond
ADD etc/diamond /etc/diamond
RUN mkdir -p /var/log/diamond
ADD etc/supervisord.d/diamond.ini /etc/supervisord.d/diamond.ini

# carboniface
RUN yum install -y python-docopt
ADD yum-cache/carboniface /tmp/yum-cache/carboniface
RUN yum install -y /tmp/yum-cache/carboniface/python-carboniface-*
RUN rm -rf /tmp/yum-cache/carboniface

# Application libs
RUN yum install -y gsl libgomp

# rsyslog
RUN yum install -y syslog-ng
ADD etc/syslog-ng/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf
ADD etc/supervisord.d/syslog-ng.ini /etc/supervisord.d/

# tidy up
RUN rm -rf /tmp/rpms

# We do not care about the known_hosts-file
RUN echo "        StrictHostKeyChecking no" >> /etc/ssh/ssh_config
RUN echo "        UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config
RUN echo "        AddressFamily inet" >> /etc/ssh/ssh_config
# Solution for 'ping: icmp open socket: Operation not permitted'
RUN chmod u+s /usr/bin/ping
RUN ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime 

CMD /bin/supervisord -c /etc/supervisord.conf
