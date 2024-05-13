#!/bin/sh
parent=$(_parent)
if [ "$(proc -x -P $parent |sed -r 's/^.* ([^ ]+)$/\1/')" != "zsh" ]; then
    echo "called from script"
fi

procx $0
