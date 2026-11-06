#!/usr/bin/env bash
set -e
set -x

release_urlbase="$1"
disttype="$2"
customtag="$3"
datestring="$4"
commit="$5"
fullversion="$6"
config_flags="--cross-compiling --experimental-enable-pointer-compression"

cd /home/node

tar -xf node.tar.xz
cd "node-${fullversion}"

# configure reads the numeric default in node_version.h for config.gypi.
# The runtime and the headers shipped to addon authors use the same definition.
major=${fullversion%%.*}
major=${major#v}
stock_abi=$(python3 tools/getmoduleversion.py)
# Proposed registry allocations. Confirm these before enabling server builds.
case "$major:$stock_abi" in
  22:127) module_abi=155 ;;
  24:137) module_abi=156 ;;
  26:147) module_abi=157 ;;
  *) echo "No ARM64 pointer-compression ABI for $fullversion (stock ABI $stock_abi)" >&2; exit 1 ;;
esac
sed -i "s/^#define NODE_MODULE_VERSION ${stock_abi}$/#define NODE_MODULE_VERSION ${module_abi}/" src/node_version.h
test "$(python3 tools/getmoduleversion.py)" = "$module_abi"

export CCACHE_BASEDIR="$PWD"
export CC_host="ccache gcc-14"
export CXX_host="ccache g++-14"
export CC="ccache aarch64-linux-gnu-gcc-14"
export CXX="ccache aarch64-linux-gnu-g++-14"

# Require Temporal on Node 26+ so configure fails if the Rust toolchain is missing.
if [ "$major" -ge 26 ]; then
  config_flags="$config_flags --v8-enable-temporal-support"
fi

# Link each GYP toolset with the archive the Cargo shim built for it.
if [ -f deps/crates/crates.gyp ]; then
  python3 - <<'GYPPATCH'
import re
from pathlib import Path

path = Path('deps/crates/crates.gyp')
pattern = r"'link_settings':\s*\{\s*'libraries':\s*\[\s*'<\(node_crates_libpath\)',\s*\]"
replacement = """'link_settings': {
        'target_conditions': [
          ['_toolset=="host"', {
            'libraries': ['<(SHARED_INTERMEDIATE_DIR)/x86_64-unknown-linux-gnu/release/libnode_crates.a'],
          }],
          ['_toolset=="target"', {
            'libraries': ['<(SHARED_INTERMEDIATE_DIR)/aarch64-unknown-linux-gnu/release/libnode_crates.a'],
          }],
        ]"""
patched, count = re.subn(pattern, replacement, path.read_text(), count=1)
assert count == 1, 'crates.gyp link_settings pattern not found'
path.write_text(patched)
GYPPATCH
fi

make -j"$(getconf _NPROCESSORS_ONLN)" binary V= \
  DESTCPU="arm64" \
  ARCH="arm64" \
  VARIATION="pointer-compression" \
  DISTTYPE="$disttype" \
  CUSTOMTAG="$customtag" \
  DATESTRING="$datestring" \
  COMMIT="$commit" \
  RELEASE_URLBASE="$release_urlbase" \
  CONFIG_FLAGS="$config_flags"

mv node-*.tar.?z /out/
