#!/bin/sh
. ../testenv.sh
# Generate mixed source and assembly code listing
$OBECOMP TestLibrary.mod -m
./TestLibrary >result
. ../testresult.sh
