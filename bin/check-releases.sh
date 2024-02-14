#!/bin/bash

# Given a disttype (release, rc, nightly, test), check for new releases on
# nodejs.org and print them to stdout.
# The first run of this file won't print anything but will save current state
# to ../../var/ so subsequent runs will pick up the difference.

__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
vardir="$(realpath "${__dirname}/../../var/")"

disttype="$1"
if [ "X$disttype" = "X" ]; then
  echo "Usage: check-releases.sh <disttype>"
  exit 1
fi

last_file="${vardir}/check-releases-${disttype}-latest-index.tab"
new_file="${vardir}/check-releases-${disttype}-new-index.tab"
index_tab_url="https://nodejs.org/download/${disttype}/index.tab"

function fetch_latest {
  curl -sL $index_tab_url | awk '{ print $1 }'
}

# first check
if ! test -e $last_file ; then
  fetch_latest > $last_file
  exit 0
fi

fetch_latest > $new_file

# no changes, or maybe there's weirdness
if [ $(wc -l $new_file | cut -d' ' -f1) -le $(wc -l $last_file | cut -d' ' -f1) ] ; then
  rm $new_file
  exit 0
fi

for new in $(diff $last_file $new_file | grep '>' | awk '{ print $2 }'); do
  echo $new
done

mv $new_file $last_file
