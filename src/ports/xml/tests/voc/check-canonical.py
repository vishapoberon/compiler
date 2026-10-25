"""Compare canonical XML bytes with the bundled reference outputs."""

import argparse
from pathlib import Path
import re
import subprocess
import tarfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    parser.add_argument("--work", type=Path, default=Path("build/conformance"))
    args = parser.parse_args()
    tests = Path(__file__).resolve().parents[1]
    executable = args.executable.resolve()
    args.work.mkdir(parents=True, exist_ok=True)
    passed = True
    for suite, expected_count in (("xmltest", 163), ("ibm", 148), ("sun", 28)):
        with tarfile.open(tests / "3rd-party-archives" / f"{suite}.tar.gz") as archive:
            archive.extractall(args.work, filter="data")
        root = args.work / suite
        notes = []
        if suite == "sun":
            catalog = (root / "sun-valid.xml").read_text(encoding="utf-8")
            names = re.findall(r'<TEST\b[^>]*\bURI="([^"]*)"', catalog)
        else:
            names = []
            excluded = "valid/sa/065.xml" if suite == "xmltest" else "valid/P02/ibm02v01.xml"
            for path in sorted((root / "valid").glob("*/*.xml")):
                name = path.relative_to(root).as_posix()
                if name == excluded:
                    notes.append(f"Skipped (upstream exclusion): {name}")
                else:
                    names.append(name)
        if len(names) != expected_count or len(set(names)) != expected_count:
            raise SystemExit(f"Incomplete {suite} corpus: expected {expected_count} unique cases, found {len(names)}")
        failures = []
        for name in names:
            path = root / name
            reference = path.parent / "out" / path.name
            if not reference.is_file():
                failures.append(f"{name}: missing reference output {reference}")
                continue
            expected = reference.read_bytes()
            if suite == "sun" and name in ("valid/sa02.xml", "valid/not-sa02.xml"):
                old = b'nmtokens="this also gets normalized"'
                if expected.count(old) != 1:
                    raise SystemExit(f"Unexpected historical reference bytes: {reference}")
                expected = expected.replace(old, b'nmtokens="this&#13;&#10; also gets normalized"')
                notes.append(f"Corrected historical output: {name}: preserve character-reference CR/LF in NMTOKENS")
            try:
                flag = "--canonical" if suite == "xmltest" else "--second"
                result = subprocess.run(
                    [str(executable), "--external", flag, str(path.resolve())],
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=5,
                )
                if result.returncode:
                    failures.append(f"{name}: exit {result.returncode}\n"
                                    + result.stdout.decode("utf-8", errors="replace"))
                elif result.stdout != expected:
                    offset = next((i for i, (a, b) in enumerate(zip(result.stdout, expected)) if a != b),
                                  min(len(result.stdout), len(expected)))
                    failures.append(f"{name}: byte mismatch at {offset}\n"
                                    f"actual: {result.stdout[offset:offset+100]!r}\n"
                                    f"expected: {expected[offset:offset+100]!r}")
            except subprocess.TimeoutExpired:
                failures.append(f"{name}: timeout")
        report = args.work / f"{suite}-canonical.txt"
        report.write_text("\n".join(notes + failures) + "\n", encoding="utf-8")
        print(f"{suite} canonical output: {len(names) - len(failures)}/{len(names)} passed")
        for note in notes:
            print(note)
        if failures:
            print("\n".join(failures))
            passed = False
    if not passed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
