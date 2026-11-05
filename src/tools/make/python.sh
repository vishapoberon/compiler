#!/bin/sh
# Run build-time tests with Python 3, including hosts that name it "python".

is_python3() {
    command -v "$1" >/dev/null 2>&1 || return 1
    "$1" -c 'import sys; sys.exit(sys.version_info[0] != 3)' >/dev/null 2>&1
}

if [ -n "${PYTHON:-}" ]; then
    interpreter=$PYTHON
    if ! is_python3 "$interpreter"; then
        echo "PYTHON must name a Python 3 interpreter: $interpreter" >&2
        exit 2
    fi
else
    interpreter=
    for candidate in python3 python; do
        if is_python3 "$candidate"; then
            interpreter=$candidate
            break
        fi
    done
    if [ -z "$interpreter" ]; then
        echo 'Python 3 is required for tests; install python3 or python, or set PYTHON.' >&2
        exit 127
    fi
    if [ "$interpreter" = python ]; then
        echo 'Using python (verified Python 3; no usable python3 command).' >&2
    fi
fi

exec "$interpreter" "$@"
