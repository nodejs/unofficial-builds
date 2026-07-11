#!/usr/bin/env bash

set -e

__dirname=$1
fullversion=$2

isNodeVersionGE() {
	printf "$1\n$fullversion" | sort -VC
}

isNodeVersionLT() {
	! printf "$1\n$fullversion" | sort -VC
}

isNodeVersionGE 'v18.0'                               # published pre-v18 artifacts are immutable, do not rebuild them

isNodeVersionLT 'v17.0'  || isNodeVersionGE 'v18.0'   # Node.js v17   requires GCC version between 4.8.5 and 12.1 which is not installed
isNodeVersionLT 'v22.2'  || isNodeVersionGE 'v22.3'   # Node.js v22.2 requires GCC version between 12.1  and 15.1 which is not installed

isNodeVersionLT 'v27.0'                               # v24 and v26 verified on glibc 2.17; raise per new line after testing
