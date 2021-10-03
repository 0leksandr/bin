#!/bin/sh
title="$1"

list="$(vivaldi-windows list)"
if [ "$title" != "" ] && [ $# -ge 2 ]; then
    keys=""
    first="1"
    for key in "$@"; do
        if [ "$first" ]; then
            first=""
        else
            keys="$keys key $key"
        fi
    done
    xdotool search --name "^$title - Vivaldi$" windowactivate --sync %1 $keys windowactivate $(xdotool getactivewindow)
else
    alert "$0: error"
fi

# sleep 3
# if [ "$(vivaldi-windows list)" = "$list" ]; then
#     echo>&2 "$(basename $0) failed: key[$key] title[$title]"
# fi
