#!/bin/bash
new_title="$1"

dir="$HOME/Downloads"
files () { ls -1 --sort=none "$dir" |sort ;}
old_files="$(files)"
i=0
while [ $i -lt 10 ]; do
    new_file="$(comm -1 -3 <(echo "$old_files") <(files))"  # bash, needed for process substitution. Note: `comm`, not `diff`
    if [ "$new_file" ]; then
        j=0
        while [ $j -lt 120 ]; do
            if [ ! -f "$dir/$new_file" ]; then
                title="$(echo "$new_file" |sed -r 's ^(.*)\.[^.]+$ \1 ')"
notify "$(basename $0): $new_title"
                mv "$dir/$title" "$dir/$new_title.mp3"
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
