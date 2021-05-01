#!/bin/sh
export DISPLAY=:0
notify-send "begin"
notify-send "$@"
mplayer "$1"
exit 0
