#!/bin/sh
title="$1"
key="$2"

list="$(vivaldi-windows list)"
if [ "$title" != "" ] && [ "$key" != "" ]; then
    xdotool search --name "^$title - Vivaldi$" windowactivate --sync %1 key "$key" windowactivate $(xdotool getactivewindow)
fi
sleep 3
if [ "$(vivaldi-windows list)" = "$list" ]; then
    alert "$(basename $0) failed: key[$key] title[$title]"
fi
