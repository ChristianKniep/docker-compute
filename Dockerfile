FROM qnib/slurmd
MAINTAINER "Christian Kniep <christian@qnib.org>"

# Install dependencies
RUN yum install -y mpich openmpi
# Application libs
RUN yum install -y gsl libgomp

RUN echo "source /etc/profile" >> /etc/bashrc
RUN echo "module load mpi:openmpi" >> /etc/bashrc

# Stress
#RUN yum install -y stress
