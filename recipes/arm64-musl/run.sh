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
config_flags=""

cd /home/node

tar -xf node.tar.xz
cd "node-${fullversion}"

# Patch needed to support cross compilation for arm64 on amd64 for node 16.
# This change will normally be backported to a future node 16 release. 
# @see https://github.com/nodejs/node/issues/42544#issuecomment-1094680617
major=$(echo ${fullversion} | cut -d . -f 1 | tr -d v)
if [ "$major" == "16" ]; then
  wget https://github.com/nodejs/node/commit/6ac1cccf9fd565f92f9e1cc5c7d792d5410a7c54.diff
  patch -p1 < 6ac1cccf9fd565f92f9e1cc5c7d792d5410a7c54.diff
  rm 6ac1cccf9fd565f92f9e1cc5c7d792d5410a7c54.diff
fi

export CC_host="ccache gcc"
export CXX_host="ccache g++"
export CC="ccache /opt/aarch64-linux-musl-cross/bin/aarch64-linux-musl-gcc"
export CXX="ccache /opt/aarch64-linux-musl-cross/bin/aarch64-linux-musl-g++ -static-libstdc++"

make -j$(getconf _NPROCESSORS_ONLN) binary V= \
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
