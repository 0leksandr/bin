#!/bin/sh
set -e
aqi=$(tail -n1 ~/_/aqi.txt |sed -r 's ^([0-9]+)(\..+)?$ \1 ')
if [ $aqi -lt 50 ]; then
    notify "aqi=$aqi"
fi
