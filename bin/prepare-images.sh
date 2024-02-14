#!/bin/bash -xe

# Rebuild recipe images, any directory in ../recipes gets a build

__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${__dirname}/_config.sh"

docker build "${__dirname}/../fetch-source" -t "${image_tag_pfx}fetch-source" --build-arg UID=1000 --build-arg GID=1000

for recipe in "${recipes[@]}"; do
  docker build "${recipes_dir}/${recipe}/" -t "${image_tag_pfx}${recipe}" --build-arg UID=1000 --build-arg GID=1000
done

docker system prune -f
