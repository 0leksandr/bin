#!/bin/sh
echo "#[$#]"
echo "@[$@]"
for arg in "$@" ; do
    echo $arg
done
# if [ $# -eq 1 ]; then
#     echo "1 arg"
# else
#     echo "not 1 arg"
# fi

exit 0
