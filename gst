#!/bin/sh
status=$( { git status --short ;} 2>&1 )
if [ "$status" != "" ]; then
    git status --short
else
    status_push=$(git status --short --branch |grep ahead)
    if [ "$status_push" != "" ]; then
        git status --short --branch
    else
        env printf '\xF0\x9F\x91\x8D\n'
    fi
fi
