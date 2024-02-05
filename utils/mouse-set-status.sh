#!/bin/sh
set -e
status="$1"

case "$status" in
    0) action="disable" ;;
    1) action="enable"  ;;
    *) echo "enter status" && exit 1 ;;
esac

xinput "$action" $(xinput | grep Mouse | tr -d " " | tr "\t" " " | cut -d" " -f2 | cut -d"=" -f2)
#xinput "$action" $(xinput | grep pointer | tr -d " " | tr "\t" " " | cut -d" " -f2 | cut -d"=" -f2)
