#!/bin/sh
if [ 0 -eq 1 ]; then
    echo "0 -eq 1"
fi

arg=0
if [ $arg ]; then
    echo "0"
fi

arg=1
if [ $arg ]; then
    echo "1"
fi

arg=""
if [ "$arg" ]; then
    echo '""'
fi

if [ ! "$(echo '')" ]; then
    echo "not"
else
    echo "fuck"
fi

while [ ! "$(echo '')" ]; do
    echo "while"
    break
done
