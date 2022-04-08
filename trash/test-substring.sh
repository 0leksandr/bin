#!/bin/sh
if [ "-rf" = -*f* ]; then
    echo "case 1"
fi
if [ "-rf" = -*f* ]; then
    echo "case 2"
fi
if echo "-rf" |grep "^-.*f" > /dev/null ; then
    echo case 3
fi
