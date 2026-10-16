#!/bin/sh
set -e
. ../confidence/testenv.sh

# Compile only test code: the three terminal modules and their headers/symbols
# must come from the installed conventional libraries, in both type models.
for model in 2 C; do
  CFLAGS="${CFLAGS:-} -D_XOPEN_SOURCE=700" $OBECOMP -O$model ../hresh/TestTerminalNative.Mod -s
  $OBECOMP -O$model ../hresh/TestTerminalState.Mod -m
  ./TestTerminalState >result
  printf 'opaque terminal state tests passed\n' >result-expected
  diff -b result-expected result
  $OBECOMP -O$model TestLineEditor.Mod -m
  printf 'first\nsecond\r\noversized\n\nlast' | ./TestLineEditor >result
  printf 'standalone terminal library tests passed\n' >result-expected
  diff -b result-expected result
done

echo 'Conventional Unix terminal libraries passed in both type models.'
