#!/bin/sh
. ../testenv.sh
voc signal.mod -m
./SignalTest x &
sleep 1
kill -2 $!
wait
. ../testresult.sh
