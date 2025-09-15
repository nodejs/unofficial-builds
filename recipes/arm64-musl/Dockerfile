FROM alpine:3.22

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
        # extra packages required for creating the musl bases cross-compiler 
        rsync make gcc g++ bzip2 git

COPY <<-EOF /config/config.mak
  # We only set the variables that are really needed, others are the sane defaults from the repo itself
  TARGET = aarch64-linux-musl
  GCC_VER = 14.2.0
  OUTPUT = /opt/aarch64-linux-musl-cross
EOF

RUN git clone https://github.com/richfelker/musl-cross-make /musl-cross-make && \
    cd /musl-cross-make && \
    make -I /config -j$(getconf _NPROCESSORS_ONLN) && \
    make -I /config install && \
    cd / && \
    rm -rf /musl-cross-make

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
