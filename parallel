#!/bin/sh
LIST2KILL=""
LIST2WAIT=""
for cmd in "$@"; do {
  eval "$cmd" & pid=$!
  LIST2WAIT="$LIST2WAIT $pid"
  LIST2KILL="$LIST2KILL pkill -P $pid;"
} done

trap "$LIST2KILL" INT TERM

wait $LIST2WAIT
