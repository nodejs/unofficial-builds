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
config_flags="--openssl-no-asm"

cd /home/node

tar -xf node.tar.xz
cd "node-${fullversion}"

export CC_host="ccache gcc-9"
export CXX_host="ccache g++-9"
export CC="ccache /opt/cross-tools/bin/loongarch64-unknown-linux-gnu-gcc"
export CXX="ccache /opt/cross-tools/bin/loongarch64-unknown-linux-gnu-g++"

make -j$(getconf _NPROCESSORS_ONLN) binary V= \
  DESTCPU="loong64" \
  ARCH="loong64" \
  VARIATION="" \
  DISTTYPE="$disttype" \
  CUSTOMTAG="$customtag" \
  DATESTRING="$datestring" \
  COMMIT="$commit" \
  RELEASE_URLBASE="$release_urlbase" \
  CONFIG_FLAGS="$config_flags"

mv node-*.tar.?z /out/
