#!/bin/bash
set -e
from="$1"
format="$2"

[ "$format" ] || format="%F"

to="$(date +"$format")"
res=""
n="
"
while [[ "$from" < "$to" ]]; do
    res="$res$n$from"
    from="$(date -v+1d -j -f "$format" "$from" +"$format")"
done
res="$(echo "$res" |tail --lines "$(($(echo "$res" |wc -l) - 1))")"
"$(dirname "$0")/copy" "echo '$res'"
