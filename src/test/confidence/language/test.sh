#!/bin/sh
. ../testenv.sh
# Generate mixed source and assembly code listing
$OBECOMP TestLanguage.mod -m
./TestLanguage >result
. ../testresult.sh
