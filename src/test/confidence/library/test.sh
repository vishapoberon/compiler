#!/bin/sh
set -e
. ../testenv.sh
# Generate mixed source and assembly code listing
rm -f TestLibrary # Remove LSW binary so it doesn't hide Cygwin binary.
$OBECOMP TestLibrary.mod -m
./TestLibrary >result
. ../testresult.sh
$OBECOMP TestAsciiCodes.mod -m
./TestAsciiCodes >result
printf 'ascii control code tests passed\n' >result-expected
diff -b result-expected result
