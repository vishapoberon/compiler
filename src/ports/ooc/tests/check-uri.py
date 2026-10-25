"""Replay preserved ooc-libxml URI fixtures against the shared URI package."""

import argparse
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    parser.add_argument("--work", type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parent / "uri"
    args.work.mkdir(parents=True, exist_ok=True)
    failures = []
    count = 0
    notes = []
    for group, expected_count in (("wf", 50), ("not-wf", 9), ("abs2rel", 18)):
        fixtures = sorted((root / group).glob("*.txt"))
        assert len(fixtures) == expected_count
        for fixture in fixtures:
            count += 1
            fields = dict(line.split('\t', 1) for line in fixture.read_text().splitlines()
                          if line.startswith(("TEST\t", "BASE\t")))
            command = [str(args.executable.resolve()), fields["TEST"], fields.get("BASE", "")]
            if group == "abs2rel":
                command.append("abs2rel")
            result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=5)
            path = args.work / group / fixture.name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(result.stdout)
            if group == "not-wf":
                ok = result.returncode == 1
            else:
                expected = (fixture.parent / "out-xml" / fixture.name).read_bytes()
                if group == "wf" and fixture.name == "017.txt":
                    old = b'<segment>\n<value></value>\n</segment>'
                    assert expected.count(old) == 1
                    expected = expected.replace(old, b'<segment>\n<value>d</value>\n<parameter>p</parameter>\n</segment>')
                    expected = expected.replace(b'<uri-string>http://a/b/c/?y</uri-string>',
                                                b'<uri-string>http://a/b/c/d;p?y</uri-string>')
                    notes.append("Corrected wf/017.txt: query-only references preserve the base path")
                if group == "wf" and fixture.name == "050.txt":
                    old = b'<uri-string>http://a/b/c/..</uri-string>'
                    assert expected.count(old) == 1
                    expected = expected.replace(old, b'<uri-string>http://a/b/c/%2E%2E</uri-string>')
                    notes.append("Corrected wf/050.txt: retain escaped dot segments during serialization")
                ok = result.returncode == 0 and result.stdout == expected
            if not ok:
                failures.append(f"{group}/{fixture.name}: exit {result.returncode}; output {path}")
    report = f"Original URI fixtures: {count - len(failures)}/{count} passed"
    (args.work / "results.txt").write_text('\n'.join([report, *notes, *failures]) + '\n')
    print(report)
    for note in notes:
        print(note)
    if failures:
        raise SystemExit('\n'.join(failures))


if __name__ == "__main__":
    main()
