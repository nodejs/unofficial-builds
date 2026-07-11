FROM --platform=linux/amd64 unofficial-build-recipe-centos7-toolchain

COPY --chmod=755  --chown=node:node  run_other.sh  run_versions.sh  /home/node/

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
