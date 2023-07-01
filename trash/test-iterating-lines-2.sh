#!/bin/sh
lines="  line1\n  line2"

for line in $lines; do
    echo "1 line[$line]"
done

echo "$lines" |while read line; do
    echo "2 line[$line]"
done
echo "done script"
