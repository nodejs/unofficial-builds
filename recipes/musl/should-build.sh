#!/bin/bash -xe

__dirname=$1
fullversion=$2

. ${__dirname}/_decode_version.sh

decode "$fullversion"

# 26.11.0 shipped the official binaries, but can keep building on the older releases till the EOL
test "$major" -le 26
