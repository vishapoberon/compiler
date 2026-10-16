#!/bin/sh
set -e
. ../confidence/testenv.sh

fixture=$(mktemp -d "${TMPDIR:-/tmp}/voc-directory-test.XXXXXX")
trap 'rm -rf "$fixture"' 0
trap 'exit 1' HUP INT TERM
mkdir "$fixture/child"
: >"$fixture/file.txt"
ln -s child "$fixture/link"

# In the C type model LONGINT may be wider than an address. Check both
# runtime libraries, not just the compiler's default Oberon-2 model.
for model in 2 C; do
  $OBECOMP -O$model testDirectories.Mod -m
  ./testDirectories "$fixture" >result
  printf 'directory API passed\n' >result-expected
  diff -b result-expected result
  $OBECOMP -O$model TestPlatformTime.Mod -m
  TZ=UTC0 ./TestPlatformTime "$fixture/mtime" >result
  printf 'platform time tests passed\n' >result-expected
  diff -b result-expected result
done

echo 'Platform directory and time tests passed in both type models.'
