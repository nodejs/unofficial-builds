#!/bin/bash -xe

# The heart of the build process: given a valid Node.js version string,
# fetch the source file then build each type of asset using a pre-built
# docker image

__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workdir=${workdir:-"$__dirname"/../..}
image_tag_pfx=unofficial-build-recipe-
# all of our build recipes, new recipes just go into this list,
recipes=" \
  headers \
  x86 \
  musl \
  armv6l \
  armv6l-pre16 \
  arm64-glibc-217 \
  x64-glibc-217 \
  x64-pointer-compression \
  x64-usdt \
  riscv64 \
"
ccachedir=$(realpath "${workdir}/.ccache")
stagingdir=$(realpath "${workdir}/staging")
distdir=$(realpath "${workdir}/download")
logdir=$(realpath "${workdir}/logs")

if [[ "X${1}" = "X" ]]; then
  echo "Please supply a Node.js version string"
  exit 1
fi

fullversion="$1"
. ${__dirname}/_decode_version.sh
decode "$fullversion"
# see _decode_version for all of the magic variables now set and available for use

# Point RELEASE_URLBASE to the Unofficial Builds server
unofficial_release_urlbase="https://unofficial-builds.nodejs.org/download/${disttype}/"

thislogdir="${logdir}/$(date -u +'%Y%m%d%H%M')-${fullversion}"
mkdir -p $thislogdir

echo "Logging to ${thislogdir}..."

# From here on, all stdout and stderr goes to ${thislogdir}/build.log so we can
# see it from the web @ unofficial-builds.nodejs.org/logs/

{

echo "Starting build @ $(date)"

sourcedir="${stagingdir}/src/${fullversion}"
mkdir -p $sourcedir
sourcefile="${sourcedir}/node-${fullversion}.tar.xz"
stagingoutdir="${stagingdir}/${disttype_promote}/${fullversion}"
mkdir -p $stagingoutdir
distdir_promote="${distdir}/${disttype_promote}"
distoutdir="${distdir_promote}/${fullversion}"
mkdir -p $distoutdir

# Build fetch-source, needs to be the first and must succeed
docker run --rm \
  -v ${sourcedir}:/out \
  "${image_tag_pfx}fetch-source" \
  "$unofficial_release_urlbase" "$disttype" "$customtag" "$datestring" "$commit" "$fullversion" "$source_url" \
  > ${thislogdir}/fetch-source.log 2>&1

# Build all other recipes
for recipe in $recipes; do
  # each recipe has 3 variable components:
  # - individual ~/.ccache directory
  # - a ~/node.tar.xz file that fetch-source has downloaded
  # - an output /out directory that puts generated assets into a staging directory
  ccachemount="-v ${ccachedir}/${recipe}/:/home/node/.ccache/"
  mkdir -p "${ccachedir}/${recipe}"
  sourcemount="-v ${sourcefile}:/home/node/node.tar.xz"
  stagingmount="-v ${stagingoutdir}:/out"

  shouldbuild="${__dirname}/../recipes/$recipe/should-build.sh"

  if [ -f "$shouldbuild" ]; then
    if ! "$shouldbuild" "$__dirname" "$fullversion"; then
      continue
    fi
  fi

  # each recipe logs to its own log file in the $thislogdir directory
  docker run --rm \
    ${ccachemount} ${sourcemount} ${stagingmount} \
    "${image_tag_pfx}${recipe}" \
    "$unofficial_release_urlbase" "$disttype" "$customtag" "$datestring" "$commit" "$fullversion" "$source_url" \
    > ${thislogdir}/${recipe}.log 2>&1 || echo "Failed to build recipe for ${recipe}"
done

# promote all assets in staging
mv ${stagingoutdir}/node-v* ${distoutdir}
# generate SHASUM256.txt
(cd "${distoutdir}" && shasum -a256 $(ls node* 2> /dev/null) > SHASUMS256.txt) || exit 1
echo "Generating indexes (this may error if there is no upstream tag for this build)"
# index.json and index.tab
npx nodejs-dist-indexer --dist ${distdir_promote} --indexjson ${distdir_promote}/index.json  --indextab ${distdir_promote}/index.tab || true

echo "Finished build @ $(date)"

} > ${thislogdir}/build.log 2>&1
