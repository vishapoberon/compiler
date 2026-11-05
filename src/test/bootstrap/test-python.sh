#!/bin/sh
set -eu

root=$(CDPATH= cd "$(dirname "$0")/../../.." && pwd)
launcher="$root/src/tools/make/python.sh"
shell=$(command -v sh)
temporary=$(mktemp -d "${TMPDIR:-/tmp}/voc-python-test.XXXXXX")
trap 'rm -rf "$temporary"' 0
trap 'exit 1' HUP INT TERM
mkdir "$temporary/both" "$temporary/python-only" "$temporary/empty" "$temporary/with spaces"

cat >"$temporary/interpreter" <<'EOF'
#!/bin/sh
if [ "${1:-}" = -c ]; then
    case "${0##*/}" in
        python3) exit "${PYTHON3_STATUS:-0}" ;;
        *) exit "${PYTHON_STATUS:-0}" ;;
    esac
fi
printf '%s\n' "${0##*/}" "$@"
exit "${RUN_STATUS:-0}"
EOF
chmod +x "$temporary/interpreter"
cp "$temporary/interpreter" "$temporary/both/python3"
cp "$temporary/interpreter" "$temporary/both/python"
cp "$temporary/interpreter" "$temporary/python-only/python"
cp "$temporary/interpreter" "$temporary/with spaces/custom python"

run() {
    PATH="$1" PYTHON="$2" "$shell" "$launcher" 'argument with spaces' --flag
}

expect_selected() {
    expected=$(printf '%s\n' "$3" 'argument with spaces' --flag)
    actual=$(run "$1" "$2")
    test "$actual" = "$expected"
}

expect_selected "$temporary/both" '' python3
expect_selected "$temporary/python-only" '' python
PYTHON3_STATUS=1 expect_selected "$temporary/both" '' python
expect_selected "$temporary/both" "$temporary/with spaces/custom python" 'custom python'

status=0
run "$temporary/empty" '' >"$temporary/error" 2>&1 || status=$?
test "$status" -eq 127
grep -F 'Python 3 is required' "$temporary/error" >/dev/null

status=0
PYTHON3_STATUS=1 PYTHON_STATUS=1 run "$temporary/both" '' >"$temporary/error" 2>&1 || status=$?
test "$status" -eq 127

status=0
PYTHON_STATUS=1 run "$temporary/both" "$temporary/both/python" >"$temporary/error" 2>&1 || status=$?
test "$status" -eq 2
grep -F 'PYTHON must name a Python 3 interpreter' "$temporary/error" >/dev/null

status=0
RUN_STATUS=7 run "$temporary/both" '' >"$temporary/output" 2>&1 || status=$?
test "$status" -eq 7

echo 'Python interpreter selection tests passed.'
