#!/bin/sh
. ../testenv.sh
# Generate mixed source and assembly code listing
voc TestLanguage.mod -m
./TestLanguage >result
. ../testresult.sh
