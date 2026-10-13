#!/bin/sh
set -e
. ../testenv.sh
$OBECOMP TestHeapRoots.mod -m
./TestHeapRoots >result
. ../testresult.sh
