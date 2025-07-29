#!/bin/bash -xe

__dirname=$1
fullversion=$2

. ${__dirname}/_decode_version.sh

decode "$fullversion"

(test "$major" -eq "18" && test "$minor" -ge "18") || \
(test "$major" -eq "20" && test "$minor" -ge "10") || \
(test "$major" -eq "21") || \
(test "$major" -eq "22" && test "$minor" -ge "14") || \
(test "$major" -eq "23")
