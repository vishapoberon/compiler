#!/bin/sh
. ../testenv.sh
$OBECOMP aa.mod -m
./aa >result
. ../testresult.sh
