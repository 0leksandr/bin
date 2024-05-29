#!/bin/sh
#eval 'echo $'$#
#eval 'last=$(echo $'$#')'
eval last=\${$#}
echo "last[$last]"
