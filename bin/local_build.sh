#!/bin/bash -e

usage_exit() {
  echo "Usage: $0 -r <recipe> -v <version> [-w <workdir>]"
  exit 1
}

## -- SETUP -- ##

__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# by default, workdir is the parent directory of the cloned repo
workdir=${workdir:-"$__dirname"/../..}
image_tag_pfx=unofficial-build-recipe-
recipe=""
fullversion=""

# parse command line options
while getopts ":w:r:v:" opt; do
  case ${opt} in
    w )
      workdir=$OPTARG
      ;;
    r )
      recipe=$OPTARG
      ;;
    v )
      fullversion=$OPTARG
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      usage_exit
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      usage_exit
      ;;
  esac
done
shift $((OPTIND -1))

if [[ -z "$recipe" ]]; then
  echo "Please supply a recipe name from the recipes directory"
  usage_exit
fi
if [[ -z "$fullversion" ]]; then
  echo "Please supply a Node.js version string"
  usage_exit
fi

# check that the recipe exists and has a Dockerfile
if [[ ! -d "${__dirname}/../recipes/${recipe}" ]]; then
  echo "Recipe ${recipe} does not exist"
  usage_exit
fi
if [[ ! -f "${__dirname}/../recipes/${recipe}/Dockerfile" ]]; then
  echo "Recipe ${recipe} does not have a Dockerfile"
  usage_exit
fi

. ${__dirname}/_decode_version.sh
decode "$fullversion"

workdir=$(realpath "${workdir}")
stagingdir="${workdir}/staging"
ccachedir="${workdir}/.ccache"
sourcedir="${stagingdir}/src/${fullversion}"
mkdir -p $sourcedir
sourcefile="${sourcedir}/node-${fullversion}.tar.xz"
stagingoutdir="${stagingdir}/${disttype_promote}/${fullversion}"
mkdir -p $stagingoutdir
mkdir -p $ccachedir

unofficial_release_urlbase="https://unofficial-builds.nodejs.org/download/${disttype}/"

## -- BUILD IMAGES -- ##

for r in "fetch-source" "${recipe}"; do
  echo "Building ${r} recipe and tagging as ${image_tag_pfx}${r}..."
  docker build ${__dirname}/../recipes/${r}/ -t ${image_tag_pfx}${r} --build-arg UID=$(id -u) --build-arg GID=$(id -g)
done

## -- DOWNLOAD SOURCE -- ##

if [[ ! -f "${sourcefile}" ]]; then
  echo "Downloading source tarball..."
  docker run --rm \
    --user=$(id -u) \
    -v ${sourcedir}:/out \
    "${image_tag_pfx}fetch-source" \
    "$unofficial_release_urlbase" "$disttype" "$customtag" "$datestring" "$commit" "$fullversion" "$source_url"
  echo "Done, source tarball is at ${sourcefile}"
else
  echo "Source tarball already exists at ${sourcefile}, skipping download"
fi

## -- RUN BUILD -- ##

echo "Building ${recipe} recipe..."
sourcemount="-v ${sourcefile}:/home/node/node.tar.xz"
stagingmount="-v ${stagingoutdir}:/out"
ccachemount="-v ${ccachedir}/${recipe}/:/home/node/.ccache/"
mkdir -p "${ccachedir}/${recipe}"
docker run --rm \
  --user=$(id -u) \
  ${ccachemount} ${sourcemount} ${stagingmount} \
  "${image_tag_pfx}${recipe}" \
  "$unofficial_release_urlbase" "$disttype" "$customtag" "$datestring" "$commit" "$fullversion" "$source_url"
echo "Successful build should result in assets in ${stagingoutdir}"
