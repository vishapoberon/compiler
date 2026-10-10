#!/bin/sh
set -e
. ../testenv.sh
$OBECOMP TestArrayParameters.mod -m
./TestArrayParameters >result
. ../testresult.sh
