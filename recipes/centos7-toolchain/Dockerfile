FROM --platform=linux/amd64 centos:7

ARG GID=1000
ARG UID=1000

RUN groupadd --gid $GID node \
    && adduser --gid $GID --uid $UID node

COPY --chmod=755  files/installPrerequisites  /root/installPrerequisites
COPY              files/*.repo                /etc/yum.repos.d/
RUN /root/installPrerequisites

COPY  --chmod=755  files/installFromSourceCode  /root/installFromSourceCode
COPY  --chmod=755  files/opt__gcc15__enable     /opt/gcc15/enable
COPY  --chmod=755  files/checksums.sh           /root/checksums.sh

RUN   --mount=type=cache,target=/root/.ccache  . /root/checksums.sh  &&  /root/installFromSourceCode  https://www.python.org/ftp/python/3.9.23/Python-3.9.23.tar.xz      "$sha256_python39"  '--prefix=/usr/local/'
RUN   --mount=type=cache,target=/root/.ccache  . /root/checksums.sh  &&  /root/installFromSourceCode  https://www.python.org/ftp/python/3.13.5/Python-3.13.5.tar.xz      "$sha256_python313" '--prefix=/usr/local/'
RUN   --mount=type=cache,target=/root/.ccache  . /root/checksums.sh  &&  /root/installFromSourceCode  https://gcc.gnu.org/pub/gcc/releases/gcc-15.1.0/gcc-15.1.0.tar.xz  "$sha256_gcc15"     '--prefix=/opt/gcc15/  --with-default-libstdcxx-abi=gcc4-compatible  --enable-languages=c,c++  --enable-checking=release  --enable-gnu-indirect-function  --with-linker-hash-style=gnu  --disable-bootstrap  --disable-multilib  --build=x86_64-redhat-linux'

# Rust for the Temporal API in Node 26+ (the build silently skips Temporal
# when rustc/cargo are not in PATH).
# Hash verified against the publisher's manifest at
# https://static.rust-lang.org/dist/rust-1.91.1-x86_64-unknown-linux-gnu.tar.xz.sha256
RUN RUST_VERSION="1.91.1" && \
    . /root/checksums.sh && \
    curl -fL -o /tmp/rust-host.tar.xz \
        "https://static.rust-lang.org/dist/rust-${RUST_VERSION}-x86_64-unknown-linux-gnu.tar.xz" && \
    echo "${sha256_rust}  /tmp/rust-host.tar.xz" | sha256sum -c - && \
    tar -xJf /tmp/rust-host.tar.xz -C /tmp && \
    /tmp/rust-${RUST_VERSION}-x86_64-unknown-linux-gnu/install.sh --prefix=/opt/rust \
        --components=rustc,cargo,rust-std-x86_64-unknown-linux-gnu --disable-ldconfig && \
    rm -rf /tmp/rust-* && \
    ln -s /opt/rust/bin/rustc /usr/local/bin/rustc && \
    ln -s /opt/rust/bin/cargo /usr/local/bin/cargo

COPY --chmod=755  --chown=node:node  run.sh  /home/node/
