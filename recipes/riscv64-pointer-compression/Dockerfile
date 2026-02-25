FROM ubuntu:24.04

ARG GID=1000
ARG UID=1000

RUN apt -y update && \
    apt -y dist-upgrade && \
    apt install -y \
        clang-19 \
        lld \
        gcc-riscv64-linux-gnu \
        g++-riscv64-linux-gnu \
        ccache \
        make \
        git \
        xz-utils \
        adduser && \
    apt install -y less file bzip2 curl adduser joe

RUN (addgroup --gid $GID node || groupmod -n node $(getent group $GID | cut -d: -f1)) \
    && (adduser --gid $GID --uid $UID --disabled-password --gecos "" node || usermod -l node -g $GID -d /home/node -m $(getent passwd $UID | cut -d: -f1))

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

 ENTRYPOINT [ "/home/node/run.sh" ]
