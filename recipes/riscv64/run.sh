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
source_urlbase="$8"
config_flags="--openssl-no-asm"

cd /home/node

tar -xf node.tar.xz
cd "node-${fullversion}"

export CC_host="ccache gcc-13"
export CXX_host="ccache g++-13"
export CC="ccache /usr/bin/riscv64-linux-gnu-gcc-14"
export CXX="ccache /usr/bin/riscv64-linux-gnu-g++-14"

make -j$(getconf _NPROCESSORS_ONLN) binary V= \
  DESTCPU="riscv64" \
  ARCH="riscv64" \
  VARIATION="" \
  DISTTYPE="$disttype" \
  CUSTOMTAG="$customtag" \
  DATESTRING="$datestring" \
  COMMIT="$commit" \
  RELEASE_URLBASE="$release_urlbase" \
  CONFIG_FLAGS="$config_flags"

# If removal of ICU is desired, add "BUILD_INTL_FLAGS=--with-intl=none" above

mv node-*.tar.?z /out/
