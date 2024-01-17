#!/bin/bash -xe

__dirname=$1
fullversion=$2

. ${__dirname}/_decode_version.sh

decode "$fullversion"

assert_eq "$disttype" "release"

test "$major" -ge "18"
