#!/bin/bash -xe

__dirname=$1
fullversion=$2

isNodeVersionGE() {
	printf "$1\n$fullversion" | sort -VC
}

isNodeVersionLT() {
	! printf "$1\n$fullversion" | sort -VC
}

isNodeVersionGE 'v13.4'                               # Pointer compression is supported since Node.js v13.4

isNodeVersionLT 'v17.0'  || isNodeVersionGE 'v18.0'   # Node.js v17   requires GCC version between 4.8.5 and 12.1 which is not installed
isNodeVersionLT 'v22.2'  || isNodeVersionGE 'v22.3'   # Node.js v22.2 requires GCC version between 12.1  and 15.1 which is not installed

isNodeVersionLT 'v20.17' || isNodeVersionGE 'v21.0'   # Pointer compression does not work in Node.js v20.17~v20.19 (Compilation error)
isNodeVersionLT 'v21.0'  || isNodeVersionGE 'v21.3'   # Pointer compression does not work in Node.js v21.0~v21.2   (Segmentation fault)
isNodeVersionLT 'v22.6'  || isNodeVersionGE 'v22.17'  # Pointer compression does not work in Node.js v22.6~v22.16  (Compilation error)
isNodeVersionLT 'v23.0'  || isNodeVersionGE 'v24.2'   # Pointer compression does not work in Node.js v23.0~v24.1   (Compilation error)
