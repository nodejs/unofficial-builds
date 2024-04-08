#!/bin/bash -xe

# The heart of the build process: given a valid Node.js version string,
# fetch the source file then build each type of asset using a pre-built
# docker image.

# Function to display usage and exit
usage_exit() {
  echo "Usage: $0 -v version [-r recipe ...]"
  exit "${1:-0}" # Exit with provided code or default to 0
}


# Setup file and directory paths
__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workdir=${workdir:-"${__dirname}/../.."}
ccachedir=$(realpath "${workdir}/.ccache")
stagingdir=$(realpath "${workdir}/staging")
distdir=$(realpath "${workdir}/download")
logdir=$(realpath "${workdir}/logs")


# Adds config variable and `recipe_exists` function to scope
source "${__dirname}/_config.sh"
# Adds decode function to scope to parse $fullversion below
source "${__dirname}/_decode_version.sh"


# Variable declaration
fullversion=""
recipes_to_build=()


# Parse options
while getopts "v:r:" opt; do
  case $opt in
    v)
      fullversion="$OPTARG"
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
if [ -z "$fullversion" ]; then
  usage_exit 1
fi
# see _decode_version.sh for all of the magic variables now set and available
# for use after decoding the $fullversion
decode "$fullversion"

# Point RELEASE_URLBASE to the Unofficial Builds server
unofficial_release_urlbase="https://unofficial-builds.nodejs.org/download/${disttype}/"

# If no recipes were passed via -r, build all recipes
if [ ${#recipes_to_build[@]} -eq 0 ]; then
  recipes_to_build=("${recipes[@]}")
fi

# Setup thislogdir so logs can be placed there. See comment below for more info
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
  -v "${sourcedir}:/out" \
  "${image_tag_pfx}fetch-source" \
  "$unofficial_release_urlbase" "$disttype" "$customtag" "$datestring" "$commit" "$fullversion" "$source_url" \
  > "${thislogdir}/fetch-source.log" 2>&1

# Build all other recipes
for recipe in "${recipes_to_build[@]}"; do
  # each recipe has 3 variable components:
  # - individual ~/.ccache directory
  # - a ~/node.tar.xz file that fetch-source has downloaded
  # - an output /out directory that puts generated assets into a staging directory
  ccachemount="${ccachedir}/${recipe}/:/home/node/.ccache/"
  mkdir -p "${ccachedir}/${recipe}"
  sourcemount="${sourcefile}:/home/node/node.tar.xz"
  stagingmount="${stagingoutdir}:/out"

  shouldbuild="${recipes_dir}/$recipe/should-build.sh"

  if [ -f "$shouldbuild" ]; then
    if ! "$shouldbuild" "$__dirname" "$fullversion"; then
      continue
    fi
  fi

  # each recipe logs to its own log file in the $thislogdir directory
  docker run --rm \
    -v "$ccachemount" -v "$sourcemount" -v "$stagingmount" \
    "${image_tag_pfx}${recipe}" \
    "$unofficial_release_urlbase" "$disttype" "$customtag" "$datestring" "$commit" "$fullversion" "$source_url" \
    > "${thislogdir}/${recipe}.log" 2>&1 || echo "Failed to build recipe for ${recipe}"

  # Total runtime can be up to 10hr for a full recipe so do promotion and
  # updateing of indexes after each build so dont have to wait for all builds
  # to finish before consumers can use the assets
  #
  # promote all assets in staging
  mv "${stagingoutdir}"/node-v* "${distoutdir}"
  # generate SHASUM256.txt
  (cd "$distoutdir" && shasum -a256 $(ls node* 2> /dev/null) > SHASUMS256.txt) || exit 1
  echo "Generating indexes (this may error if there is no upstream tag for this build)"
  # index.json and index.tab
  npm exec nodejs-dist-indexer@${dist_indexer_version} --yes -- --dist "$distdir_promote" --indexjson "${distdir_promote}/index.json"  --indextab "${distdir_promote}/index.tab" || true
done

echo "Finished build @ $(date)"

} > "${thislogdir}/build.log" 2>&1
