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

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
