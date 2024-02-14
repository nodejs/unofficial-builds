# All of our build recipes, new recipes should be added here.
recipes=(
  "headers"
  "x86"
  "musl"
  "armv6l"
  "x64-debug"
  "x64-glibc-217"
  "x64-pointer-compression"
  "x64-usdt"
  "riscv64"
  "loong64"
)


# This should be updated as new versions of nodejs-dist-indexer are released to
# include new assets published here; this is not done automatically for security
# reasons.
dist_indexer_version=v1.7.1

image_tag_pfx=unofficial-build-recipe-

# Location of the recipes directory relative to this script
__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
recipes_dir="${__dirname}/../recipes"
queuefile="$(realpath "${__dirname}/../../var/build_queue")"

recipe_exists() {
  local recipe=$1
  [ -d "${recipes_dir}/${recipe}" ]
}
