#!/bin/sh
set -e
. ../testenv.sh
$OBECOMP TestCKeywords.mod -m
./TestCKeywords >result
. ../testresult.sh
