#!/bin/sh
set -e
. ../testenv.sh
# Generate mixed source and assembly code listing
if $OBECOMP IntSyntax.mod -fm >result; then
  echo 'accepting implicit integer narrowing' >&2
  exit 1
fi
. ../testresult.sh
$OBECOMP TestSignedShifts.mod -m
./TestSignedShifts >result
printf 'signed shift tests passed\n' >result-expected
diff -b result-expected result
