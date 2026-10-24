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
$OBECOMP TestOocUnified.mod -m
./TestOocUnified >result
printf 'unified oo2c library tests passed\n' >result-expected
diff -b result-expected result
$OBECOMP TestLongStrings.mod -m
./TestLongStrings >result
printf 'LongStrings checks passed\n' >result-expected
diff -b result-expected result
$OBECOMP TestMessages.mod -m
./TestMessages >result
printf 'Unicode message checks passed\n' >result-expected
diff -b result-expected result
$OBECOMP TestOocChannels.mod -m
./TestOocChannels >result
printf 'oo2c channel compatibility checks passed\n' >result-expected
diff -b result-expected result
$OBECOMP TypeAliases.mod -s
$OBECOMP TestTypeAliases.mod -m
./TestTypeAliases >result
printf 'type-only aliases passed\n' >result-expected
diff -b result-expected result
$OBECOMP TestIntStr.mod -m
./TestIntStr >result
printf 'oo2c integer string tests passed\n' >result-expected
diff -b result-expected result
$OBECOMP TestLibraryNames.mod -m
./TestLibraryNames >result
printf 'library naming tests passed\n' >result-expected
diff -b result-expected result
$OBECOMP TestCompression.mod -m
./TestCompression >result
printf 'compression library tests passed\n' >result-expected
diff -b result-expected result
