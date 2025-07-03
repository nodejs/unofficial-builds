#!/bin/bash -xe

__dirname=$1
fullversion=$2

. ${__dirname}/_decode_version.sh

decode "$fullversion"

[ "$major" -ge 14 ] || ( [ "$major" -eq 13 ] && [ "$minor" -ge 4 ] )
