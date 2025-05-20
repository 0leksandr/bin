#!/bin/sh
set -e
last=""; for arg in $@; do last="$arg"; done
echo "last[$last]"
_highlander "$last"

#sleep infinity
while :; do sleep 1000; done
