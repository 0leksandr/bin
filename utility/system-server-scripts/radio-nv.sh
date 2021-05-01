#!/bin/sh
title="$1"

dir="$HOME/Downloads"
files () { ls -1 --sort=time "$dir" ;}
nr_files=$(files |wc -l)
i=0
while [ $i -lt 10 ]; do
    nr_new=$(($(files |wc -l) - $nr_files))
    if [ $nr_new -gt 0 ]; then
        j=0
        while [ $j -lt 30 ]; do
            file="$(files |tail -n $(($nr_files + 1)) |head -n 1)"
            if echo "$file" |grep '\.mp3$' > /dev/null ; then
                mv "$dir/$file" "$dir/$title.mp3"
                break
            fi
            j=$((j+1))
            sleep 1
        done
        break
    fi
    i=$((i+1))
    sleep 1
done
