#!/bin/bash -e

__dirname=$1
fullversion=$2

. "${__dirname}/_decode_version.sh"

decode "$fullversion"

# Earlier 22.x and 24.x releases have pointer-compression build failures.
# Add new release lines only after checking the cross-build and runtime.
case "$major" in
  22) test "$minor" -ge 17 ;;
  24) test "$minor" -ge 2 ;;
  26) exit 0 ;;
  *) exit 1 ;;
esac
