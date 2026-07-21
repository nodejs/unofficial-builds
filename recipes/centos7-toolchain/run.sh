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
cd "$nodeDir"

setPython
setGCC

# Temporal needs the rust toolchain; a broken toolchain must fail configure
# loudly, not ship binaries that silently lack Temporal
if [ "$MAJOR_VERSION" -ge 26 ]; then
  config_flags="$config_flags --v8-enable-temporal-support"
fi

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

# Run without the GCC 15 runtime paths: the binary must work on a stock
# glibc 2.17 system, an LD_LIBRARY_PATH here would mask a bad dynamic link.
# Also catches segfaulting builds (example: v21.0~v21.2 x64-pointer-compression)
env -u LD_LIBRARY_PATH "$nodeDir/node" -p process.versions
# Test Temporal API for Node v26+
if [ "$MAJOR_VERSION" -ge 26 ]; then
  env -u LD_LIBRARY_PATH "$nodeDir/node" -e 'Temporal'
fi

# glibc 2.17 compatibility is the product: fail if the binary picked up a
# dependency on the GCC 15 runtime or a glibc symbol newer than the target
if env -u LD_LIBRARY_PATH ldd "$nodeDir/node" | grep /opt/gcc15; then
  echo "binary is dynamically linked against the GCC 15 runtime" >&2
  exit 1
fi
maxGlibc=$(objdump -T "$nodeDir/node" | grep -oE 'GLIBC_[0-9]+\.[0-9]+' | sort -uV | tail -1)
if [ "$(printf 'GLIBC_2.17\n%s\n' "$maxGlibc" | sort -V | tail -1)" != "GLIBC_2.17" ]; then
  echo "binary requires $maxGlibc, newer than the glibc 2.17 target" >&2
  exit 1
fi

mv node-*.tar.?z /out/
