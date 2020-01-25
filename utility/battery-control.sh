#!/bin/sh
alerted=0
while true; do
    if [ `battery` -le 10 ]; then
        if [ $alerted -eq 0 ]; then
            notify-send --urgency=critical --icon=terminal "Battery low"
            beep
            alerted=1
        fi
    else
        alerted=0
    fi
    sleep 1
done

exit 0
