#!/bin/bash -xe

__dirname=$1
fullversion=$2

. ${__dirname}/_decode_version.sh

decode "$fullversion"

# v20 does not build successfully with clang19
test "$major" -ge "22"
