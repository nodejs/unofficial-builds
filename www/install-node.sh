#!/bin/bash

# install-node.sh: download and install an official Node.js build from
# nodejs.org, or an unofficial-builds.nodejs.org build for some platforms the
# official project does not cover (musl/Alpine, ARMv6/Raspberry Pi, RISC-V,
# LoongArch, old-glibc x64 systems). YMMV, caveat emptor, etc.
#
# The download is verified against the publisher's SHASUMS256.txt before
# anything is written to the target directory.
#
# Home: https://github.com/nodejs/unofficial-builds
# Usage: install-node.sh [options]   (see --help)

set -euo pipefail

official=nodejs.org
unofficial=unofficial-builds.nodejs.org

disttype=release
line=""
platform=""
targetdir=/usr/local
assumeyes=""
dryrun=""

usage() {
  cat <<EOF
Usage: install-node.sh [options]
  -l, --line <prefix>      match a version prefix, e.g. --line 22 or --line 22.1
  -n, --nightly            install the latest nightly instead of a release
  -r, --rc                 install the latest release candidate
  -p, --platform <name>    force a platform variant instead of auto-detecting,
                           e.g. x64-glibc-217, x64-musl, arm64-musl, x64,
                           armv6l, riscv64, loong64
  -d, --dir <path>         install prefix (default: /usr/local)
  -y, --yes                install without prompting
      --dry-run            resolve and print the download URL, install nothing
  -h, --help               this text

The target directory must be writable (use sudo for /usr/local).
EOF
}

err() { echo "install-node.sh: $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -l|--line)     line="${2:?--line requires a value}"; shift 2;;
    -n|--nightly)  disttype=nightly; shift;;
    -r|--rc)       disttype=rc; shift;;
    -p|--platform) platform="${2:?--platform requires a value}"; shift 2;;
    -d|--dir)      targetdir="${2:?--dir requires a value}"; shift 2;;
    -y|--yes)      assumeyes=y; shift;;
    --dry-run)     dryrun=y; shift;;
    -h|--help)     usage; exit 0;;
    *)             usage >&2; err "unknown option: $1";;
  esac
done

# ---- platform detection -----------------------------------------------------

os=$(uname | tr '[:upper:]' '[:lower:]')
machine=$(uname -m)

# what libc is the running system actually using (a musl loader merely being
# installed does not make this a musl system)
is_musl() {
  ldd /bin/sh 2> /dev/null | grep -q musl
}

# glibc older than the official builds' floor needs the glibc-217 variant
glibc_too_old() {
  command -v getconf > /dev/null || return 1
  local ver
  ver=$(getconf GNU_LIBC_VERSION 2> /dev/null | awk '{ print $2 }') || return 1
  [ -n "$ver" ] && [ "$(printf '2.28\n%s\n' "$ver" | sort -V | head -1)" != "2.28" ]
}

if [ -z "$platform" ]; then
  case "$os" in
    linux)
      case "$machine" in
        x86_64)
          if is_musl; then
            platform=x64-musl
          elif glibc_too_old; then
            platform=x64-glibc-217
          else
            platform=x64
          fi
          ;;
        aarch64|arm64)
          if is_musl; then platform=arm64-musl; else platform=arm64; fi
          ;;
        armv6l)          platform=armv6l;;
        armv7l)          platform=armv7l;;
        riscv64)         platform=riscv64;;
        loongarch64)     platform=loong64;;
        ppc64le)         platform=ppc64le;;
        s390x)           platform=s390x;;
        *) err "unsupported architecture: $machine (use --platform to force a variant)";;
      esac
      ;;
    darwin)
      case "$machine" in
        x86_64) platform=x64;;
        arm64)  platform=arm64;;
        *) err "unsupported architecture: $machine";;
      esac
      ;;
    *) err "unsupported OS: $os (Linux and macOS only)";;
  esac
fi

# unofficial-builds hosts the variants nodejs.org does not
case "$platform" in
  *musl*|*glibc-217*|*pointer-compression*|*debug*|armv6l|riscv64*|loong64|x86)
    domain=$unofficial;;
  *)
    domain=$official;;
esac

# ---- version resolution -----------------------------------------------------

indexurl="https://${domain}/download/${disttype}/index.tab"

# the index's files column says which platforms each version was built for;
# resolve to the newest version that actually has ours
case "$os" in
  darwin) filetoken="osx-${platform}-tar";;
  *)      filetoken="${os}-${platform}";;
esac

latest=$(curl -fsSL "$indexurl" | awk -v line="^v${line}" -v tok="(^|,)${filetoken}(,|$)" \
  '!found && $1 ~ /^v[0-9]/ && $1 ~ line && $3 ~ tok { print $1; found = 1 }') || true
[ -n "${latest:-}" ] || err "no ${disttype} version matching '${line:-any}' with a ${filetoken} build found at ${indexurl}"

have_xz=""
command -v xzcat > /dev/null && have_xz=y
if [ -n "$have_xz" ]; then
  tarball="node-${latest}-${os}-${platform}.tar.xz"
else
  tarball="node-${latest}-${os}-${platform}.tar.gz"
fi
urlbase="https://${domain}/download/${disttype}/${latest}"
url="${urlbase}/${tarball}"

if [ -n "$dryrun" ]; then
  echo "$url"
  exit 0
fi

# ---- confirm ----------------------------------------------------------------

echo "Node.js ${latest} ${os}-${platform} (${disttype}) from ${domain}"
echo "  -> ${targetdir}"
if [ -z "$assumeyes" ]; then
  # when piped into bash, stdin is this script; the prompt needs the terminal
  [ -t 0 ] || exec < /dev/tty || err "no terminal to confirm from, use --yes"
  printf 'Download and install? [y/N] '
  read -r yorn
  case "$yorn" in y|Y|yes|YES) ;; *) echo "aborted"; exit 1;; esac
fi

# ---- download, verify, install ----------------------------------------------

[ -d "$targetdir" ] && [ -w "$targetdir" ] || err "${targetdir} is not a writable directory"

tmp=$(mktemp -d "${TMPDIR:-/tmp}/install-node.XXXXXX") || err "could not create a temporary directory"
# ${tmp:?} guarantees this can never expand to rm -rf ""
trap 'rm -rf "${tmp:?}"' EXIT

echo "Downloading ${url}..."
progress="-sS"
[ -t 2 ] && progress="--progress-bar"
curl -fL $progress -o "${tmp}/${tarball}" "$url" \
  || err "download failed; ${domain} may not host ${platform} for ${latest} (see ${urlbase}/)"

curl -fsSL -o "${tmp}/SHASUMS256.txt" "${urlbase}/SHASUMS256.txt" \
  || err "SHASUMS256.txt not found at ${urlbase}/, refusing to install unverified download"

# sha256sum on Linux, shasum on macOS; both accept `sha256 filename` lines on stdin
sha256_check() {
  if command -v sha256sum > /dev/null; then
    sha256sum -c - > /dev/null
  else
    shasum -a 256 -c - > /dev/null
  fi
}
(cd "$tmp" && grep " ${tarball}\$" SHASUMS256.txt | sha256_check) \
  || err "checksum verification failed for ${tarball}"
echo "Checksum verified against ${urlbase}/SHASUMS256.txt"

if [ -n "$have_xz" ]; then
  xzcat "${tmp}/${tarball}"
else
  gzip -dc "${tmp}/${tarball}"
fi | tar -x -C "$targetdir" \
  --strip-components=1 \
  --exclude '*/CHANGELOG.md' --exclude '*/README.md' --exclude '*/LICENSE'

if installed=$("${targetdir}/bin/node" --version 2> /dev/null); then
  echo "Installed Node.js ${installed} to ${targetdir}"
else
  echo "Installed to ${targetdir}, but ${targetdir}/bin/node does not run on this system"
  case "$platform" in
    *musl*) echo "musl builds need libstdc++: apk add libstdc++";;
  esac
  exit 1
fi
