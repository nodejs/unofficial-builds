#!/usr/bin/env bash

curl_with_retry()
{
  URL=$1
  echo "Fetching $URL"
  for ((i=1;i<=7;i++)); do
    if curl -fsSLO --compressed "$URL"; then
      break
    else
      echo "Curl failed with status $?. Retrying in 10 seconds..."
      sleep 10
    fi
  done
}

set -x
set -e

release_urlbase="$1"
disttype="$2"
customtag="$3"
datestring="$4"
commit="$5"
fullversion="$6"
source_url="$7"
source_urlbase="$8"
config_flags=

cd /home/node

# Curl with retry
curl_with_retry "$source_url"

if [[ "$disttype" = "release" ]]; then
  curl_with_retry https://github.com/nodejs/release-keys/raw/HEAD/gpg-only-active-keys/pubring.kbx
  curl_with_retry "${source_urlbase}/SHASUMS256.txt.asc"

  gpgv --keyring="pubring.kbx" --output - < SHASUMS256.txt.asc \
  | grep " node-${fullversion}.tar.xz\$" \
  | sha256sum -c -
fi

mv -f node-${fullversion}.tar.xz /out/
