#!/bin/bash -xe

__dirname=$1
fullversion=$2

. ${__dirname}/_decode_version.sh

decode "$fullversion"

[ "$major" -ge 14 ] || ( [ "$major" -eq 13 ] && [ "$minor" -ge 4 ] )  # Pointer compression is supported since Node.js v13.4
[ "$major" -ne 17 ]                                                   # GCC version between 4.8.5 and 12.1 is required but not installed
[ "$major" -ne 20 ] || [ "$minor" -le 16 ]                            # Pointer compression does not work in Node.js v20.17~v20.19
[[ ! "$fullversion" =~ ^v(23|24\.[0-1]\.) ]]                          # Pointer compression does not work in Node.js v23.0~v24.1
