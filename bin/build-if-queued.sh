#!/bin/bash

# A wrapper around `build.sh` that uses the pulls from the build queue and provides
# some locking facilities so it can be used directly and via a periodic runner without
# conflicts.

__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${__dirname}/_config.sh"
source "${__dirname}/_lock.sh"
source "${__dirname}/_decode_version.sh"

# quick checks before we bother with locks
if [ ! -f "$queuefile" ]; then
  exit 0
fi
if [ "$(wc -l $queuefile | cut -f1 -d' ')" = "0" ]; then
  exit 0
fi 

# another build is running, bail early
exit_if_locked "node-build"
acquire_lock "node-build"

# next build from the queue
version_and_recipes="$("${__dirname}/queue-pop.sh")"

if [ "X$version_and_recipes" != "X" ]; then
  # split the version and recipes
  IFS='|' read -r fullversion recipes_list <<< "$version_and_recipes"
  
  decode "$fullversion"

  cmd_args=("-v" "$fullversion")

  # Check if recipes_list is not empty
  if [[ -n "$recipes_list" ]]; then
    # split comma separated list of recipes_to_build
    IFS=',' read -ra recipes_to_build <<< "$recipes_list"
    for recipe in "${recipes_to_build[@]}"; do
      # Construct the recipes_args as part of the command string
      cmd_args+=("-r" "$recipe")
    done
  fi

  # only "release" versions are guaranteed to have source files available when they appear
  # in the indexes, the others promote components as they are available and source has a
  # lower priority
  # so if source doesn't exist, re-queue it and it'll be tried again next time, it's possible
  # that a version gets stuck in the queue and this `curl` to be run over and over
  # but since it's a FIFO it shouldn't prevent others from running
  if curl --output /dev/null --silent --head --fail $source_url; then
    "${__dirname}/build.sh" "${cmd_args[@]}"
  else
    echo "Source file for ${fullversion} does not exist, queueing for retry"
    "${__dirname}/queue-push.sh" "${cmd_args[@]}"
  fi
fi

release_lock
