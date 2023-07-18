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
         gcc-8-aarch64-linux-gnu \
         g++-8-aarch64-linux-gnu \
         binutils-aarch64-linux-gnu \
         libstdc++-8-dev-amd64-cross \
         linux-libc-dev-arm64-cross linux-libc-dev-amd64-cross \
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
