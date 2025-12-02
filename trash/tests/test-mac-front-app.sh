#!/bin/sh
set -e

front_app="$(osascript -e 'path to frontmost application as Unicode text' |sed -r 's/^.*:([^:]+):?$/\1/')"
notify "front_app[$front_app]"
#osascript -e '
#    set front_app to (path to frontmost application as Unicode text)
#    return front_app
#'
#    set front_app to (do shell script "echo " & quoted form of front_app & "|sed -r \\'s/^.*:([^:]+):?$/\1/\\'")
#    display dialog front_app with title "'"$(basename "$0")"'"
