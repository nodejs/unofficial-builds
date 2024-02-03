FROM alpine:latest

ARG GID=1000
ARG UID=1000

RUN addgroup -g $GID node \
    && adduser -u $UID -G node -s /bin/sh -D node

RUN apk add --no-cache bash gnupg curl

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /out/

USER node

RUN mkdir ~/.gnupg && \
    chmod 700 ~/.gnupg && \
    for key in $(curl -sL https://raw.githubusercontent.com/nodejs/docker-node/HEAD/keys/node.keys) \
  ; do \
      gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
      gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
  done

ENTRYPOINT [ "/home/node/run.sh" ]
