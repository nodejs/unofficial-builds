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
config_flags=

cd /home/node

tar -xf node.tar.xz

# configuring cares correctly to not use sys/random.h on this target
cd "node-${fullversion}"/deps/cares/config/linux
sed -i 's/define HAVE_SYS_RANDOM_H 1/undef HAVE_SYS_RANDOM_H/g' ./ares_config.h
sed -i 's/define HAVE_GETRANDOM 1/undef HAVE_GETRANDOM/g' ./ares_config.h

cd /home/node

cd "node-${fullversion}"

export CC_host="ccache gcc-12 -m32"
export CXX_host="ccache g++-12 -m32"
export CC="ccache /opt/rpi-newer-crosstools/x64-gcc-12.3.0-glibc-2.28/arm-rpi-linux-gnueabihf/bin/arm-rpi-linux-gnueabihf-gcc -march=armv6zk"
export CXX="ccache /opt/rpi-newer-crosstools/x64-gcc-12.3.0-glibc-2.28/arm-rpi-linux-gnueabihf/bin/arm-rpi-linux-gnueabihf-g++ -march=armv6zk"

make -j$(getconf _NPROCESSORS_ONLN) binary V= \
  DESTCPU="arm" \
  ARCH="armv6l" \
  VARIATION="" \
  DISTTYPE="$disttype" \
  CUSTOMTAG="$customtag" \
  DATESTRING="$datestring" \
  COMMIT="$commit" \
  RELEASE_URLBASE="$release_urlbase" \
  CONFIG_FLAGS="$config_flags"

mv node-*.tar.?z /out/
