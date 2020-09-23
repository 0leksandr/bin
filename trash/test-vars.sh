#!/bin/bash
a="aa"
aa="bb"
echo "a[$a]"
echo "aa[$aa]"
echo "!a[${!a}]"
echo "__a[$$a]"
echo "ech[$$(echo $a)]"
