#!/bin/sh
set -e
method="$1"
header="$2"
url="$3"

echo>&2 "method[$method] header[$header] url[$url]"

#curl --request "$method" --header "$header" -v "$url"

case "$method" in
    HEAD) method="--head"            ;;
    GET)  method=""                  ;;
    .*)   method="--request $method" ;;
esac
[ "$header" ] && header="--header '$header'"

eval "curl $method $header -v $url"
