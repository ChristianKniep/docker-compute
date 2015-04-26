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

ADD opt/qnib/jobscripts/ /opt/qnib/jobscripts/
ADD opt/qnib/bin/gemm_block_mpi_50ms /opt/qnib/bin/
ADD opt/qnib/bin/gemm_block_mpi_250ms /opt/qnib/bin/
ADD opt/qnib/bin/gemm_block_mpi_500ms /opt/qnib/bin/
ADD opt/qnib/bin/generate_work.sh /opt/qnib/bin/generate_work.sh
