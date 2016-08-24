#!/bin/sh
. ../testenv.sh
$OBECOMP testTexts.mod -m
./testTexts >result
. ../testresult.sh
