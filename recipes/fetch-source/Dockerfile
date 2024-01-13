FROM alpine:latest

ARG GID=1000
ARG UID=1000

RUN addgroup -g $GID node \
    && adduser -u $UID -G node -s /bin/sh -D node

RUN apk add --no-cache bash gnupg curl

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /out/

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
