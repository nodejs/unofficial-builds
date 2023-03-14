#!/bin/bash -xe

# Rebuild recipe images, any directory in ../recipes gets a build

__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
image_tag_pfx=unofficial-build-recipe-

if [[ $# -gt 0 ]]; then
  recipes=( "$@" )
else
  recipes=( $(ls ${__dirname}/../recipes/) )
fi

for recipe in "${recipes[@]}" ; do
	docker build ${__dirname}/../recipes/${recipe}/ -t ${image_tag_pfx}${recipe} --build-arg UID=1000 --build-arg GID=1000
done

docker system prune -f
