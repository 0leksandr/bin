#!/bin/sh
while true; do
    battery=$(battery)
    if [ $battery -le 10 ]; then
        notify-send --urgency=critical --icon=terminal "Battery low"
        beep
        exit 0
    fi
    sleep $battery
done
