#!/bin/sh
. ../testenv.sh
voc hello.mod -m
./hello >result
. ../testresult.sh
