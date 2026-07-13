#!/bin/sh

# Node's gyp runs one shared cargo action for both toolsets, but mksnapshot
# (host) and node (target) each need their own architecture's crates. Build
# both triples; run.sh patches crates.gyp to point each toolset at its own.
# Upstream does per-platform target selection for Windows in
# deps/crates/cargo_build.py; Linux cross-compilation has no equivalent yet.
set -e

HOST_TRIPLE=x86_64-unknown-linux-musl
CROSS_TRIPLE=aarch64-unknown-linux-musl
CARGO=/opt/rust/bin/cargo
export PATH="/opt/rust/bin:$PATH"

targetdir=""
prev=""
for arg in "$@"; do
  if [ "$prev" = "--target-dir" ]; then
    targetdir="$arg"
  fi
  prev="$arg"
done

# only gyp's build invocations pass --target-dir; everything else (e.g.
# `cargo --version` from node's configure) passes through untouched
if [ -z "$targetdir" ]; then
  exec "$CARGO" "$@"
fi

"$CARGO" "$@" --target "$HOST_TRIPLE"
"$CARGO" "$@" --target "$CROSS_TRIPLE"

# gyp's action output is the triple-less path; satisfy its freshness check
if [ -n "$targetdir" ]; then
  for profile in release debug; do
    if [ -f "${targetdir}/${CROSS_TRIPLE}/${profile}/libnode_crates.a" ]; then
      mkdir -p "${targetdir}/${profile}"
      cp "${targetdir}/${CROSS_TRIPLE}/${profile}/libnode_crates.a" "${targetdir}/${profile}/"
    fi
  done
fi
