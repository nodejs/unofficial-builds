#!/usr/bin/env bash

set -x
set -e

release_urlbase="$1"
disttype="$2"
customtag="$3"
datestring="$4"
commit="$5"
fullversion="$6"
source_url="$7"
config_flags=

cd /home/node

gpg_keys=$(curl -sL https://raw.githubusercontent.com/nodejs/docker-node/HEAD/keys/node.keys)

for key in ${gpg_keys}; do
  gpg --list-keys "$key" ||
      gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
      gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
done

# Curl with retry
for ((i=1;i<=7;i++)); do
  if curl -fsSLO --compressed "$source_url"; then
    break
  else
    echo "Curl failed with status $?. Retrying in 10 seconds..."
    sleep 10
  fi
done

if [[ "$disttype" = "release" ]]; then
  curl -fsSLO --compressed "${source_url}/../SHASUMS256.txt.asc"
  gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc
  grep " node-${fullversion}.tar.xz\$" SHASUMS256.txt | sha256sum -c -
fi

mv -f node-${fullversion}.tar.xz /out/
