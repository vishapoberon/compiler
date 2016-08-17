#!/bin/sh
. ../testenv.sh
# Generate mixed source and assembly code listing
voc TestLibrary.mod -m
./TestLibrary >result
. ../testresult.sh
