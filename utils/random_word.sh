#!/bin/bash
dics_dir="/home/nezhraba/_/Parallango/dics"
dic_file="${dics_dir}/ukr/ukr.txt"

case $# in
    0)
        while :; do
            # nr_lines="$(wc -l ${dic_file} |sed -r 's/^([0-9]+) .*$/\1/')"
            # line_nr=$(_rand $nr_lines)
            # line="$(sed "${line_nr}q;d" ${dic_file})"
            line="$(shuf -n 1 ${dic_file})"

            word="$(echo "${line}" |sed -r 's ^([^|]+)\|.*$ \1 ')"

            echo "$(date-ft)"
            echo "$word"
            read input
            if [ ! "$input" ]; then break; fi
            clr
        done
        ;;
    1)
        if [ "$1" = "?" ]; then
            echo "What words do I remeber?"
            read
        else
            nr_words=$1
            while [ $nr_words -gt 0 ]; do
                nr_words=$(($nr_words - 1))
                gnome-terminal -- $0
            done
        fi
        ;;
esac
