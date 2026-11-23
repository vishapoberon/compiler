#!/bin/sh
set -e
. ../testenv.sh
$OBECOMP ReadOnlyData.mod -s
$OBECOMP TestReadOnly.mod -m
./TestReadOnly >result
. ../testresult.sh
if $OBECOMP BadReadOnlyGet.mod -sS >result-rejected 2>&1; then
  echo 'accepting read-only SYSTEM.GET destinations' >&2
  exit 1
fi
test "$(grep -c 'err 76 ' result-rejected)" -eq 14
test "$(grep -c 'err ' result-rejected)" -eq 14
if $OBECOMP BadReadOnlyGetReg.mod -sS >result-registers 2>&1; then
  echo 'accepting read-only SYSTEM.GETREG destinations' >&2
  exit 1
fi
test "$(grep -c 'err 76 ' result-registers)" -eq 3
