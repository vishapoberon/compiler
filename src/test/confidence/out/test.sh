#!/bin/sh
set -e
. ../testenv.sh
rm -f outtest # Remove LSW binary so it doesn't hide Cygwin binary.
$OBECOMP outtest.mod -m -O2
./outtest >result-O2
$OBECOMP outtest.mod -m -OC
./outtest >result-OC
echo --- Testing with Oberon 2 variable model --- >result
cat result-O2 >>result
echo "" >>result
echo "" >>result
echo --- Testing with Component Pascal variable model --- >>result
cat result-OC >>result
. ../testresult.sh
for model in 2 C; do
  $OBECOMP TestOutHex.mod -m -O$model
  ./TestOutHex >hex-result
  diff -u hex-expected hex-result
done
echo 'ETH Hex and unsigned HexDigits output passed in both type models.'
