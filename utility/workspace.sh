#!/bin/bash
wmctrl -n 10
exit

gsettings set org.cinnamon.desktop.wm.preferences num-workspaces $(calc $(gsettings get org.cinnamon.desktop.wm.preferences num-workspaces) - 1)
exit 0

case $1 in
add) ACTION="+" ;;
del) ACTION="-" ;;
esac
ACTION="+"
WS=$(dbus-send --print-reply --type=method_call --dest=org.freedesktop.compiz /org/freedesktop/compiz/core/screen0/hsize org.freedesktop.compiz.get | tail -c -2)
dbus-send --type=method_call --dest=org.freedesktop.compiz /org/freedesktop/compiz/core/screen0/hsize org.freedesktop.compiz.set int32:$[ $WS $ACTION 1 ]
