#!/bin/bash -xe

__dirname=$1
fullversion=$2

. ${__dirname}/_decode_version.sh

decode "$fullversion"

[ "$major" -ge 7  ] || ( [ "$major" -eq 6 ] && [ "$minor" -ge 2 ] )  # Node.js v6.1- cannot download required files due to broken links
[ "$major" -ne 17 ]                                                  # Not supported neigher by GCC 12.1 nor GCC 4.8.5 (works with GCC 9.3)
