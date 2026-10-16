#!/bin/sh
set -eu

root=$(CDPATH= cd "$(dirname "$0")/../../.." && pwd)
comparison="$root/src/tools/make/sourcechanges.sh"
temporary=$(mktemp -d "${TMPDIR:-/tmp}/voc-sourcechanges-test.XXXXXX")
trap 'rm -rf "$temporary"' 0
trap 'exit 1' HUP INT TERM

saved="$temporary/saved sources"
built="$temporary/build output"
mkdir "$saved" "$built" "$temporary/empty"

run() {
  (cd "$built" && sh "$comparison" "$1") >"$temporary/result" 2>&1
}

expect() {
  if ! grep -F "$1" "$temporary/result" >/dev/null; then
    cat "$temporary/result" >&2
    echo "Missing expected report: $1" >&2
    exit 1
  fi
}

expect_difference() {
  expect 'Generated c source files differ from bootstrap'
  if grep -F 'Generated c source files match bootstrap' "$temporary/result" >/dev/null; then
    cat "$temporary/result" >&2
    exit 1
  fi
}

# Version comments and wholly ignored files must not cause a false difference.
printf '/* voc old version */\nint value = 1;\n' >"$saved/Module.c"
printf '/* voc new version */\nint value = 1;\n' >"$built/Module.c"
printf 'Configuration_old\n' >"$saved/Configuration.c"
printf 'Configuration_new\n' >"$built/Configuration.c"
run "$saved"
expect 'Generated c source files match bootstrap'

# Existing files with the old script's temporary suffixes must be untouched.
for suffix in old new diff; do
  printf 'keep\n' >"$built/Module.c.$suffix"
done

# A real difference must not be forgotten when the comparison loop ends.
printf 'int value = 2;\n' >"$built/Module.c"
run "$saved"
expect_difference
expect 'int value = 1;'
expect 'int value = 2;'
for suffix in old new diff; do
  test "$(cat "$built/Module.c.$suffix")" = keep
done

rm "$built/Module.c"
run "$saved"
expect_difference
expect 'Missing generated source: Module.c'

if run "$temporary/empty"; then
  echo 'Accepting an empty bootstrap directory' >&2
  exit 1
fi
expect 'No bootstrap sources'

if run "$temporary/missing"; then
  echo 'Accepting a nonexistent bootstrap directory' >&2
  exit 1
fi
expect 'Usage:'

# Grep errors must not look like an ordinary empty filtered file.
mkdir "$temporary/bad filter"
cp "$comparison" "$temporary/bad filter/sourcechanges.sh"
comparison="$temporary/bad filter/sourcechanges.sh"
printf '[\n' >"$temporary/bad filter/ignore"
if run "$saved"; then
  echo 'Ignoring an invalid comparison filter' >&2
  exit 1
fi

echo 'Bootstrap source comparison tests passed.'
