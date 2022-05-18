#!/bin/sh

echo "["
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

if [ : ]; then
    echo ":"
fi

if [ true ]; then
    echo "true"
fi

if [ false ]; then
    echo "false"
fi
echo "]"

if true; then
    echo "true"
fi
if false; then
    echo "false"
fi
