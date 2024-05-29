#!/bin/sh
if [ "" ]; then
    read -p "Heh?" aa
    echo $aa

    read void
    read

    if [ $(read aa) ]; then
        echo "yes"
    else
        echo "no"
    fi
fi

# echo "testing multiple read with timeout"
# while :; do
#     timeout 5s read a
#     echo "a[$a]"
# done

if [ "" ]; then
    while :; do
        hr
        timeout --foreground 5 sh -c 'read a; echo $a'|while read -r a; do
            echo "a[$a]"
        done
    done
fi

if [ "" ]; then
    printf "%s\n" "Do you want to un-Mount the External Drives?"
    timeout --foreground 10 bash -c '
        select sel in "yes" "no"
        do
            echo "$REPLY"
            break
        done' | while read -r answer; do
            echo ">>Got from user: $answer"
            case "$answer" in
                "yes") echo "Unmounting stuff" ;;
            esac
    done
fi

if [ "" ]; then
    if [ "$(read)" ]; then
        echo "yes"
    else
        echo "no"
    fi
fi

if [ "1" ]; then
    read _
fi
