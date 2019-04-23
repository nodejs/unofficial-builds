FROM ubuntu:16.04

RUN addgroup --gid 1000 node \
    && adduser --gid 1000 --uid 1000 --disabled-password --gecos node node

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y software-properties-common \
    && add-apt-repository ppa:ubuntu-toolchain-r/test \
    &&  apt-get update \
    && apt-get install -y \
         git \
         curl \
         g++-6 \
         gcc-6 \
         gcc-6-multilib \
         g++-6-multilib \
         make \
         python \
         ccache \
         xz-utils

RUN git clone --depth=1 https://github.com/rvagg/rpi-newer-crosstools \
    /opt/rpi-newer-crosstools/

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
