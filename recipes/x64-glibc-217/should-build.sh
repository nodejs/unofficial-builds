#!/bin/bash -xe

__dirname=$1
fullversion=$2

. ${__dirname}/_decode_version.sh

decode "$fullversion"

[ "$major" -ge 7  ] || ( [ "$major" -eq 6 ] && [ "$minor" -ge 2 ] )  # Node.js v6.1- cannot download required files due to broken links

[ "$major" -ne 17 ]                                                  # GCC version between 4.8.5 and 12.1 is required but not installed
[[ ! "$fullversion" =~ ^v22\.2\.) ]]                                 # GCC version between 12.1  and 15.1 is required but not installed
