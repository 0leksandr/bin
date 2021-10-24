#!/bin/sh
while true; do
    battery=$(battery)
    if [ $battery -le 10 ]; then
        alert "Battery low"
        beep
        exit 0
    fi
    sleep $battery
done
