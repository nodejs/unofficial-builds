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
cd "node-${fullversion}"

export CCACHE_BASEDIR="$PWD"
export CC_host="ccache gcc"
export CXX_host="ccache g++"
export CC="ccache /opt/aarch64-linux-musl-cross/bin/aarch64-linux-musl-gcc"
export CXX="ccache /opt/aarch64-linux-musl-cross/bin/aarch64-linux-musl-g++ -static-libstdc++"
# The musl-cross-make-built toolchain has no specs file injecting
# -Wl,--build-id like distro-packaged cross-compilers do, so without this the
# resulting binary has no .note.gnu.build-id section and no PT_NOTE program
# header. That breaks postject-based SEA tooling, which relies on
# dl_iterate_phdr finding a PT_NOTE segment to extend.
# Refs: https://github.com/nodejs/unofficial-builds/issues/200
export LDFLAGS="-Wl,--build-id=sha1"

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
