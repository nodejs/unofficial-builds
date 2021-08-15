#!/bin/bash -xe

# Rebuild recipe images, any directory in ../recipes gets a build

__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
image_tag_pfx=unofficial-build-recipe-

for recipe in $(ls ${__dirname}/../recipes/); do
	docker build ${__dirname}/../recipes/${recipe}/ -t ${image_tag_pfx}${recipe} --build-arg UID=1000 --build-arg GID=1000
done

docker system prune -f
