FROM alpine:3.19

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
        git \
        patch

RUN git clone https://github.com/richfelker/musl-cross-make /musl-cross-make
RUN echo 'TARGET = aarch64-linux-musl' >> /musl-cross-make/config.mak
RUN echo 'GCC_VER = 11.2.0' >> /musl-cross-make/config.mak
RUN chown -R node:node /musl-cross-make/

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /home/node/.ccache
VOLUME /out
VOLUME /home/node/node.tar.xz

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
