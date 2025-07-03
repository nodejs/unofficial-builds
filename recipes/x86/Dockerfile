FROM --platform=linux/386 centos:7

ARG GID=1000
ARG UID=1000

RUN groupadd --gid $GID node \
    && adduser --gid $GID --uid $UID node

COPY --chmod=755  files/installPrerequisites  /root/installPrerequisites
COPY              files/*.repo                /etc/yum.repos.d/
RUN /root/installPrerequisites

COPY  --chmod=755  files/installFromSourceCode  /root/installFromSourceCode
COPY  --chmod=755  files/opt__gcc15__enable     /opt/gcc15/enable
RUN   --mount=type=cache,target=/root/.ccache  --mount=type=tmpfs,target=/usr/src  /root/installFromSourceCode  python3   https://www.python.org/ftp/python/3.9.23/Python-3.9.23.tar.xz      '--prefix=/usr/local/'
RUN   --mount=type=cache,target=/root/.ccache  --mount=type=tmpfs,target=/usr/src  /root/installFromSourceCode  python3   https://www.python.org/ftp/python/3.13.5/Python-3.13.5.tar.xz      '--prefix=/usr/local/'
RUN   --mount=type=cache,target=/root/.ccache  --mount=type=tmpfs,target=/usr/src  /root/installFromSourceCode  gcc       https://gcc.gnu.org/pub/gcc/releases/gcc-15.1.0/gcc-15.1.0.tar.xz  '--prefix=/opt/gcc15/  --with-default-libstdcxx-abi=gcc4-compatible  --enable-languages=c,c++  --enable-checking=release  --enable-gnu-indirect-function  --with-linker-hash-style=gnu  --disable-bootstrap  --disable-multilib  --build=i686-redhat-linux'
RUN   --mount=type=cache,target=/root/.ccache  --mount=type=tmpfs,target=/usr/src  /root/installFromSourceCode  binutils  https://sourceware.org/pub/binutils/releases/binutils-2.44.tar.xz  '--prefix=/opt/gcc15/  --without-debuginfod  --disable-nls  LDFLAGS=-pthread'

COPY --chmod=755  --chown=node:node  run.sh  run_other.sh  run_versions.sh  /home/node/

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
