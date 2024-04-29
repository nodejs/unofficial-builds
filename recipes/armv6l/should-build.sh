#!/bin/bash -xe

__dirname=$1
fullversion=$2

. ${__dirname}/_decode_version.sh

decode "$fullversion"

# TODO: Re-enable if a compatible compiler can be found
test "$major" -lt "22"
