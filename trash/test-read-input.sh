#!/bin/sh
read -p "Heh?" aa
echo $aa

read void

if [ $(read aa) ]; then
    echo "yes"
else
    echo "no"
fi

echo "exit"
