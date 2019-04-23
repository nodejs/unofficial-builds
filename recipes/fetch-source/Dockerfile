FROM alpine:3.9

RUN addgroup -g 1000 node \
    && adduser -u 1000 -G node -s /bin/sh -D node

RUN apk add --no-cache bash gnupg curl

RUN for key in $(curl -sL https://raw.githubusercontent.com/nodejs/docker-node/master/keys/node.keys) \
  ; do \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done

COPY --chown=node:node run.sh /home/node/run.sh

VOLUME /out/

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
