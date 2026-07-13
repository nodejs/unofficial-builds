FROM alpine:3.23

ARG GID=1000
ARG UID=1000

RUN addgroup -g $GID node \
    && adduser -u $UID -G node -s /bin/sh -D node

RUN apk add --no-cache \
        libstdc++ \
    && apk add --no-cache --virtual .build-deps \
        bash \
        binutils-gold \
        curl \
        g++ \
        gcc \
        gnupg \
        libgcc \
        linux-headers \
        make \
        python3 \
        ccache \
        xz \
        patch \
        # extra packages required for creating the musl based cross-compiler
        rsync make gcc g++ bzip2 git

COPY <<-EOF /config/config.mak
  # We only set the variables that are really needed, others are the sane defaults from the repo itself
  TARGET = aarch64-linux-musl
  GCC_VER = 14.2.0
  OUTPUT = /opt/aarch64-linux-musl-cross
EOF

# set the version we want do use.
# This is currently set to the last known working commit sha, as the lastest tag (v0.9.11) is not working
# We specifically don't use the master branch as protection against rougue changes.
# see following link for more context of what archives are available.
# https://docs.github.com/en/repositories/working-with-files/using-files/downloading-source-code-archives#source-code-archive-urls
RUN RELEASE="3635262e4524c991552789af6f36211a335a77b3" && \
    wget https://github.com/richfelker/musl-cross-make/archive/${RELEASE}.tar.gz && \
    tar -xzf ${RELEASE}.tar.gz && \
    cd /musl-cross-make-${RELEASE} && \
    make -I /config -j$(getconf _NPROCESSORS_ONLN) && \
    make -I /config install && \
    cd / && \
    rm -rf /musl-cross-make-${RELEASE}/ ${RELEASE}.tar.gz

# Rust for the Temporal API in Node 26+ (the build silently skips Temporal
# when rustc/cargo are not in PATH). The host toolchain and the
# aarch64-unknown-linux-musl target std must come from the same build of
# rustc (E0514 rejects mixed rlibs), so both come from the upstream dist
# server rather than Alpine's own rustc build, which cannot consume upstream
# std rlibs. Hashes verified against the publisher's manifests, e.g.
# https://static.rust-lang.org/dist/rust-1.91.1-x86_64-unknown-linux-musl.tar.xz.sha256
# Approach based on nikeee's commit in
# https://github.com/nodejs/unofficial-builds/commit/74ae38b3117b8dc29f6f2f00e37205cbe447e167
RUN RUST_VERSION="1.91.1" && \
    RUST_HOST_SHA256="2fc7cac1663d245530bca0d487b2423f6b5a0bb99f03eedc439a155484dd6f56" && \
    RUST_STD_SHA256="2a919a0e5df46e1bfe4b8be8fbc81cf48bf9813be34ff5f212a2a68f03eb517f" && \
    wget -O /tmp/rust-host.tar.xz \
        "https://static.rust-lang.org/dist/rust-${RUST_VERSION}-x86_64-unknown-linux-musl.tar.xz" && \
    echo "${RUST_HOST_SHA256}  /tmp/rust-host.tar.xz" | sha256sum -c - && \
    # busybox tar's built-in xz decoder cannot read these archives; use the
    # real xz installed above
    xz -dc /tmp/rust-host.tar.xz | tar -x -C /tmp && \
    /tmp/rust-${RUST_VERSION}-x86_64-unknown-linux-musl/install.sh --prefix=/opt/rust \
        --components=rustc,cargo,rust-std-x86_64-unknown-linux-musl --disable-ldconfig && \
    wget -O /tmp/rust-std.tar.xz \
        "https://static.rust-lang.org/dist/rust-std-${RUST_VERSION}-aarch64-unknown-linux-musl.tar.xz" && \
    echo "${RUST_STD_SHA256}  /tmp/rust-std.tar.xz" | sha256sum -c - && \
    xz -dc /tmp/rust-std.tar.xz | tar -x -C /tmp && \
    /tmp/rust-std-${RUST_VERSION}-aarch64-unknown-linux-musl/install.sh --prefix=/opt/rust --disable-ldconfig && \
    rm -rf /tmp/rust-*

# node's gyp invokes plain `cargo` for host and cross builds alike; this shim
# (found first in PATH) adds --target for the cross target only
COPY --chmod=755 cargo-shim.sh /usr/local/bin/cargo
RUN ln -s /opt/rust/bin/rustc /usr/local/bin/rustc

# Tell Cargo to use the musl-cross-make linker when targeting aarch64-musl.
COPY <<-EOF /usr/local/cargo/config.toml
  [target.aarch64-unknown-linux-musl]
  linker = "/opt/aarch64-linux-musl-cross/bin/aarch64-linux-musl-gcc"
EOF
ENV CARGO_HOME=/usr/local/cargo

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
