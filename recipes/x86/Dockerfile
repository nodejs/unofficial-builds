FROM centos:7

RUN groupadd --gid 1000 node \
    && adduser --gid 1000 --uid 1000 node

COPY cloudlinux.repo /etc/yum.repos.d/cloudlinux.repo

RUN yum install -y epel-release \
    && yum upgrade -y \
    && yum install -y \
         git \
         curl \
         make \
         python \
         ccache \
         xz-utils \
         devtoolset-6.i686 \
         glibc-devel.i686

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
