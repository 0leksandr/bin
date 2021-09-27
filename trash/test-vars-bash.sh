#!/bin/bash
a="aa"
aa="bb"
echo "a[$a]"
echo "{a}[${a}]"
echo "aa[$aa]"
echo "!a[${!a}]"
echo "__a[$$a]"
echo "echo[$$(echo $a)]"

echo "!1[${!1}]"
echo "!2[${!2}]"
echo "!-1[${!-1}]"
n=1
echo "n=1[${!n}]"
echo "1[${1}]"
hr
echo "-2[${@:(-2):1}]"
