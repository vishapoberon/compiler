#!/bin/sh
. ../testenv.sh
# Generate mixed source and assembly code listing
$OBECOMP IntSyntax.mod -fm | fgrep -v "Testing. Binary directory is: '" >result
. ../testresult.sh
