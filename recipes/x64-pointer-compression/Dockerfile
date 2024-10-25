FROM centos:7

ARG GID=1000
ARG UID=1000

RUN groupadd --gid $GID node \
    && adduser --gid $GID --uid $UID node

COPY cloudlinux.repo /etc/yum.repos.d/cloudlinux.repo

# patch repos and install base dependencies
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* \
    && sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* \
    && yum install -y epel-release \
    && yum upgrade -y \
    && yum install -y \
         git \
         curl \
         make \
         python2 \
         ccache \
         xz-utils \
         devtoolset-8 \
         devtoolset-9 \
         glibc-devel

# installs c compiler dev tools and builds python >=3.8 from source as it is needed for node >=v22
ENV PYTHON_VERSION="3.10.15"
RUN yum groupinstall -y "Development Tools" \
    && yum install -y \
        gcc \
        gcc-c++ \
        make \
        zlib-devel \
        bzip2-devel \
        openssl-devel \
        libffi-devel \
        sqlite-devel \
        readline-devel \
    && curl https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz -O \
    && tar xzf Python-${PYTHON_VERSION}.tgz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --enable-optimizations \
    && make altinstall \
    && PYTHON_MAJOR_MINOR_VERSION=$(echo $PYTHON_VERSION | cut -d. -f1,2) \
    && ln -sf /usr/local/bin/python${PYTHON_MAJOR_MINOR_VERSION} /usr/bin/python3

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
