FROM nvidia/cuda:11.2.0-devel

ENV DEBIAN_FRONTEND=noninteractive

# User directory
ENV USER=user
ENV HOME=/home/user
RUN mkdir -p /home/user

# Fix invalid CUDA keys
RUN rm /etc/apt/sources.list.d/cuda.list
RUN rm /etc/apt/sources.list.d/nvidia-ml.list

# GNU compiler
RUN apt-get update -y && \
    apt install -y --no-install-recommends software-properties-common && \
    add-apt-repository ppa:ubuntu-toolchain-r/ppa

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends\
    file \
    g++ \
    gcc \
    gcc-9 \
    g++-9 \
    gfortran \
    libgfortran4 \
    libgomp1 \
    make \
    gdb \
    strace \
    wget \
    ca-certificates \
    openssh-client \
    openssh-server && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Install CUDA-aware OpenMPI
RUN wget -q https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.4.tar.gz && \
    tar xf openmpi-4.1.4.tar.gz && \
    cd openmpi-4.1.4 && \
    ./configure --disable-fortran --enable-fast=all,O3 --prefix=/usr/local --with-cuda=/usr/local/cuda && \
    make -j$(nproc) && \
    make install &&\
    ldconfig && \
    rm ../openmpi-4.1.4.tar.gz

# Install SSH for running MPI
RUN apt-get install -y openssh-client openssh-server

RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp http://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-5.7.tar.gz && \
    mkdir -p /var/tmp && tar -x -f /var/tmp/osu-micro-benchmarks-5.7.tar.gz -C /var/tmp -z && \
    cd /var/tmp/osu-micro-benchmarks-5.7 && CC=mpicc CXX=mpicxx ./configure --prefix=/usr/local/osu --enable-cuda --with-cuda=/usr/local/cuda && \
    make -j$(nproc) && \
    make -j$(nproc) install && \
    rm -rf /var/tmp/osu-micro-benchmarks-5.7 /var/tmp/osu-micro-benchmarks-5.7.tar.gz

ENV PATH=/usr/local/osu/libexec/osu-micro-benchmarks:/usr/local/osu/libexec/osu-micro-benchmarks/mpi/collective:/usr/local/osu/libexec/osu-micro-benchmarks/mpi/one-sided:/usr/local/osu/libexec/osu-micro-benchmarks/mpi/pt2pt:/usr/local/osu/libexec/osu-micro-benchmarks/mpi/startup:$PATH


###########################################################
###########################################################
###########################################################
###########################################################


ENV PATH=/usr/local/osu/libexec/osu-micro-benchmarks:/usr/local/osu/libexec/osu-micro-benchmarks/mpi/collective:/usr/local/osu/libexec/osu-micro-benchmarks/mpi/one-sided:/usr/local/osu/libexec/osu-micro-benchmarks/mpi/pt2pt:/usr/local/osu/libexec/osu-micro-benchmarks/mpi/startup:$PATH

# Linux tooling 
RUN apt-get update -y &&\
    apt install -y --no-install-recommends\
    nano \
    tar \
    wget && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# gcc, git, && python

RUN apt-get update -y && \
    apt install -y --no-install-recommends \
    git \
    python \
    python3.8 \
    python3.8-dev &&\
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean


# Fix python && gcc default bin to point to the version we need
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.8 60
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 60
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 60
RUN python --version
RUN gcc --version
RUN g++ --version

# CMake version 3.18.3
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    make \
    wget && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp https://github.com/Kitware/CMake/releases/download/v3.18.3/cmake-3.18.3-Linux-x86_64.sh && \
    mkdir -p /usr/local && \
    /bin/sh /var/tmp/cmake-3.18.3-Linux-x86_64.sh --prefix=/usr/local --skip-license && \
    rm -rf /var/tmp/cmake-3.18.3-Linux-x86_64.sh
ENV PATH=/usr/local/bin:$PATH

#PIP
# Get a random py3 pip then upgrade it to latest (same for setuptools & wheel)
RUN apt-get update -y &&\
    apt install -y --no-install-recommends\
    python3-pip

RUN python -m pip --no-cache-dir install --upgrade pip && \
    python -m pip --no-cache-dir install setuptools &&\
    python -m pip --no-cache-dir install wheel

# Py default packages
RUN python -m pip --no-cache-dir install \
    install \
    kiwisolver \
    numpy \
    matplotlib \
    cupy-cuda112 \
    Cython \
    h5py \
    six \
    zipp \
    pytest \
    pytest-profiling \
    pytest-subtests \
    pytest-regressions \
    hypothesis \
    gitpython \
    clang-format \
    gprof2dot \
    cftime \
    f90nml \
    pandas \
    pyparsing \
    python-dateutil \
    pytz \
    pyyaml \
    xarray \
    zarr

RUN LDFLAGS='-L /usr/local/cuda/lib64 -lcudart -lcuda' MPICC=mpicc pip install mpi4py

# Boost
RUN wget -q https://boostorg.jfrog.io/artifactory/main/release/1.74.0/source/boost_1_74_0.tar.gz && \
    tar xzf boost_1_74_0.tar.gz && \
    rm -f boost_1_74_0.tar.gz && \
    cd boost_1_74_0 && \
    cp -r boost /usr/include/ && cd /
ENV BOOST_HOME=/usr/include/boost
ARG CPPFLAGS="-I${BOOST_HOME} -I${BOOST_HOME}/boost"

# gt4py - with GridTools
RUN git clone --branch SC22 https://github.com/gronerl/gt4py &&\
    python -m pip install ./gt4py &&\
    git clone --depth 1 -b v2.1.0 https://github.com/GridTools/gridtools.git /usr/local/lib/python3.8/dist-packages/gt4py/_external_src/gridtools2

# # fv3gfs-util
RUN git clone --branch SC22 https://github.com/ai2cm/fv3gfs-util.git &&\
    python -m pip install ./fv3gfs-util

# # fv3core
RUN git clone --branch SC22 https://github.com/ai2cm/fv3core.git &&\
    python -m pip install ./fv3core

# # DaCe
RUN git clone --branch FV3v2 --recursive https://github.com/spcl/dace.git &&\
    python -m pip install ./dace

# Setup inputs and runner scripts
ADD inputs /
COPY runner.sh /runner.sh
COPY runner_local.sh /runner_local.sh
RUN chmod a+x /runner.sh
RUN chmod a+x /runner_local.sh

