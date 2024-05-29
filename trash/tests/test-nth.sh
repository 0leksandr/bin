#!/bin/sh
nth() {
    eval res=\${$(($1 + 1))}
    echo $res
}
list="first second third"
echo "$(nth 2 $list)"
