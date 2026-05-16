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

homeDir=/home/node
nodeDir="$homeDir/node-$fullversion"

tar --directory="$homeDir" -xf "$homeDir/node.tar.xz"

# configuring cares correctly to not use sys/random.h on this target
cd "$nodeDir/deps/cares"
sed -i 's/define HAVE_SYS_RANDOM_H 1/undef HAVE_SYS_RANDOM_H/g' ./config/linux/ares_config.h
sed -i 's/define HAVE_GETRANDOM 1/undef HAVE_GETRANDOM/g' ./config/linux/ares_config.h

# fix https://github.com/c-ares/c-ares/issues/850
if [[ "$(grep -o 'ARES_VERSION_STR "[^"]*"' ./include/ares_version.h | awk '{print $2}' | tr -d '"')" == "1.33.0" ]]; then
  sed -i 's/MSG_FASTOPEN/TCP_FASTOPEN_CONNECT/g' ./src/lib/ares__socket.c
fi

# Linux implementation of experimental WASM memory control requires Linux 3.17 & glibc 2.27 so disable it
cd "$nodeDir/deps/v8/src"
[ -f d8/d8.cc ] && sed -i -e 's/#if V8_TARGET_OS_LINUX/#if false/g' wasm/wasm-objects.cc d8/d8.cc

cd "$nodeDir"

export CCACHE_BASEDIR="$PWD"
export CC="ccache gcc"
export CXX="ccache g++"
export MAJOR_VERSION=$(echo ${fullversion} | cut -d . -f 1 | tr --delete v)

isNodeVersionGE() {
	printf "$1\n$fullversion" | sort -VC
}

source "$homeDir/run_other.sh"
source "$homeDir/run_versions.sh"

setPython
setGCC

make -j$(getconf _NPROCESSORS_ONLN) binary V= \
  DESTCPU="$destCPU" \
  ARCH="$arch" \
  VARIATION="$variation" \
  DISTTYPE="$disttype" \
  CUSTOMTAG="$customtag" \
  DATESTRING="$datestring" \
  COMMIT="$commit" \
  RELEASE_URLBASE="$release_urlbase" \
  CONFIG_FLAGS="$config_flags"

"$nodeDir/node" -p process.versions  # Make sure there is no "Segmentation fault" error  (example: node v21.0~v21.2 x64-pointer-compression)
mv node-*.tar.?z /out/
