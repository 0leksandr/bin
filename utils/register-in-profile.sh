#!/bin/sh
set -e
filename="$1"
target="$2"

add_to(){
    local filename="$1"
    local target="$2"
    printf '\n\n. "%s"' "$(realpath "$filename")" >> "$target"
}

rc_file="$HOME/.$(basename "$(which "$SHELL")")rc"

case "$target" in
    profile)
        case "$("$HOME"/_/Programs/bin/_os)" in
            linux) target="$HOME/.profile" ;;
            mac)   target="$rc_file"       ;;
        esac
        add_to "$filename" "$target"
        ;;
    rc) add_to "$filename" "$rc_file" ;;
    *)
        echo>&2 "unsupported target: $target"
        exit 1
        ;;
esac
