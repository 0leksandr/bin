#!/bin/sh

# name="$1"
# if ! echo "$name" |grep -Ei '^[0-9a-z .-]{1,30}$' > /dev/null; then name="$PPID"; fi
# echo "name[$name]"
# exit

#run-detached "$(basename $0)" "echo 'this is a test' > $(errors)"

for i in 1 2 3; do
    sleep 5
    echo "i[$i]"
    echo "i[$i]" >&2
done
