#!/bin/bash -xe

__dirname=$1
fullversion=$2

. ${__dirname}/_decode_version.sh

decode "$fullversion"

[ "$major" -ge 14 ] || ( [ "$major" -eq 13 ] && [ "$minor" -ge 4 ] )  # Pointer compression is supported since Node.js v13.4

[ "$major" -ne 17 ]                                                   # GCC version between 4.8.5 and 12.1 is required but not installed
[[ ! "$fullversion" =~ ^v22\.2\. ]]                                   # GCC version between 12.1  and 15.1 is required but not installed

[ "$major" -ne 20 ] || [ "$minor" -lt 17 ]                            # Pointer compression does not work in Node.js v20.17~v20.19 (Compilation error)
[[ ! "$fullversion" =~ ^v21\.[0-2]\. ]]                               # Pointer compression does not work in Node.js v21.0~v21.2   (Segmentation fault)
[ "$major" -ne 22 ] || [ "$minor" -lt 6 ] || [ "$minor" -gt 16 ]      # Pointer compression does not work in Node.js v22.6~v22.16  (Compilation error)
[[ ! "$fullversion" =~ ^v(23|24\.[0-1]\.) ]]                          # Pointer compression does not work in Node.js v23.0~v24.1   (Compilation error)
