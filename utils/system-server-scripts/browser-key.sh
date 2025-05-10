#!/bin/sh
set -e

title="$1"
delay="$2"

#list="$(vivaldi-windows list)"

os="$(_os)"

if [ $# -ge 3 ]; then
    keys=""
    i=0
    for key in "$@"; do
        i=$(($i + 1))
        if [ $i -ge 3 ]; then
            case "$os" in
                linux) keys="$keys key $key" ;;
                mac)   keys="$keys$key"      ;;
            esac
        fi
    done
    if [ $delay -gt 0 ]; then sleep "$delay"; fi

    case "$os" in
        linux)
            if [ "$title" ]; then
                xdotool search --name "^$title - Vivaldi$" windowactivate --sync %1 $keys windowactivate $(xdotool getactivewindow)
            else
                xdotool $keys
            fi
            ;;
        mac)
            #if [ ! "$title" ]; then
            #    title="$(lsappinfo info "$(lsappinfo front)" |head --lines=1 |sed -r 's/^"([^"]+)".*$/\1/')"
            #fi
            if [ "$title" ]; then
                osascript -e "activate application \"$title\""
            fi
            case "$keys" in
                "ctrl+"*) keystroke="$(echo "$keys" |sed -r 's/^ctrl\+(.+)$/\1/') using command down" ;;
                *)        keystroke="$keys"
            esac
notify "keystroke[$keystroke]"
            osascript -e "tell application \"System Events\" to keystroke \"$keystroke\""
            ;;
    esac
else
    alert "$0: error"
fi

#sleep 3
#if [ "$(vivaldi-windows list)" = "$list" ]; then
#    echo>&2 "$(basename $0) failed: key[$key] title[$title]"
#fi
