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
make_flags=""

alpineArch="$(apk --print-arch)"
case "${alpineArch##*-}" in
  riscv64)
    config_flags+="--openssl-no-asm"
    ;;
  loongarch64)
    # v18.x need, https://github.com/nodejs/node/blob/v18.x/Makefile#L939
    make_flags+=" DESTCPU=loong64 ARCH=loong64"
    config_flags+="--openssl-no-asm"
    ;;
esac

cd /home/node

tar -xf node.tar.xz
cd "node-${fullversion}"

export CC="ccache gcc"
export CXX="ccache g++"

make_flags+=" \
  VARIATION=musl \
  DISTTYPE=$disttype \
  CUSTOMTAG=$customtag \
  DATESTRING=$datestring \
  COMMIT=$commit \
  RELEASE_URLBASE=$release_urlbase \
  CONFIG_FLAGS=$config_flags"

make -j$(getconf _NPROCESSORS_ONLN) binary V= $make_flags

mv node-*.tar.?z /out/
