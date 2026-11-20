FROM --platform=linux/amd64 ubuntu:24.04

ARG GID=1000
ARG UID=1000

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         adduser \
         ca-certificates \
         ccache \
         curl \
         g++-14 \
         g++-14-aarch64-linux-gnu \
         git \
         make \
         python3 \
         xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN (addgroup --gid $GID node || groupmod -n node $(getent group $GID | cut -d: -f1)) \
    && (adduser --gid $GID --uid $UID --disabled-password --gecos "" node || usermod -l node -g $GID -d /home/node -m $(getent passwd $UID | cut -d: -f1))

# Node 26's Temporal implementation needs matching host and target Rust
# libraries. Use the same upstream toolchain approach as arm64-musl.
# Checksums: https://static.rust-lang.org/dist/<archive>.tar.xz.sha256
RUN RUST_VERSION="1.91.1" && \
    RUST_HOST_SHA256="db178028da493a663b2e344a142076fb0f72adea4120043983f488de9cf95214" && \
    RUST_STD_SHA256="6aed0726a0fe50cbd488f6c5dd7a053c17ff57b8b361d14bcd216ea9939fb531" && \
    curl -fsSL -o /tmp/rust-host.tar.xz \
        "https://static.rust-lang.org/dist/rust-${RUST_VERSION}-x86_64-unknown-linux-gnu.tar.xz" && \
    echo "${RUST_HOST_SHA256}  /tmp/rust-host.tar.xz" | sha256sum -c - && \
    tar -xJf /tmp/rust-host.tar.xz -C /tmp && \
    /tmp/rust-${RUST_VERSION}-x86_64-unknown-linux-gnu/install.sh --prefix=/opt/rust \
        --components=rustc,cargo,rust-std-x86_64-unknown-linux-gnu --disable-ldconfig && \
    curl -fsSL -o /tmp/rust-std.tar.xz \
        "https://static.rust-lang.org/dist/rust-std-${RUST_VERSION}-aarch64-unknown-linux-gnu.tar.xz" && \
    echo "${RUST_STD_SHA256}  /tmp/rust-std.tar.xz" | sha256sum -c - && \
    tar -xJf /tmp/rust-std.tar.xz -C /tmp && \
    /tmp/rust-std-${RUST_VERSION}-aarch64-unknown-linux-gnu/install.sh --prefix=/opt/rust --disable-ldconfig && \
    rm -rf /tmp/rust-*

COPY --chmod=755 cargo-shim.sh /usr/local/bin/cargo
RUN ln -s /opt/rust/bin/rustc /usr/local/bin/rustc \
    && ln -s /usr/bin/gcc-14 /usr/local/bin/cc
ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc-14

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
