#!/bin/sh
lines="  line1\n  line2"

#for line in $lines; do
#    echo "line[$line]"
#done

echo "$lines" |while read line; do
    echo "line[$line]"
done
