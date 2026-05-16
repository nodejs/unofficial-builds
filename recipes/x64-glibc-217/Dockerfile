FROM --platform=linux/amd64 unofficial-build-recipe-centos7-toolchain

ARG GID=1000
ARG UID=1000

RUN groupadd --gid $GID node \
    && adduser --gid $GID --uid $UID node

COPY --chmod=755  --chown=node:node  run.sh  run_other.sh  run_versions.sh  /home/node/

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
