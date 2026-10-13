#!/bin/sh
set -e
. ../testenv.sh
$OBECOMP TestArrayParameters.mod -m
./TestArrayParameters >result
. ../testresult.sh
$OBECOMP TestOpenArrayRows.mod -m
./TestOpenArrayRows >result
printf 'open array row tests passed\n' >result-expected
diff -b result-expected result
$OBECOMP TestNestedArrayLengths.mod -m
./TestNestedArrayLengths >result
printf 'nested array length tests passed\n' >result-expected
diff -b result-expected result
