#!/bin/sh
# echo "$1"
# exit "$1"

test () {
    return "this-is-a-test"
}
echo "test[$(test)]"
