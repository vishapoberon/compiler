"""Compare original parser and namespace callback protocol snapshots."""

import argparse
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    parser.add_argument("--work", type=Path, default=Path("build/conformance"))
    args = parser.parse_args()
    executable = args.executable.resolve()
    tests = Path(__file__).resolve().parents[1]
    args.work.mkdir(parents=True, exist_ok=True)
    cases = []
    for suite, valid_count, invalid_count, extra in (("protocol", 5, 1, ()),
                                                   ("namespaces", 9, 15, ("--namespaces",))):
        root = tests / suite
        for category, count, code in (("valid", valid_count, 0), ("not-wf", invalid_count, 1)):
            paths = sorted((root / category).glob("???.xml"))
            if len(paths) != count:
                raise SystemExit(f"Incomplete {suite}/{category} corpus: expected {count} cases, found {len(paths)}")
            cases.extend((root, path, extra, code) for path in paths)
    failures = []
    for root, path, extra, code in cases:
        name = path.relative_to(root).as_posix()
        label = root.name + '/' + name
        expected = (path.parent / "out" / path.name).read_bytes() if code == 0 else None
        try:
            result = subprocess.run([str(executable), "--external", "--protocol", *extra, name],
                                    cwd=root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=5)
            if result.returncode != code:
                failures.append(f"{label}: exit {result.returncode}\n"
                                + result.stdout.decode("utf-8", errors="replace"))
            elif expected is not None and result.stdout != expected:
                offset = next((i for i, (a, b) in enumerate(zip(result.stdout, expected)) if a != b),
                              min(len(result.stdout), len(expected)))
                failures.append(f"{label}: byte mismatch at {offset}\n"
                                f"actual: {result.stdout[offset:offset+100]!r}\n"
                                f"expected: {expected[offset:offset+100]!r}")
        except subprocess.TimeoutExpired:
            failures.append(f"{label}: timeout")
    (args.work / "parser-protocol.txt").write_text("\n".join(failures) + "\n", encoding="utf-8")
    print(f"Parser protocol checks: {len(cases) - len(failures)}/{len(cases)} passed")
    if failures:
        raise SystemExit("\n".join(failures))


if __name__ == "__main__":
    main()
