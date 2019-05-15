#!/bin/bash

# Fail-fast
set -e

# The recipes managed by this script
RECIPES=("sdk/rtems-tools"
         "sdk/rtems-source-builder"
         "ssw/rtps/r52/rtems"
         "ssw/rtps/r52/hpsc-rtems")

for rec in "${RECIPES[@]}"; do
    ./build-recipe.sh -r "$rec" "$@"
done
