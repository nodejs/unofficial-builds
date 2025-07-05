#!/bin/bash -xe

__dirname=$1
fullversion=$2

. ${__dirname}/_decode_version.sh

decode "$fullversion"

[ "$major" -ge 7 ] || ( [ "$major" -eq 6 ] && [ "$minor" -ge 2 ] )  # Node.js v6.1- cannot download required files due to broken links
[[ ! "$fullversion" =~ ^v22\.[0-2]\. ]]                             # Not supported neigher by GCC 15.1 nor GCC 9.3 (GCC 12.4 would be good but is not installed)
