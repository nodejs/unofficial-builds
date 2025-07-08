#!/bin/bash -xe

__dirname=$1
fullversion=$2

isNodeVersionGE() {
	printf "$1\n$fullversion" | sort -VC
}

isNodeVersionLT() {
	! printf "$1\n$fullversion" | sort -VC
}

isNodeVersionGE 'v6.2'                                # Node.js v6.1- cannot download required files due to broken links

isNodeVersionLT 'v17.0'  || isNodeVersionGE 'v18.0'   # Node.js v17   requires GCC version between 4.8.5 and 12.1 which is not installed
isNodeVersionLT 'v22.2'  || isNodeVersionGE 'v22.3'   # Node.js v22.2 requires GCC version between 12.1  and 15.1 which is not installed
