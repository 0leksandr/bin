#!/bin/sh
nr_args=$#
all_or_nothing=""
if [ "$1" = "-n" ]; then
    nr_args=$((nr_args - 1))
    all_or_nothing="-n"
fi

if [ $nr_args -eq 1 ]; then
    for arg in "$@"; do
        if [ "$arg" != "-n" ]; then
            commands="$(echo "$arg" |sed -r 's/^ *#.*$//' |awk 'NF > 0' |sed -r "s ^.*\$ '\0' ")"
            if [ "$(echo "$commands" |wc -l)" -gt 1 ]; then
                eval "$0 $all_or_nothing $(echo "$commands" |tr '\n' ' ')"
                exit 1
            fi
        fi
    done
fi

list2kill=""
list2wait=""

for cmd in "$@"; do
    if [ "$cmd" != "-n" ]; then
        eval "$cmd" & pid=$!
        list2wait="$list2wait $pid"
        list2kill="$list2kill pkill -P $pid;"
    fi
done

trap "$list2kill" INT TERM

if [ "$all_or_nothing" ]; then
    # bash -c "wait -n"
    while true; do
        for pid in $list2wait; do
            # if ! ps --pid="$pid" > /dev/null; then
            if ! ps |grep -E -q "^ *$pid "; then
                eval "$list2kill"
                exit 1
            fi
        done
        sleep 0.1
    done
else
    wait $list2wait
fi
