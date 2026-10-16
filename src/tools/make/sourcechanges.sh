#!/bin/sh
# Source change report.
#
# Compares compiler source files against the appropriate bootstrap source.
# Configured differences, including the compiler version comment, are ignored.
# Differences are reported without failing the build; comparison errors fail.
#
# Parameters
#
#   $1 - bootstrap directory
#
# Assumptions
#
#   The current directory is the build directory

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
  echo "Usage: $0 bootstrap-directory" >&2
  exit 2
fi

scriptdir=$(CDPATH= cd "$(dirname "$0")" && pwd) || exit 2
temporary=$(mktemp -d "${TMPDIR:-/tmp}/voc-sourcechanges.XXXXXX") || exit 2
trap 'rm -rf "$temporary"' 0
trap 'exit 2' HUP INT TERM

filter() {
  grep -E -v -f "$scriptdir/ignore" "$1" >"$2"
  status=$?
  # An entirely ignored file is valid empty input to diff.
  [ "$status" -le 1 ] || exit "$status"
}

changes=0
files=0
# Bootstrap source directories are flat. Keep this loop in the current shell
# so a detected difference is not lost when a pipeline subshell exits.
for f in "$1"/*; do
  [ -f "$f" ] || continue
  files=1
  fn=${f##*/}
  if [ ! -f "$fn" ]; then
    echo "Missing generated source: $fn" >&2
    changes=1
    continue
  fi
  filter "$f" "$temporary/old"
  filter "$fn" "$temporary/new"
  diff -U 2 -b "$temporary/old" "$temporary/new" >"$temporary/diff"
  status=$?
  case "$status" in
    0) ;;
    1)
      echo ""
      echo "Comparing $f with $fn:"
      cat "$temporary/diff"
      changes=1
      ;;
    *) exit "$status" ;;
  esac
done

if [ "$files" -eq 0 ]; then
  echo "No bootstrap sources in $1" >&2
  exit 2
fi

echo ""
if [ "$changes" -eq 0 ]; then
  echo "--- Generated c source files match bootstrap ---"
else
  echo "--- Generated c source files differ from bootstrap ---"
fi
echo ""
