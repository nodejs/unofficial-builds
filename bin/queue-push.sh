#!/bin/bash
#
#
# Put a new version into the build queue
#
#

# Function to display usage and exit
usage_exit() {
  echo "Usage: $0 -v version [-r recipe]"
  exit "${1:-0}" # Exit with provided code or default to 0
}

# Location of the build queue file
__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
queuefile="$(realpath ${__dirname}/../../var/build_queue)"

# Adds recipe_exists function to scope
. ${__dirname}/_get_recipes.sh

# Variable declaration
version=""
recipes_to_build=()

# Parse options
while getopts "v:r:" opt; do
  case $opt in
    v)
      version="$OPTARG"
      ;;
    r)
      if ! recipe_exists "$OPTARG"; then
        echo "Error: Recipe '$OPTARG' does not exist."
        usage_exit 1
      fi
      recipes_to_build+=("$OPTARG")
      ;;
    \?) 
      echo "Invalid option: -$OPTARG" >&2;
      usage_exit 1
      ;;
    :)
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      usage_exit
      ;;
  esac
done
shift $((OPTIND-1))

# Exit if no version was passed via -v
if [ -z "$version" ]; then
  usage_exit 1
fi

recipes_string="" # No recipes provided, default to all (handled later)
if [ ${#recipes_to_build[@]} -gt 0 ]; then
  recipes_string=$(IFS=,; echo "${recipes_to_build[*]}")
fi

# Acquire a lock on the build queue
. ${__dirname}/_lock.sh
acquire_lock "build_queue"

# Add the version (and optionally recipes) to the queue
echo "Queuing $version with recipes: ${recipes_string:-"all"}"
if [[ -n "$recipes_string" ]]; then
  echo "$version|$recipes_string" >> $queuefile
else
  echo "$version" >> $queuefile
fi

# Release the lock
release_lock

