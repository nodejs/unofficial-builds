FROM centos:7

ARG GID=1000
ARG UID=1000

RUN groupadd --gid $GID node \
    && adduser --gid $GID --uid $UID node

RUN ulimit -n 1024 \
    && sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* \
    && sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* \
    && yum install -y epel-release \
    && yum upgrade -y \
    && yum install -y \
         git \
         curl \
         make \
         ccache

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENV PATH="/home/node/.local/bin:${PATH}"

RUN curl -L micro.mamba.pm/install.sh | bash -s -- -y \
    && eval "$(micromamba shell hook --shell bash)" \
    && micromamba install -y \
         python=3.12 \
         gxx=15

ENTRYPOINT [ "/home/node/run.sh" ]
