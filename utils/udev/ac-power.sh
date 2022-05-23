#!/bin/sh
set -e

log(){ echo "$(date +"%F %T"): $1" >> /home/nezhraba/.temp/ac-power.log ;}

case $1 in
    0)
        log "off"
        #brightness 10
        /home/nezhraba/_/Programs/bin/utils/run-as-me /home/nezhraba/_/Programs/bin/brightness 10
        ;;
    1)
        log "on"
        ;;
    *) exit 1 ;;
esac
