#!/usr/bin/env bash

set -e
set -x

release_urlbase="$1"
disttype="$2"
customtag="$3"
datestring="$4"
commit="$5"
fullversion="$6"
source_url="$7"
config_flags=--experimental-enable-pointer-compression

cd /home/node

tar -xf node.tar.xz
cd "node-${fullversion}"

export CC="ccache gcc"
export CXX="ccache g++"
export MAJOR_VERSION=$(echo ${fullversion} | cut -d . -f 1 | tr --delete v)

if [ $MAJOR_VERSION -ge 16 ]; then
  . /opt/rh/devtoolset-9/enable
else
  . /opt/rh/devtoolset-8/enable
fi

make -j$(getconf _NPROCESSORS_ONLN) binary V= \
  DESTCPU="x64" \
  ARCH="x64" \
  VARIATION="pointer-compression" \
  DISTTYPE="$disttype" \
  CUSTOMTAG="$customtag" \
  DATESTRING="$datestring" \
  COMMIT="$commit" \
  RELEASE_URLBASE="$release_urlbase" \
  CONFIG_FLAGS="$config_flags"

mv node-*.tar.?z /out/
