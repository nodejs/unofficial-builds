FROM ubuntu:20.04

ARG GID=1000
ARG UID=1000

RUN addgroup --gid $GID node \
    && adduser --gid $GID --uid $UID --disabled-password --gecos node node

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get install -y \
         git \
	 g++-13 \
         curl \
         make \
         python3 \
	 python3-distutils \
         ccache \
         xz-utils

RUN curl -L https://github.com/loongson/build-tools/releases/download/2024.11.01/x86_64-cross-tools-loongarch64-binutils_2.43.1-gcc_14.2.0-glibc_2.40.tar.xz | tar xJf - -C /opt

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
