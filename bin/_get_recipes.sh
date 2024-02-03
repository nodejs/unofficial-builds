#!/bin/bash

# Initialize recipes array
all_recipes=()

# Location of the recipes directory relative to this script
__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
recipes_dir="${__dirname}/../recipes"

get_recipes() {
    # Clear the array to prevent duplication if called multiple times
    all_recipes=()
    for recipe in $(ls ${recipes_dir}/); do
        all_recipes+=("$recipe")
    done
}


recipe_exists() {
    local recipe=$1
    [ -d "${recipes_dir}/${recipe}" ]
}

# Populate the recipes array
get_recipes

export -f recipe_exists
