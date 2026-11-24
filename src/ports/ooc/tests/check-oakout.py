#!/usr/bin/env python3
"""Check Oakwood output formatting from the standalone fixture program."""

import subprocess
import sys


def main():
    result = subprocess.run([sys.argv[1]], capture_output=True, text=True, check=True)
    lines = result.stdout.splitlines()
    expected = [
        "[OakOut]",
        "   -3|3|42",
        None,
        None,
        "   1.5E+00|-5.0E-03",
        "0.0E+00|1.0E+02",
        "   1.5E+000|-5.0E-003",
        "0.0E+000|1.0E+001|1.0E+100",
        "reopened",
    ]
    if len(lines) != len(expected):
        raise AssertionError(f"unexpected output: {result.stdout!r}")
    for index, (actual, wanted) in enumerate(zip(lines, expected), 1):
        if wanted is None:
            left, right = actual.split("|")
            if left != right or int(left) == 0:
                raise AssertionError(f"line {index}: integer limit mismatch: {actual!r}")
        elif actual != wanted:
            raise AssertionError(f"line {index}: expected {wanted!r}, got {actual!r}")
    if result.stderr:
        raise AssertionError(f"unexpected stderr: {result.stderr!r}")
    print("OakOut: 9 output checks, 0 failed")


if __name__ == "__main__":
    main()
