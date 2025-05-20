#!/bin/sh

echo "*[$*]"
[ $# -gt 1 ] && exit
if _is_in_script; then
    echo "called from script"
fi

#procx "$0"
eval "$0 test $*"
