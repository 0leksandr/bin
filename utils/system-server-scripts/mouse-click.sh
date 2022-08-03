#!/bin/sh
set -e

x="$1"
y="$2"

xdotool mousemove $x $y click 1
