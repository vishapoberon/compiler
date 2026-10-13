#!/bin/sh
set -e
. ../testenv.sh
${CC:-cc} -x c -fPIC -shared WriteFaults.inc -o WriteFaults.so -ldl
LDLIBS="${LDLIBS:-} -ldl" $OBECOMP TestPlatformWrite.mod -m
for mode in 1 2 3 4 5 6 7 8; do
  VOC_WRITE_FAULT=$mode LD_PRELOAD="$PWD/WriteFaults.so" ./TestPlatformWrite >result
  . ../testresult.sh
done
