#!/bin/bash

# Take a standard Node.js version string from any release type and deduce the variables
# that were used to compile it

# Normal usage would include this file: . ./_decode_version.sh
# and the environment variables below would be set in the current context

# execute with $TEST defined to run the tests, i.e. TEST= ./_decode_version.sh 

decode() {
  local fullversion="$1"

  disttype=
  customtag=
  datestring=
  commit=
  release_urlbase=

  if [[ "$fullversion" =~ ^v([0-9]+\.[0-9]+\.[0-9]+)+(:?-(nightly|rc|test)(\.([0-9])+|([0-9]{8})(.+)))?$ ]]; then
    version="${BASH_REMATCH[1]}"
    disttype="${BASH_REMATCH[3]}"
    if [[ "$disttype" = "" ]]; then
      disttype="release"
      customtag=""
      datestring=""
      commit=""
    elif [[ "$disttype" = "rc" ]]; then
      customtag="rc.${BASH_REMATCH[5]}"
      datestring=""
      commit=""
    else
      customtag=""
      datestring="${BASH_REMATCH[6]}"
      commit="${BASH_REMATCH[7]}"
    fi

    if [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
      major="${BASH_REMATCH[1]}"
      minor="${BASH_REMATCH[2]}"
      patch="${BASH_REMATCH[3]}"
    fi

    release_urlbase="https://nodejs.org/download/${disttype}/"
    source_urlbase="${release_urlbase}${fullversion}"
    source_url="${source_urlbase}/node-${fullversion}.tar.xz"
    # this is just an unfortunate artifact of history, most disttypes that are not nightly or release
    # go through "custom" but pop out the other end in special directories, see Node's Makefile and
    # the www dist "promote" scripts in nodejs/build
    disttype_promote="$disttype"
    if [[ "$disttype" =~ ^(rc|test)$ ]]; then
      disttype="custom"
    fi
  else
    echo "Unknown version: $fullversion"
    exit 1
  fi
}

# from https://github.com/torokmark/assert.sh/blob/master/assert.sh
assert_eq() {
  local expected="$1"
  local actual="$2"

  if [ "$expected" == "$actual" ]; then
    return 0
  else
    echo "fail: $expected == $actual" || true
    #return 1
    exit 1
  fi
}

if [ ! -z ${TEST+x} ]; then
  decode "v11.12.0"
  assert_eq "11.12.0" "$version"
  assert_eq "release" "$disttype"
  assert_eq "release" "$disttype_promote"
  assert_eq "" "$customtag"
  assert_eq "" "$datestring"
  assert_eq "" "$commit"
  assert_eq "https://nodejs.org/download/release/" "$release_urlbase"
  assert_eq "https://nodejs.org/download/release/v11.12.0" "$source_urlbase"
  assert_eq "https://nodejs.org/download/release/v11.12.0/node-v11.12.0.tar.xz" "$source_url"

  decode "v10.9.0-nightly20171102d4471e06e8"
  assert_eq "10.9.0" "$version"
  assert_eq "nightly" "$disttype"
  assert_eq "nightly" "$disttype_promote"
  assert_eq "" "$customtag"
  assert_eq "20171102" "$datestring"
  assert_eq "d4471e06e8" "$commit"
  assert_eq "https://nodejs.org/download/nightly/" "$release_urlbase"
  assert_eq "https://nodejs.org/download/nightly/v10.9.0-nightly20171102d4471e06e8" "$source_urlbase"
  assert_eq "https://nodejs.org/download/nightly/v10.9.0-nightly20171102d4471e06e8/node-v10.9.0-nightly20171102d4471e06e8.tar.xz" "$source_url"

  decode "v12.0.0-nightly201904208d901bb44e"
  assert_eq "12.0.0" "$version"
  assert_eq "nightly" "$disttype"
  assert_eq "" "$customtag"
  assert_eq "20190420" "$datestring"
  assert_eq "8d901bb44e" "$commit"
  assert_eq "https://nodejs.org/download/nightly/" "$release_urlbase"

  decode "v6.4.1-nightly20160822a146e683dd"
  assert_eq "6.4.1" "$version"
  assert_eq "nightly" "$disttype"
  assert_eq "" "$customtag"
  assert_eq "20160822" "$datestring"
  assert_eq "a146e683dd" "$commit"
  assert_eq "https://nodejs.org/download/nightly/" "$release_urlbase"

  decode "v10.0.0-rc.0"
  assert_eq "10.0.0" "$version"
  assert_eq "custom" "$disttype"
  assert_eq "rc" "$disttype_promote"
  assert_eq "rc.0" "$customtag"
  assert_eq "" "$datestring"
  assert_eq "" "$commit"
  assert_eq "https://nodejs.org/download/rc/" "$release_urlbase"
  assert_eq "https://nodejs.org/download/rc/v10.0.0-rc.0" "$source_urlbase"
  assert_eq "https://nodejs.org/download/rc/v10.0.0-rc.0/node-v10.0.0-rc.0.tar.xz" "$source_url"

  decode "v6.12.0-rc.4"
  assert_eq "6.12.0" "$version"
  assert_eq "custom" "$disttype"
  assert_eq "rc.4" "$customtag"
  assert_eq "" "$datestring"
  assert_eq "" "$commit"
  assert_eq "https://nodejs.org/download/rc/" "$release_urlbase"

  decode "v12.0.0-rc.2"
  assert_eq "12.0.0" "$version"
  assert_eq "custom" "$disttype"
  assert_eq "rc.2" "$customtag"
  assert_eq "" "$datestring"
  assert_eq "" "$commit"
  assert_eq "https://nodejs.org/download/rc/" "$release_urlbase"
  assert_eq "https://nodejs.org/download/rc/v12.0.0-rc.2" "$source_urlbase"
  assert_eq "https://nodejs.org/download/rc/v12.0.0-rc.2/node-v12.0.0-rc.2.tar.xz" "$source_url"

  decode "v12.0.1-test201904152fed83dee8"
  assert_eq "12.0.1" "$version"
  assert_eq "custom" "$disttype"
  assert_eq "test" "$disttype_promote"
  assert_eq "" "$customtag"
  assert_eq "20190415" "$datestring"
  assert_eq "2fed83dee8" "$commit"
  assert_eq "https://nodejs.org/download/test/" "$release_urlbase"
  assert_eq "https://nodejs.org/download/test/v12.0.1-test201904152fed83dee8" "$source_urlbase"
  assert_eq "https://nodejs.org/download/test/v12.0.1-test201904152fed83dee8/node-v12.0.1-test201904152fed83dee8.tar.xz" "$source_url"

  decode "v12.0.0-test20190116irp-mode-implementation"
  assert_eq "12.0.0" "$version"
  assert_eq "custom" "$disttype"
  assert_eq "" "$customtag"
  assert_eq "20190116" "$datestring"
  assert_eq "irp-mode-implementation" "$commit"
  assert_eq "https://nodejs.org/download/test/" "$release_urlbase"
fi
