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

cd /musl-cross-make

make -j$(getconf _NPROCESSORS_ONLN)
make install

cd /home/node

tar -xf node.tar.xz
cd "node-${fullversion}"

export CC="ccache /musl-cross-make/output/bin/aarch64-linux-musl-gcc"
export CXX="ccache /musl-cross-make/output/bin/aarch64-linux-musl-g++"
export AR_host="ar"
export CC_host="gcc"
export CXX_host="g++"
export LINK_host="g++"

# TODO: add back -j$(getconf _NPROCESSORS_ONLN)
make -j1 binary V= \
  DESTCPU="arm64" \
  ARCH="arm64" \
  VARIATION="musl" \
  DISTTYPE="$disttype" \
  CUSTOMTAG="$customtag" \
  DATESTRING="$datestring" \
  COMMIT="$commit" \
  RELEASE_URLBASE="$release_urlbase" \
  CONFIG_FLAGS="$config_flags"

mv node-*.tar.?z /out/
