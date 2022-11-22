#!/bin/sh
set -e

cmd="git status --short $@"
if [ "$($cmd 2>&1)" ]; then
    $cmd
    exit 1
else
    cmd="git status --short --branch $@"
    if $cmd |egrep -q 'ahead|behing'; then
        $cmd
        exit 1
    else
        env printf '\xF0\x9F\x91\x8D\n'
        exit 0
    fi
fi
