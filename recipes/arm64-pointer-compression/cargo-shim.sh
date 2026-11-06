#!/bin/sh

set -e

HOST_TRIPLE=x86_64-unknown-linux-gnu
CROSS_TRIPLE=aarch64-unknown-linux-gnu
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

# Only GYP's build action passes --target-dir.
if [ -z "$targetdir" ]; then
  exec "$CARGO" "$@"
fi

# The host mksnapshot and the ARM64 node executable each need their own archive.
"$CARGO" "$@" --target "$HOST_TRIPLE"
"$CARGO" "$@" --target "$CROSS_TRIPLE"

# GYP checks for the action output in the profile directory.
for profile in release debug; do
  archive="$targetdir/$CROSS_TRIPLE/$profile/libnode_crates.a"
  if [ -f "$archive" ]; then
    mkdir -p "$targetdir/$profile"
    cp "$archive" "$targetdir/$profile/"
  fi
done
