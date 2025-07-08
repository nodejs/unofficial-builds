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

! ( isNodeVersionGE 'v17.0'  && isNodeVersionLT 'v18.0'  )  # GCC version between 4.8.5 and 12.1 is required but not installed
! ( isNodeVersionGE 'v22.2'  && isNodeVersionLT 'v22.3'  )  # GCC version between 12.1  and 15.1 is required but not installed
