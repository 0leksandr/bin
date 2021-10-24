#!/bin/sh
export DISPLAY=:0
notify "begin"
notify "$@"
mplayer "$1"
exit 0
