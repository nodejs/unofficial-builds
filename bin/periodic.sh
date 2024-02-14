#!/bin/bash

# Run periodically by a systemd timer, use it to check for new releases and
# record them in the queue, then run any builds that are queued

__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

disttypes="release rc"

for disttype in $disttypes; do
  for version in $("${__dirname}/check-releases.sh" $disttype); do
    "${__dirname}/queue-push.sh" -v $version
  done
done

"${__dirname}/build-if-queued.sh"
