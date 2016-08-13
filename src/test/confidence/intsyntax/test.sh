#!/bin/sh
. ../testenv.sh
# Generate mixed source and assembly code listing
voc IntSyntax.mod -m >result
. ../testresult.sh
