#!/bin/sh
. ../testenv.sh
$OBECOMP mathtest.mod -m -OC
./mathtest >result
. ../testresult.sh
