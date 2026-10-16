#!/bin/sh
set -eu
compiler=$1
build=$2
model=$3
flags=$4
source=$(pwd)
cd "$build"
for path in base64/TestStringBase64 bdStrings/TestBDBounds strutils/TestStrBounds \
            lists/TestListLinks opts/TestLongOption toml/TestTOMLBounds s3/TestDESLegacy ssqJson/TestJson; do
  "$compiler" -O"$model" "$flags" "$source/$path.Mod"
  name=${path##*/}
  if [ "$name" = TestLongOption ]; then
    long=$(awk 'BEGIN {for(i=0; i<300; i++) printf "x"}')
    ./TestLongOption -n "$long" -- tail
  else
    "./$name"
  fi
done
"$compiler" -O"$model" "$flags" "$source/base64/TestBase64Reject.Mod"
for invalid in Z Zg Zg= =AAA Z=== Zg=A Zg==AAAA Zh== Zm9= 'Zg??' small-destination; do
  status=0
  ./TestBase64Reject "$invalid" >base64-rejected.log 2>&1 || status=$?
  if [ "$status" -ne 100 ]; then
    cat base64-rejected.log
    echo "Expected Base64 HALT(100), got $status for $invalid" >&2
    exit 1
  fi
done
echo 'portable port regressions passed'
