#!/bin/bash

# Put a new version into the build queue

__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
queuefile="$(realpath ${__dirname}/../../var/build_queue)"

. ${__dirname}/_lock.sh
version="$1"
if [ "X$version" = "X" ]; then
  echo "Usage: queue-push.sh <version>"
  exit 1
fi

echo "Queuing $version"

acquire_lock "build_queue"
echo $version >> $queuefile
release_lock

