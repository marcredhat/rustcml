
# Using the `rust-musl-builder` as base image, instead of
# the official Rust toolchain
FROM docker.io/clux/muslrust:stable AS chef
USER root
RUN cargo install cargo-chef
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
# Notice that we are specifying the --target flag!
RUN cargo chef cook --release --target x86_64-unknown-linux-musl --recipe-path recipe.json
COPY . .
RUN cargo build --release --target x86_64-unknown-linux-musl --bin hello_cargo



#FROM ip-10-10-207-158.us-west-2.compute.internal:9999/b868/cargo-chef:marc as chef


FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04
RUN apt-key del 7fa2af80 && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub

RUN \
  addgroup --gid 8536 cdsw && \
  adduser --disabled-password --gecos "CDSW User" --uid 8536 --gid 8536 cdsw


RUN for i in /etc /etc/alternatives; do \
  if [ -d ${i} ]; then chmod 777 ${i}; fi; \
  done

RUN chown cdsw /

RUN for i in /bin /etc /opt /sbin /usr; do \
  if [ -d ${i} ]; then \
    chown cdsw ${i}; \
    find ${i} -type d -exec chown cdsw {} +; \
  fi; \
  done

WORKDIR /
ENV DEBIAN_FRONTEND=noninteractive \
    LC_ALL=en_US.UTF-8 LANG=C.UTF-8 LANGUAGE=en_US.UTF-8 \
    TERM=xterm


RUN apt -y update && apt-get install -y --no-install-recommends \
  locales \
  apt-transport-https \
  krb5-user \
  xz-utils \
  git \
  git-lfs \
  ssh \
  unzip \
  gzip \
  curl \
  nano \
  emacs-nox \
  wget \
  ca-certificates \
  zlib1g-dev \
  libbz2-dev \
  liblzma-dev \
  libssl-dev \
  libsasl2-dev \
  libsasl2-2 \
  libsasl2-modules-gssapi-mit \
  libzmq3-dev \
  cpio \
  cmake \
  make \
  && \
  apt-get clean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/* && \
  echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

RUN rm -f /etc/krb5.conf

RUN mkdir -p /etc/pki/tls/certs
RUN ln -s /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt

RUN ln -s /usr/lib/x86_64-linux-gnu/libsasl2.so.2 /usr/lib/x86_64-linux-gnu/libsasl2.so.3

ENV PATH /home/cdsw/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/conda/bin

ENV SHELL /bin/bash

ENV HADOOP_ROOT_LOGGER WARN,console



WORKDIR /build

RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        libsqlite3-0 \
        mime-support \
        libpq-dev \
        gcc \
        g++ \
        libkrb5-dev \
    && \
    rm -rf /var/lib/apt/lists/*


ENV PYTHON3_VERSION=3.10.9 \
    ML_RUNTIME_KERNEL="Python 3.10"

ADD build/python-3.10.9-pkg.tar.gz /usr/local

COPY etc/sitecustomize.py /usr/local/lib/python3.10/site-packages/
COPY etc/pip.conf /etc/pip.conf
COPY requirements/python-standard-packages/requirements-3.10.txt /build/requirements.txt

RUN \
    ldconfig && \
    pip3 config set install.user false && \
    SETUPTOOLS_USE_DISTUTILS=stdlib pip3 install \
        --no-cache-dir \
        --no-warn-script-location \
        -r requirements.txt && \
    rm -rf /build


ENV ML_RUNTIME_EDITOR="PBJ Workbench" \
    ML_RUNTIME_EDITION="Standard" \
    ML_RUNTIME_JUPYTER_KERNEL_GATEWAY_CMD="jupyter kernelgateway --config=/home/cdsw/.jupyter/jupyter_kernel_gateway_config.py" \
    JUPYTERLAB_WORKSPACES_DIR=/tmp

COPY requirements/pbj-workbench-base/requirements-3.10.txt /build/requirements.txt

COPY etc/cloudera.mplstyle /etc/cloudera.mplstyle

RUN \
    SETUPTOOLS_USE_DISTUTILS=stdlib pip3 install \
        --no-cache-dir \
        --no-warn-script-location \
        -r /build/requirements.txt && \
    rm -rf /build

COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/hello_cargo /usr/local/bin/
USER cdsw
CMD ["/usr/local/bin/hello_cargo"]


ENV PYTHON3_VERSION=3.10.9 \
    ML_RUNTIME_KERNEL="Rust Marc"



ENV ML_RUNTIME_EDITOR="PBJ Workbench" \
    ML_RUNTIME_EDITION="Standard" \
    ML_RUNTIME_JUPYTER_KERNEL_GATEWAY_CMD="jupyter kernelgateway --config=/home/cdsw/.jupyter/jupyter_kernel_gateway_config.py" \
    JUPYTERLAB_WORKSPACES_DIR=/tmp


ENV ML_RUNTIME_JUPYTER_KERNEL_NAME="python3" \
    ML_RUNTIME_DESCRIPTION="PBJ Workbench Python runtime provided by Cloudera"

ENV ML_RUNTIME_EDITION="Marc Rust Nvidia GPU" \
    ML_RUNTIME_DESCRIPTION="Rust runtime with CUDA libraries" \
    ML_RUNTIME_CUDA_VERSION="11.8.0"




ENV \
    ML_RUNTIME_METADATA_VERSION=2 \
    ML_RUNTIME_FULL_VERSION=2023.08.2-b8 \
    ML_RUNTIME_SHORT_VERSION=2023.08 \
    ML_RUNTIME_MAINTENANCE_VERSION=2 \
    ML_RUNTIME_GIT_HASH=cdee6e30026323b76feda974d3b6fba48bee5688 \
    ML_RUNTIME_GBN=45253874

LABEL \
    com.cloudera.ml.runtime.runtime-metadata-version=2 \
    com.cloudera.ml.runtime.editor="PBJ Workbench" \
    com.cloudera.ml.runtime.edition="Rust Musl Python GPU Marc Standard" \
    com.cloudera.ml.runtime.description="Rust Musl Python GPU" \
    com.cloudera.ml.runtime.kernel="Rust Musl Python GPU" \
    com.cloudera.ml.runtime.full-version=$ML_RUNTIME_FULL_VERSION \
    com.cloudera.ml.runtime.short-version=$ML_RUNTIME_SHORT_VERSION \
    com.cloudera.ml.runtime.maintenance-version=$ML_RUNTIME_MAINTENANCE_VERSION \
    com.cloudera.ml.runtime.git-hash=$ML_RUNTIME_GIT_HASH \
    com.cloudera.ml.runtime.gbn=$ML_RUNTIME_GBN \
    com.cloudera.ml.runtime.cuda-version=$ML_RUNTIME_CUDA_VERSION
