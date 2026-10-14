#!/bin/sh
set -e
. ../testenv.sh
rm -f testTexts # Remove LSW binary so it doesn't hide Cygwin binary.
$OBECOMP testTexts.mod -m
./testTexts >result
. ../testresult.sh
$OBECOMP TestScannerNumbers.mod -m
./TestScannerNumbers >result
printf 'bounded scanner number tests passed\n' >result-expected
diff -b result-expected result
