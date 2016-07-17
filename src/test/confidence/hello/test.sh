#!/bin/sh
. ../testenv.sh
# Generate mixed source and assembly code listing
CFLAGS="-gstabs -g1 -Wa,-acdhln=hello.s" && voc hello.mod -m
./hello >result
. ../testresult.sh
