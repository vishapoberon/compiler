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
$OBECOMP TestFixedArrayValues.mod -m
./TestFixedArrayValues >result
printf 'fixed array value tests passed\n' >result-expected
diff -b result-expected result
if $OBECOMP BadFixedArrayValues.mod -sS >result-rejected 2>&1; then
  echo 'accepting incompatible fixed-array actuals' >&2
  exit 1
fi
test "$(grep -c 'err 113' result-rejected)" -eq 6
$OBECOMP TestNestedArrayLengths.mod -m
./TestNestedArrayLengths >result
printf 'nested array length tests passed\n' >result-expected
diff -b result-expected result
