FROM ubuntu:16.04

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
         curl \
         g++-6 \
         gcc-6 \
         gcc-6-multilib \
         g++-6-multilib \
         make \
         python \
         python3 \
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
