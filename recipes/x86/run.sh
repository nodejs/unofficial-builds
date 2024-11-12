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
config_flags=--openssl-no-asm

cd /home/node

tar -xf node.tar.xz

# configuring cares correctly to not use sys/random.h on this target
cd "node-${fullversion}"/deps/cares/config/linux
sed -i 's/define HAVE_SYS_RANDOM_H 1/undef HAVE_SYS_RANDOM_H/g' ./ares_config.h
sed -i 's/define HAVE_GETRANDOM 1/undef HAVE_GETRANDOM/g' ./ares_config.h

cd /home/node

cd "node-${fullversion}"

export CC="ccache gcc"
export CXX="ccache g++"
export CXXFLAGS=-m32
export CFLAGS=-m32
export MAJOR_VERSION=$(echo ${fullversion} | cut -d . -f 1 | tr --delete v)

if [ $MAJOR_VERSION -ge 16 ]; then
  . /opt/rh/devtoolset-9/enable
fi

make -j$(getconf _NPROCESSORS_ONLN) binary V= \
  DESTCPU="x86" \
  ARCH="x86" \
  VARIATION="" \
  DISTTYPE="$disttype" \
  CUSTOMTAG="$customtag" \
  DATESTRING="$datestring" \
  COMMIT="$commit" \
  RELEASE_URLBASE="$release_urlbase" \
  CONFIG_FLAGS="$config_flags"

mv node-*.tar.?z /out/
