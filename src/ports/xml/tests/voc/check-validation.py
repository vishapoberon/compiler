"""Check DTD validation against the bundled XML conformance archives."""

import argparse
from pathlib import Path
import re
import subprocess
import tarfile


def run_cases(executable, root, cases, report, notes=()):
    failures = []
    count = 0
    for name, valid in cases:
        count += 1
        try:
            result = subprocess.run(
                [str(executable), "--validate", str((root / name).resolve())],
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=5,
            )
            if result.returncode != (0 if valid else 1):
                failures.append(f"{name}: exit {result.returncode}\n"
                                + result.stdout.decode("utf-8", errors="replace"))
        except subprocess.TimeoutExpired:
            failures.append(f"{name}: timeout")
    report.write_text("\n".join([*notes, *failures]) + "\n", encoding="utf-8")
    print(f"{root.name} DTD validation: {count - len(failures)}/{count} passed")
    for note in notes:
        print(note)
    if failures:
        print("\n".join(failures))
    return not failures


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    parser.add_argument("--work", type=Path, default=Path("build/conformance"))
    args = parser.parse_args()
    tests = Path(__file__).resolve().parents[1]
    executable = args.executable.resolve()
    args.work.mkdir(parents=True, exist_ok=True)
    passed = True
    for suite in ("xmltest", "ibm", "sun", "oasis"):
        with tarfile.open(tests / "3rd-party-archives" / f"{suite}.tar.gz") as archive:
            archive.extractall(args.work, filter="data")
        root = args.work / suite
        cases = []
        notes = []
        corrections = {}
        if suite in ("xmltest", "ibm"):
            excluded = {
                "xmltest": {
                    "valid/sa/065.xml": "malformed entity replacement",
                    "valid/not-sa/022.xml": "improper conditional-section/parameter-entity nesting",
                },
                "ibm": {
                    "valid/P02/ibm02v01.xml": "encoding errors in fixture",
                    "valid/P58/ibm58v01.xml": "duplicate NOTATION tokens",
                },
            }[suite]
            for category in ("valid", "invalid", "not-wf"):
                for path in sorted((root / category).glob("*/*.xml")):
                    name = path.relative_to(root).as_posix()
                    if name in excluded:
                        notes.append(f"Skipped (upstream exclusion): {name}: {excluded[name]}")
                    else:
                        cases.append((name, category == "valid"))
            expected = {"xmltest": 359, "ibm": 932}[suite]
            if suite == "ibm":
                corrections = {
                    "valid/P45/ibm45v01.xml": (False, "non-deterministic content model (XML 3.2.1)"),
                    "valid/P47/ibm47v01.xml": (False, "non-deterministic content models (XML 3.2.1)"),
                    "valid/P57/ibm57v01.xml": (False, "NOTATION attribute on EMPTY element (XML 3.3.1)"),
                }
        elif suite == "sun":
            # These four catalog fragments identify fixtures; directory globs
            # would also include copies of the catalog fragments themselves.
            for catalog in ("valid", "invalid", "not-wf", "error"):
                text = (root / f"sun-{catalog}.xml").read_text(encoding="utf-8")
                for tag in re.findall(r"<TEST\b[^>]*>", text):
                    attrs = dict(re.findall(r'([A-Z]+)="([^"]*)"', tag))
                    cases.append((attrs["URI"], attrs["TYPE"] == "valid"))
            corrections = {
                "valid/sa02.xml": (False, "character-reference CR/LF remain invalid in NMTOKENS (erratum E20)"),
                "valid/not-sa02.xml": (False, "character-reference CR/LF remain invalid in NMTOKENS (erratum E20)"),
                "valid/optional.xml": (False, "non-deterministic content models (XML 3.2.1)"),
                "invalid/attr11.xml": (True, "unused ENTITY default is syntactically valid (erratum E9)"),
                "invalid/attr12.xml": (True, "unused ENTITIES default is syntactically valid (erratum E9)"),
                "invalid/pe01.xml": (True, "percent signs are literal in attribute defaults"),
                **{f"not-wf/lang{i:02}.xml": (True, "xml:lang is declared as CDATA; its semantics are application-level")
                   for i in range(1, 7)},
            }
            expected = 171
        else:
            for category in ("valid", "invalid", "not-wf"):
                cases.extend((name, category == "valid") for name in
                             (tests / "oasis" / f"{category}.list").read_text().split())
            expected = 346
            corrections = {
                name: (False, "NOTATION attribute on EMPTY element (XML 3.3.1)")
                for name in ("p57pass1.xml", "p58pass1.xml")
            }
        cases = [(name, corrections.get(name, (valid, ""))[0]) for name, valid in cases]
        notes.extend(f"Corrected historical expectation: {name}: {reason}"
                     for name, (_, reason) in corrections.items())
        if len(cases) != expected or len({name for name, _ in cases}) != expected:
            raise SystemExit(f"Incomplete {suite} corpus: expected {expected} unique cases, found {len(cases)}")
        passed = run_cases(executable, root, cases, args.work / f"{suite}-validation.txt", notes) and passed
    if not passed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
