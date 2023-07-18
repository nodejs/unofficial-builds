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
config_flags=

cd /home/node

tar -xf node.tar.xz
cd "node-${fullversion}"

export CC_host="ccache gcc-8"
export CXX_host="ccache g++-8"
export CC="ccache aarch64-linux-gnu-gcc-8"
export CXX="ccache aarch64-linux-gnu-g++-8"

make -j$(getconf _NPROCESSORS_ONLN) binary V= \
  DESTCPU="arm64" \
  ARCH="arm64" \
  VARIATION="" \
  DISTTYPE="$disttype" \
  CUSTOMTAG="$customtag" \
  DATESTRING="$datestring" \
  COMMIT="$commit" \
  RELEASE_URLBASE="$release_urlbase" \
  CONFIG_FLAGS="$config_flags"

mv node-*.tar.?z /out/
