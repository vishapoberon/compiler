#!/bin/sh
set -e
. ../testenv.sh
$OBECOMP TestFileStrings.mod -m
./TestFileStrings >result
. ../testresult.sh
