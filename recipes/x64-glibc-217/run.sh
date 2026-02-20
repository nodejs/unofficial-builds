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
config_flags=""

cd /home/node

tar -xf node.tar.xz

# configuring cares correctly to not use sys/random.h on this target
cd "node-${fullversion}"/deps/cares
sed -i 's/define HAVE_SYS_RANDOM_H 1/undef HAVE_SYS_RANDOM_H/g' ./config/linux/ares_config.h
sed -i 's/define HAVE_GETRANDOM 1/undef HAVE_GETRANDOM/g' ./config/linux/ares_config.h

# fix https://github.com/c-ares/c-ares/issues/850
if [[ "$(grep -o 'ARES_VERSION_STR "[^"]*"' ./include/ares_version.h | awk '{print $2}' | tr -d '"')" == "1.33.0" ]]; then
  sed -i 's/MSG_FASTOPEN/TCP_FASTOPEN_CONNECT/g' ./src/lib/ares__socket.c
fi

cd /home/node

cd "node-${fullversion}"

export CCACHE_BASEDIR="$PWD"
export CC="ccache gcc"
export CXX="ccache g++"
export MAJOR_VERSION=$(echo ${fullversion} | cut -d . -f 1 | tr --delete v)

. /opt/rh/devtoolset-12/enable
. /opt/rh/rh-python38/enable

make -j$(getconf _NPROCESSORS_ONLN) binary V= \
  DESTCPU="x64" \
  ARCH="x64" \
  VARIATION="glibc-217" \
  DISTTYPE="$disttype" \
  CUSTOMTAG="$customtag" \
  DATESTRING="$datestring" \
  COMMIT="$commit" \
  RELEASE_URLBASE="$release_urlbase" \
  CONFIG_FLAGS="$config_flags"

mv node-*.tar.?z /out/
