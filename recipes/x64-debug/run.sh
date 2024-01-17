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
config_flags="--gdb --debug --debug-node"

cd /home/node

tar -xf node.tar.xz
cd "node-${fullversion}"

export CC="ccache gcc"
export CXX="ccache g++"

make -j$(getconf _NPROCESSORS_ONLN) binary V= \
  DESTCPU="x64" \
  ARCH="x64" \
  VARIATION="debug" \
  DISTTYPE="$disttype" \
  CUSTOMTAG="$customtag" \
  DATESTRING="$datestring" \
  COMMIT="$commit" \
  RELEASE_URLBASE="$release_urlbase" \
  CONFIG_FLAGS="$config_flags"

# The default tarballs from the binary make target do not have the debug
# binary included so we need to rebuild them correctly.
for tarball in node-*.tar.?z; do
  # Create a temporary directory and extract the tarball into it
  temp_dir=$(mktemp -d)
  tar -xf "$tarball" -C "$temp_dir"

  # Copy the debug build to a different name
  cp out/Debug/node "$temp_dir/bin/node_g"

  # Recreate the tarball with the same comprbasession format
  case $tarball in
    *.tar.gz)
      tar -czf "/out/$tarball" -C "$temp_dir" .
      ;;
    *.tar.xz)
      tar -cJf "/out/$tarball" -C "$temp_dir" .
      ;;
  esac

  rm -rf "$temp_dir"
done
