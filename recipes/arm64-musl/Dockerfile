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
        # this is required to support building v16 on python 3.12
        py3-packaging

RUN cd /opt \
    && curl -O https://musl.cc/aarch64-linux-musl-cross.tgz \
    && tar xzf aarch64-linux-musl-cross.tgz

COPY --chown=node:node run.sh /home/node/run.sh
COPY --chown=node:node 55596.diff /home/node/55596.diff
COPY --chown=node:node 51256-v16.diff /home/node/51256-v16.diff

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
