#!/bin/sh
set -e

title="$1"
delay="$2"

#list="$(vivaldi-windows list)"

if [ $# -ge 3 ]; then
    keys=""
    i=0
    for key in "$@"; do
        i=$(($i + 1))
        if [ $i -ge 3 ]; then
            keys="$keys key $key"
        fi
    done
    if [ $delay -gt 0 ]; then sleep "$delay"; fi
    if [ "$title" ]; then
        xdotool search --name "^$title - Vivaldi$" windowactivate --sync %1 $keys windowactivate $(xdotool getactivewindow)
    else
        xdotool $keys
    fi
else
    alert "$0: error"
fi

#sleep 3
#if [ "$(vivaldi-windows list)" = "$list" ]; then
#    echo>&2 "$(basename $0) failed: key[$key] title[$title]"
#fi
