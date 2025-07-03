#!/bin/bash -xe

__dirname=$1
fullversion=$2

. ${__dirname}/_decode_version.sh

decode "$fullversion"

[ "$major" -ge 7 ] || ( [ "$major" -eq 6 ] && [ "$minor" -ge 2 ] )
[[ ! "$fullversion" =~ ^v22\.[0-2]\. ]]
