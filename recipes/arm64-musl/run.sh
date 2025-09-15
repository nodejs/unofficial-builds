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

major=$(echo ${fullversion} | cut -d . -f 1 | tr -d v)

# Patch needed to support cross compilation for arm64 on amd64 for node 16 and 18.
# The PR introducing the issue (https://github.com/nodejs/node/pull/43200) was merged in main released in v20 and backported to v18 (https://github.com/nodejs/node/pull/44353) and v16 (https://github.com/nodejs/node/pull/44886)
# The fix for the issue (https://github.com/nodejs/node/pull/51256) was only merged into v20 (https://github.com/nodejs/node/pull/52793)
# Therefore the fix needs to be re-applied to v16 and v18 if we want to compile those too.
# the initial patch works on v18, for v16 a reroll was required.
# @see https://github.com/nodejs/node/pull/51256
if [ "$major" == "18" ]; then
  wget -O /home/node/51256.diff https://patch-diff.githubusercontent.com/raw/nodejs/node/pull/51256.diff
  patch -p1 < /home/node/51256.diff || true
elif [ "$major" == "16" ]; then
  patch -p1 < /home/node/51256-v16.diff || true
  rm /home/node/51256-v16.diff
fi

# Patch needed so we can depend on newer Python versions for older NodeJS versions.
# This allows us to use the same Dockerfile and Alpine version.
if [ "$major" == "18" ] || [ "$major" == "16" ] ; then
  wget -O /home/node/50209.diff https://patch-diff.githubusercontent.com/raw/nodejs/node/pull/50209.diff
  patch -p1 < /home/node/50209.diff || true
fi

# For v16, and additional patch is needed to replace the dependency on distutils, as it was removed in Python 3.12
# There is both usage of distutils in node itself, and in the gyp dependency.
# This also requires the packaging module, which is installed in the Dockerfile (see py3-packaging)
if [ "$major" == "16" ] ; then
  wget -O /home/node/50582.diff https://patch-diff.githubusercontent.com/raw/nodejs/node/pull/50582.diff
  patch -p1 < /home/node/50582.diff || true

  wget -O /home/node/2888.diff https://patch-diff.githubusercontent.com/raw/nodejs/node-gyp/pull/2888.diff
  patch -d tools -p1 < /home/node/2888.diff
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
