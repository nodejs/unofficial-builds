#!/bin/bash -xe

__dirname=$1
fullversion=$2

isNodeVersionGE() {
	printf "$1\n$fullversion" | sort -VC
}

isNodeVersionLT() {
	! printf "$1\n$fullversion" | sort -VC
}

isNodeVersionGE 'v6.2'                                      # Node.js v6.1- cannot download required files due to broken links

! ( isNodeVersionGE 'v22.0'  && isNodeVersionLT 'v22.3'  )  # GCC version between 9.3 and 15.1 is required but not installed
