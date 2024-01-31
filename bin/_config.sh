# All of our build recipes, new recipes should be added here.
recipes=" \
  headers \
  x86 \
  musl \
  armv6l \
  x64-debug \
  x64-glibc-217 \
  x64-pointer-compression \
  x64-usdt \
  riscv64 \
  loong64 \
"

# This should be updated as new versions of nodejs-dist-indexer are released to
# include new assets published here; this is not done automatically for security
# reasons.
dist_indexer_version=v1.7.1

image_tag_pfx=unofficial-build-recipe-
