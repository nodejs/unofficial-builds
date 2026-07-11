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
        # rustc/cargo are needed for the Temporal API support in Node 26+
        # (the build silently skips Temporal when they are not in PATH).
        # Pinned so the rust-std target download below matches.
        rust=1.91.1-r2 \
        cargo=1.91.1-r2 \
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

# Install the aarch64-unknown-linux-musl Rust std library for cross-compiling.
# Alpine's `rust` package only ships the host (x86_64-musl) standard library;
# building `cargo --target=aarch64-unknown-linux-musl` requires a matching
# std artifact under `/usr/lib/rustlib/`. Pull the prebuilt std from the
# upstream Rust dist server, matching the version of the host toolchain.
# Hash verified against the publisher's signed sha256 manifest at
# https://static.rust-lang.org/dist/rust-std-1.91.1-aarch64-unknown-linux-musl.tar.xz.sha256
# Approach based on nikeee's commit in
# https://github.com/nodejs/unofficial-builds/commit/74ae38b3117b8dc29f6f2f00e37205cbe447e167
RUN RUST_STD_VERSION="1.91.1" && \
    RUST_STD_SHA256="2a919a0e5df46e1bfe4b8be8fbc81cf48bf9813be34ff5f212a2a68f03eb517f" && \
    wget -O /tmp/rust-std.tar.xz \
        "https://static.rust-lang.org/dist/rust-std-${RUST_STD_VERSION}-aarch64-unknown-linux-musl.tar.xz" && \
    echo "${RUST_STD_SHA256}  /tmp/rust-std.tar.xz" | sha256sum -c - && \
    # busybox tar's built-in xz decoder cannot read this archive; use the
    # real xz installed above
    xz -dc /tmp/rust-std.tar.xz | tar -x -C /tmp && \
    cp -r /tmp/rust-std-${RUST_STD_VERSION}-aarch64-unknown-linux-musl/rust-std-aarch64-unknown-linux-musl/lib/rustlib/aarch64-unknown-linux-musl \
        /usr/lib/rustlib/ && \
    rm -rf /tmp/rust-std*

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
