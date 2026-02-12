# All of our build recipes, order matters: recipes run sequentially, so put the
# most popular/important ones first. Recipes with a should-build.sh that gates
# them out for a given version are skipped instantly.
recipes=(
  # Active recipes, ordered by likely popularity
  "headers"
  "musl"
  "arm64-musl"
  "riscv64"
  "loong64"

  # Legacy recipes, currently gated out for modern Node.js versions
  "x86"                     # major < 22
  "armv6l"                  # major < 24
  "x64-glibc-217"           # major < 24
  "x64-pointer-compression" # major < 23
  "x64-debug"               # major < 24
  "x64-usdt"                # major <= 18
)


# This should be updated as new versions of nodejs-dist-indexer are released to
# include new assets published here; this is not done automatically for security
# reasons.
dist_indexer_version=v1.7.30

image_tag_pfx=unofficial-build-recipe-

# Location of the recipes directory relative to this script
__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
recipes_dir="${__dirname}/../recipes"
queuefile="$(realpath "${__dirname}/../../var/build_queue")"

recipe_exists() {
  local recipe=$1
  [ -d "${recipes_dir}/${recipe}" ]
}
