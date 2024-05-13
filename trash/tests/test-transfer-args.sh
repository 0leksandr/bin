#!/bin/bash
args=""
for arg in "$@"; do
    arg="$(printf "%q" "$arg")"
    args="$args $arg"
done
eval "./test-args.sh $args"
a3="3"
echo "3[${!a3}]"
# ./test-args.sh $args
# printf "%s\n" "${args[@]}"
