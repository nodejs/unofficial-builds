#!/bin/bash -xe

__dirname=$1
fullversion=$2

. ${__dirname}/_decode_version.sh

decode "$fullversion"

test "$major" -ge "17" && test "$major" -ne "24" && test "$major" -ne 26
