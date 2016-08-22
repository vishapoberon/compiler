#!/bin/sh
. ../testenv.sh
$OBECOMP signal.mod -m
./SignalTest x &
sleep 1
kill -2 $!
wait
. ../testresult.sh
