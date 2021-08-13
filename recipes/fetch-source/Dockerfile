FROM alpine:3.9

ARG GID=1000
ARG UID=1000

RUN addgroup -g $GID node \
    && adduser -u $UID -G node -s /bin/sh -D node

RUN apk add --no-cache bash gnupg curl

RUN for key in $(curl -sL https://raw.githubusercontent.com/nodejs/docker-node/master/keys/node.keys) \
  ; do \
      gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
      gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
  done

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /out/

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
