#!/bin/sh
eval "sleep 3 && beep" & pid=$!
echo "waiting"
tail --pid=$pid -f /dev/null
echo "done"
