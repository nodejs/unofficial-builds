#!/bin/bash -xe

__dirname=$1
fullversion=$2

isNodeVersionGE() {
	printf "$1\n$fullversion" | sort -VC
}

isNodeVersionLT() {
	! printf "$1\n$fullversion" | sort -VC
}

isNodeVersionGE 'v13.4'                                     # Pointer compression is supported since Node.js v13.4

! ( isNodeVersionGE 'v17.0'  && isNodeVersionLT 'v18.0'  )  # GCC version between 4.8.5 and 12.1 is required but not installed
! ( isNodeVersionGE 'v22.2'  && isNodeVersionLT 'v22.3'  )  # GCC version between 12.1  and 15.1 is required but not installed

! ( isNodeVersionGE 'v20.17' && isNodeVersionLT 'v21.0'  )  # Pointer compression does not work in Node.js v20.17~v20.19 (Compilation error)
! ( isNodeVersionGE 'v21.0'  && isNodeVersionLT 'v21.3'  )  # Pointer compression does not work in Node.js v21.0~v21.2   (Segmentation fault)
! ( isNodeVersionGE 'v22.6'  && isNodeVersionLT 'v22.17' )  # Pointer compression does not work in Node.js v22.6~v22.16  (Compilation error)
! ( isNodeVersionGE 'v23.0'  && isNodeVersionLT 'v24.2'  )  # Pointer compression does not work in Node.js v23.0~v24.1   (Compilation error)
