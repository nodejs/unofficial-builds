FROM ubuntu:24.04

ARG GID=1000
ARG UID=1000

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y \
         adduser \
         git \
	     g++-13 \
         curl \
         make \
         python3.10 \
         ccache \
         xz-utils \
         gcc-14-riscv64-linux-gnu \
         g++-14-riscv64-linux-gnu \
         gcc-14-riscv64-linux-gnu-base

RUN (addgroup --gid $GID node || groupmod -n node $(getent group $GID | cut -d: -f1)) \
    && (adduser --gid $GID --uid $UID --disabled-password --gecos "" node || usermod -l node -g $GID -d /home/node -m $(getent passwd $UID | cut -d: -f1))
    
RUN rm -f /usr/bin/python3
RUN ln -s /usr/bin/python3.10 /usr/bin/python3

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
