"""Run reproducible XML truncations and byte mutations under process limits."""

import argparse
import os
from pathlib import Path
import random
import resource
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    parser.add_argument("--work", type=Path, default=Path("build/fuzz"))
    parser.add_argument("--seed", type=int, default=20261025)
    parser.add_argument("--mutations", type=int, default=160)
    args = parser.parse_args()
    executable = args.executable.resolve()
    args.work.mkdir(parents=True, exist_ok=True)
    seeds = [
        b'<r/>', b'<?xml version="1.0"?><r a="x">text<!--comment--><?pi x?></r>',
        b'<!DOCTYPE r [<!ELEMENT r (s*)><!ELEMENT s EMPTY><!ATTLIST s a ID #IMPLIED>]><r><s a="x"/></r>',
        b'<!DOCTYPE r [<!ENTITY a "text"><!ENTITY b "&a;&a;">]><r a="&b;">&b;</r>',
        b'<r xmlns="urn:test" xmlns:p="urn:p" p:a="x"><p:s/><![CDATA[a<b]]></r>',
        '<\u0531 a="\U0001f642">&#x1F642;&#13;\u0531</\u0531>'.encode(),
        b'<!DOCTYPE r [<!NOTATION n SYSTEM "n"><!ENTITY u SYSTEM "u" NDATA n>]><r/>',
    ]
    rng = random.Random(args.seed)
    cases = {b'', b'\x00', b'\xff\xfe', b'\xfe\xff', b'\xef\xbb\xbf'}
    for seed in seeds:
        cases.update(seed[:i] for i in range(len(seed) + 1))
    alphabet = b'<>!?[]()/&;="\'%-:abc012 \t\r\n\x00\x01\x80\xff'
    for _ in range(args.mutations):
        text = bytearray(rng.choice(seeds))
        for _ in range(rng.randrange(1, 9)):
            start = rng.randrange(len(text) + 1)
            end = min(len(text), start + rng.randrange(0, 12))
            text[start:end] = bytes(rng.choice(alphabet) for _ in range(rng.randrange(0, 12)))
        cases.add(bytes(text))

    def constrain():
        resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
        resource.setrlimit(resource.RLIMIT_CPU, (3, 4))
        resource.setrlimit(resource.RLIMIT_FSIZE, (1024 * 1024, 1024 * 1024))
        if "ASAN_OPTIONS" not in os.environ:
            size = 512 * 1024 * 1024
            resource.setrlimit(resource.RLIMIT_AS, (size, size))

    modes = ((), ("--namespaces",), ("--validate",), ("--canonical",), ("--protocol",))
    failures = []
    count = 0
    for i, text in enumerate(sorted(cases)):
        path = args.work / f"{i:04}.xml"
        path.write_bytes(text)
        for j, flags in enumerate(modes):
            count += 1
            log = args.work / f"{i:04}-{j}.log"
            try:
                with log.open("wb") as output:
                    result = subprocess.run([str(executable), *flags, str(path.resolve())],
                                            stdout=output, stderr=subprocess.STDOUT,
                                            timeout=5, preexec_fn=constrain)
                if result.returncode not in (0, 1):
                    failures.append(f"{path.name} {flags}: exit {result.returncode}: "
                                    + log.read_text(errors="replace")[:1000])
            except subprocess.TimeoutExpired:
                failures.append(f"{path.name} {flags}: timeout")
    report = f"XML mutation checks (seed {args.seed}): {count - len(failures)}/{count} passed"
    (args.work / "results.txt").write_text('\n'.join([report, *failures]) + '\n')
    print(report)
    if failures:
        raise SystemExit('\n'.join(failures))


if __name__ == "__main__":
    main()
