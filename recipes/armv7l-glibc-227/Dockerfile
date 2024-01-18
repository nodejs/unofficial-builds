FROM ubuntu:18.04

ARG GID=1000
ARG UID=1000

RUN addgroup --gid $GID node \
    && adduser --gid $GID --uid $UID --disabled-password --gecos node node

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get update \
    && apt-get install -y \
         git \
         curl \
         gcc-8 \
         g++-8 \
         gcc-8-arm-linux-gnueabihf \
         g++-8-arm-linux-gnueabihf \
         binutils-arm-linux-gnueabihf \
         lib32stdc++-8-dev libstdc++-8-dev-amd64-cross libstdc++-8-dev-x32-cross libx32stdc++-8-dev libstdc++-8-dev-i386-cross \
         linux-libc-dev-armhf-cross linux-libc-dev-amd64-cross linux-libc-dev-x32-cross linux-libc-dev-i386-cross \
         make \
         python3 \
         python3-distutils \
         ccache \
         xz-utils

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
