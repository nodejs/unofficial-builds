FROM centos:7

ARG GID=1000
ARG UID=1000

RUN groupadd --gid $GID node \
    && adduser --gid $GID --uid $UID node

COPY cloudlinux.repo /etc/yum.repos.d/cloudlinux.repo

RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* \
    && sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* \
    && yum install -y epel-release \
    && yum upgrade -y \
    && yum install -y \
         git \
         curl \
         make \
         python2 \
         python3 \
         ccache \
         xz-utils \
         devtoolset-8 \
         devtoolset-8-systemtap-sdt-devel \
         devtoolset-9 \
         devtoolset-9-systemtap-sdt-devel \
         glibc-devel

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
