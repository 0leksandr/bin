#!/bin/sh
while ! ~/Programs/test-return.sh 1; do
    sleep 1
    beep
done
exit 0
