#!/bin/bash
#reg="^(.*)\\[(.*)\\](.*)$"
reg='^(.*(?:[^\\\\]))?\[([^][]+)\](.*)$'
from="line1[test]
line2"
#to="bar"
to='\3'
perl -0777pe "s/$reg/$to/s" <<<"$from"

#hr
#reg='^(.*([^\\\\]))?\[([^][]+)\](.*)$'
#echo "$from" |sed -r "s $reg \1 "
