FROM centos:7

ARG GID=1000
ARG UID=1000

RUN groupadd --gid $GID node \
    && adduser --gid $GID --uid $UID node

COPY cloudlinux.repo /etc/yum.repos.d/cloudlinux.repo

# configures centos and base repos and upgrades packages 
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* \
    && sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* \
    && yum install -y epel-release \
    && yum upgrade -y \

# installs python 3.8 as it is needed to build x64 pointer compression
RUN yum install -y \
        rh-python38 \
        rh-python38-python-devel \
    && echo "source scl_source enable rh-python38" >> /etc/bashrc \
    && echo "source scl_source enable rh-python38" >> /home/node/.bashrc \
    && ln -s /opt/rh/rh-python38/root/usr/bin/python3 /usr/bin/python3 \
    && ln -s /opt/rh/rh-python38/root/usr/bin/pip3 /usr/bin/pip3

# installs any other needed dependencies
RUN yum install -y \
        git \
        curl \
        make \
        python2 \
        ccache \
        xz-utils \
        devtoolset-8 \
        devtoolset-9 \
        glibc-devel

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
