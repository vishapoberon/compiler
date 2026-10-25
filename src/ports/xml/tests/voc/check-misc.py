"""Check the original local XML regressions and bulk canonical outputs."""

import argparse
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    parser.add_argument("--work", type=Path, default=Path("build/conformance"))
    args = parser.parse_args()
    tests = Path(__file__).resolve().parents[1]
    executable = args.executable.resolve()
    args.work.mkdir(parents=True, exist_ok=True)
    cases = []
    notes = []
    for directory in ("valid/sa", "valid/not-sa"):
        for path in sorted((tests / "miscxml" / directory).glob("???.xml")):
            reference = path.parent / "out" / path.name
            cases.append((path, ("--canonical", "--external"), 0, reference))
            if path.relative_to(tests).as_posix() == "miscxml/valid/sa/046.xml":
                cases.append((path, ("--canonical", "--validate"), 1, None))
                notes.append("Corrected historical expectation: miscxml/valid/sa/046.xml: "
                             "non-deterministic content model (XML 3.2.1)")
            else:
                cases.append((path, ("--canonical", "--validate"), 0, reference))
    for path in sorted((tests / "miscxml/wf").glob("???.xml")):
        cases.append((path, ("--canonical", "--external"), 0, path.parent / "out" / path.name))
    for path in sorted((tests / "miscxml/invalid").glob("???.xml")):
        cases.append((path, (), 0, None))
        cases.append((path, ("--validate",), 1, None))
    for path in sorted((tests / "miscxml/not-wf").glob("???.xml")):
        cases.append((path, ("--external",), 1, None))
    for path in sorted((tests / "bulk/valid").glob("*.xml")):
        cases.append((path, ("--canonical", "--external"), 0, path.parent / "out" / path.name))
    if len(cases) != 126 or len({(path, flags) for path, flags, _, _ in cases}) != 126:
        raise SystemExit(f"Incomplete local corpus: expected 126 checks, found {len(cases)}")
    failures = []
    for path, flags, code, reference in cases:
        name = path.relative_to(tests).as_posix() + ' ' + ' '.join(flags)
        try:
            result = subprocess.run([str(executable), *flags, str(path)],
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=5)
            if result.returncode != code:
                failures.append(f"{name}: exit {result.returncode}\n" + result.stdout.decode(errors="replace"))
            elif reference is not None:
                expected = reference.read_bytes()
                if result.stdout != expected:
                    offset = next((i for i, (a, b) in enumerate(zip(result.stdout, expected)) if a != b),
                                  min(len(result.stdout), len(expected)))
                    failures.append(f"{name}: byte mismatch at {offset}\n"
                                    f"actual: {result.stdout[offset:offset+100]!r}\n"
                                    f"expected: {expected[offset:offset+100]!r}")
        except subprocess.TimeoutExpired:
            failures.append(f"{name}: timeout")
    report = f"Local XML and bulk regressions: {len(cases) - len(failures)}/{len(cases)} passed"
    (args.work / "miscxml-bulk.txt").write_text('\n'.join([report, *notes, *failures]) + '\n')
    print(report)
    for note in notes:
        print(note)
    if failures:
        raise SystemExit('\n'.join(failures))


if __name__ == "__main__":
    main()
