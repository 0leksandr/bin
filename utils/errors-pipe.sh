#!/bin/sh

pipe=/tmp/my-errors-pipe

trap "rm -f $pipe" EXIT

if [ ! -p "$pipe" ]; then
    mkfifo "$pipe"
fi

while :; do
    if read line <$pipe; then
        alert "$line"
    fi
done
