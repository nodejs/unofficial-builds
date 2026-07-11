#!/usr/bin/env bash

curl_with_retry()
{
  URL=$1
  attempts=${2:-7}
  delay=${3:-10}
  echo "Fetching $URL"
  for ((i=1;i<=attempts;i++)); do
    if curl -fsSLO --compressed "$URL"; then
      return 0
    else
      echo "Curl failed with status $?. Retry $i/$attempts in $delay seconds..."
      sleep "$delay"
    fi
  done
  echo "Giving up on $URL after $attempts attempts"
  return 1
}

set -exo pipefail

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

if [[ "$disttype" = "release" ]]; then
  # SHASUMS256.txt.asc is uploaded after the tarballs appear in the release
  # index, so a build triggered off a fresh index entry can race it. Wait for
  # the signature (up to 15 minutes) before spending bandwidth on the source
  # tarball we would not be able to validate.
  curl_with_retry "${source_urlbase}/SHASUMS256.txt.asc" 30 30
  curl_with_retry https://github.com/nodejs/release-keys/raw/HEAD/gpg-only-active-keys/pubring.kbx
fi

curl_with_retry "$source_url"

if [[ "$disttype" = "release" ]]; then
  gpgv --keyring="$(pwd)/pubring.kbx" --output - < SHASUMS256.txt.asc \
  | grep " node-${fullversion}.tar.xz\$" \
  | sha256sum -c -
fi

mv -f node-${fullversion}.tar.xz /out/
