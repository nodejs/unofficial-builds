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
config_flags="--openssl-no-asm --use_clang --experimental-enable-pointer-compression"

cd /home/node

tar -xf node.tar.xz
cd "node-${fullversion}"

export CCACHE_BASEDIR="$PWD"
export CC='ccache clang-19  --target=riscv64-linux-gnu -march=rv64gc'
export CXX='ccache clang++-19  --target=riscv64-linux-gnu -march=rv64gc'
export CC_host='ccache clang-19'
export CXX_host='ccache clang++-19'

#make -j$(getconf _NPROCESSORS_ONLN) binary \

make -j4 binary \
  DESTCPU="riscv64" \
  ARCH="riscv64" \
  VARIATION="pointer-compression" \
  DISTTYPE="$disttype" \
  CUSTOMTAG="$customtag" \
  DATESTRING="$datestring" \
  COMMIT="$commit" \
  RELEASE_URLBASE="$release_urlbase" \
  CONFIG_FLAGS="$config_flags"

# If removal of ICU is desired, add "BUILD_INTL_FLAGS=--with-intl=none" above

mv node-*.tar.?z /out/
