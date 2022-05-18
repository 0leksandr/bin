#!/bin/sh
if [ $((1 ^ 1)) -eq 1 ]; then
    echo "1-1"
fi
if [ $((1 ^ 0)) -eq 1 ]; then
    echo "1-0"
fi
if [ $((0 ^ 1)) -eq 1 ]; then
    echo "0-1"
fi
if [ $((0 ^ 0)) -eq 1 ]; then
    echo "0-0"
fi
