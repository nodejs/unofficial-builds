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
source_urlbase="$8"
config_flags=

cd /home/node

# Curl with retry
curl_with_retry "$source_url"

if [[ "$disttype" = "release" ]]; then
fi


curl -fsSLO --compressed "${source_urlbase}/node-${fullversion}-headers.tar.gz"
curl -fsSLO --compressed "${source_urlbase}/node-${fullversion}-headers.tar.xz"

if [[ "$disttype" = "release" ]]; then
  pubring=$(mktemp)
  curl -sSLo "$pubring" https://github.com/nodejs/release-keys/raw/HEAD/gpg-only-active-keys/pubring.kbx

  curl -sSL "${source_urlbase}/SHASUMS256.txt.asc" \
  | gpgv --keyring="${pubring}" --output - \
  | grep " node-${fullversion}-headers.tar.*\$" SHASUMS256.txt \
  | sha256sum -c -
fi

mv node-${fullversion}-headers.tar* /out/
