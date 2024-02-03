#!/bin/bash -e

usage_exit() {
  echo "Usage: $0 -r <recipe> -v <version> [-w <workdir>]"
  exit 1
}

## -- SETUP -- ##

__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# by default, workdir is the parent directory of the cloned repo
workdir=${workdir:-"$__dirname"/../..}

source "${__dirname}/_config.sh"

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

USER_ID=$(id -u)
GROUP_ID=$(id -g)
# there's a good chance of a UID/GID conflict in the container if we are less
# than 1000, so bump to 1000 if that's the case.
if [[ $USER_ID -lt 1000 ]]; then
  USER_ID=1000
  echo -e "\e[1mWarning: UID is less than 1000, setting to 1000, output files will be owned by this UID\e[0m"
fi
if [[ $GROUP_ID -lt 1000 ]]; then
  GROUP_ID=1000
  echo -e "\e[1mWarning: GID is less than 1000, setting to 1000\e[0m"
fi

echo "Building ${recipe} recipe and tagging as ${image_tag_pfx}${recipe}..."
docker build "${__dirname}/../fetch-source/" -t "${image_tag_pfx}fetch-source" --build-arg UID=${USER_ID} --build-arg GID=${GROUP_ID}
docker build "${__dirname}/../recipes/${recipe}/" -t "${image_tag_pfx}${recipe}" --build-arg UID=${USER_ID} --build-arg GID=${GROUP_ID}

## -- DOWNLOAD SOURCE -- ##

if [[ ! -f "${sourcefile}" ]]; then
  echo "Downloading source tarball..."
  docker run --rm \
    --user=${USER_ID} \
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
  --user=${USER_ID} \
  ${ccachemount} ${sourcemount} ${stagingmount} \
  "${image_tag_pfx}${recipe}" \
  "$unofficial_release_urlbase" "$disttype" "$customtag" "$datestring" "$commit" "$fullversion" "$source_url"
echo "Successful build should result in assets in ${stagingoutdir}"
