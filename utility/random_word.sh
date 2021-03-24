#!/bin/bash
dics_dir="/home/nezhraba/_/Parallango/dics"
dic_file="${dics_dir}/ukr/ukr.txt"
nr_lines="$(wc -l ${dic_file} |sed -r 's/^([0-9]+) .*$/\1/')"
line_nr=$(_rand $nr_lines)
line="$(sed "${line_nr}q;d" ${dic_file})"
word="$(echo "${line}" |sed -r 's ^([^|]+)\|.*$ \1 ')"

echo "$(date-ft)"
echo "$word"
read
