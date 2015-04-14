FROM qnib/slurmd
MAINTAINER "Christian Kniep <christian@qnib.org>"

# Install dependencies
RUN echo "2015-04-14.1";yum clean all;yum install -y openmpi-devel
# Application libs
RUN yum install -y gsl libgomp

RUN echo "source /etc/profile" >> /etc/bashrc
RUN echo "module load mpi" >> /etc/bashrc

# Stress
#RUN yum install -y stress

# ADD source code
ADD opt/qnib/src/hello_mpi.c /opt/qnib/src/
