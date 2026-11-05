#!/bin/sh
set -eu

# Compile each saved Unix runtime's feature preamble before system headers.
# FreeBSD exposes gettimeofday, OCRNL and ONLCR through its XSI namespace.
root=$(CDPATH= cd "$(dirname "$0")/../../.." && pwd)
temporary=$(mktemp -d "${TMPDIR:-/tmp}/voc-unix-features.XXXXXX")
trap 'rm -rf "$temporary"' 0
trap 'exit 1' HUP INT TERM

for model in unix-44 unix-48 unix-88; do
    for module in Platform PlatformNative; do
        source="$root/bootstrap/$model/$module.c"
        sed -n '/^#ifndef _POSIX_C_SOURCE/,/^#include </p' "$source" |
            sed '/^#include </d' >"$temporary/probe.c"
        cat >>"$temporary/probe.c" <<'EOF'
#if !defined(_POSIX_C_SOURCE) || _POSIX_C_SOURCE < 200809L
#error "The Unix runtime requires POSIX.1-2008 declarations before libc headers."
#endif
#if !defined(_XOPEN_SOURCE) || _XOPEN_SOURCE < 700
#error "The Unix runtime requires XSI declarations before libc headers."
#endif
#include <sys/time.h>
#include <termios.h>
int voc_unix_features(void) {
    struct timeval value;
    return gettimeofday(&value, 0) + OPOST + OCRNL + ONLCR;
}
EOF
        ${CC:-cc} -Werror=implicit-function-declaration \
            -c "$temporary/probe.c" -o "$temporary/probe.o"
    done
done

echo 'Unix bootstrap feature declarations passed.'
