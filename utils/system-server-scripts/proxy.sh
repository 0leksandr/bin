#!/bin/sh
set -e
url="$1"
header="$2"

curl --header "$header" -v "$url"
