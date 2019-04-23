#!/bin/bash

# Get the next version to be built off the queue

__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
queuefile="$(realpath ${__dirname}/../../var/build_queue)"

if [ ! -f $queuefile ]; then
  exit 0
fi

. ${__dirname}/_lock.sh

acquire_lock "build_queue"
version="$(head -1 $queuefile)"
if [ "X$version" != "X" ]; then
  queuetmp="$(mktemp /tmp/queuefile.XXXX)"
  tail -n +2 $queuefile > $queuetmp
  mv $queuetmp $queuefile
fi
release_lock

if [ "X$version" != "X" ]; then
  echo "$version"
fi
