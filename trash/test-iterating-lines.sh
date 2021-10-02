#!/bin/bash
list='123 456\n789'
cr='
'
for item in ${list//\\n/$cr}; do
   echo "Item: $item"
done
