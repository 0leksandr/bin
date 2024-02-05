#!/bin/sh
set -e

#dir="$(dirname $(realpath $0))"
#$dir/mouse-set-status.sh 0
#systemctl suspend
#sleep 5
#$dir/mouse-set-status.sh 1

# https://codetrips.com/2020/03/18/ubuntu-disable-mouse-wake-from-suspend/comment-page-1/
#dir="/sys/bus/usb/devices"
#devices="$(grep . $dir/*/power/wakeup |grep enabled |sed -r "s ^($dir/[^/]+)/.*$ \1 g")"
#for device in $devices; do
#    if [ "$(cat "$device/product")" = "2.4G Device" ]; then
#        echo disabled > "$device/power/wakeup"
#    fi
#done

# https://unix.stackexchange.com/questions/417956/make-changes-to-proc-acpi-wakeup-permanent/532839#532839

systemctl suspend
