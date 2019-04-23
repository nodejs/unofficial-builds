lockfile=""
lockfiletemp=""

# Some basic Bash locking utilities so we can don't have to worry about what's
# doing what, when

# acquire_lock "type" sets up a lock that will be released with release_lock
acquire_lock() {
  local locktype="$1"
  lockfile="/var/run/lock/${locktype}"
  lockfiletemp="$(mktemp /var/run/lock/${locktype}.XXXX)"

  # using symlinks as an atomic mechanism, if we can't get a link
  # to the lockfile then another process might be using it
  while ! ln -f $lockfiletemp $lockfile; do
    # check if another running process has the lock
    if [ -a "$lockfile" -a -r "$lockfile" ]; then
      read pid < "$lockfile"
      if [ -n "${pid:-}" ]; then
        while $(kill -0 "${pid:-}" 2> /dev/null); do
          sleep 1
        done
      fi
    fi
    rm $lockfile
  done
  echo $$ > $lockfile
}

# similar logic to `acquire_lock()` but implemented as a short-circuit if a lock is
# already in use
exit_if_locked() {
  local locktype="$1"
  lockfile="/var/run/lock/${locktype}"

  if [ -a "$lockfile" -a -r "$lockfile" ]; then
    read pid < "$lockfile"
    if [ -n "${pid:-}" ]; then
      if $(kill -0 "${pid:-}" 2> /dev/null); then
	      echo "process running"
        exit 0
      fi
    fi
  fi
}

# assumes that `acquire_lock()` has been called already
release_lock() {
  if [ "X${lockfile}${lockfiletemp}" != "X" ]; then
    rm -f $lockfile $lockfiletemp
  fi
}
