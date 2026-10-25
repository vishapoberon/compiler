"""Exercise XMLCheck resource limits with bounded hostile inputs."""

import argparse
import os
from pathlib import Path
import resource
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    parser.add_argument("--work", type=Path, default=Path("build/limits"))
    parser.add_argument("--timeout", type=int, default=10)
    parser.add_argument("--memory", type=int, default=0 if "ASAN_OPTIONS" in os.environ else 512,
                        help="address-space limit in MiB; 0 disables (default under ASan)")
    args = parser.parse_args()
    executable = args.executable.resolve()
    args.work.mkdir(parents=True, exist_ok=True)

    def constrain():
        resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
        resource.setrlimit(resource.RLIMIT_CPU, (args.timeout, args.timeout + 1))
        resource.setrlimit(resource.RLIMIT_FSIZE, (1024 * 1024, 1024 * 1024))
        if args.memory:
            size = args.memory * 1024 * 1024
            resource.setrlimit(resource.RLIMIT_AS, (size, size))

    def expansion(depth, fanout):
        declarations = ['<!ENTITY e0 "x">']
        for i in range(1, depth):
            declarations.append(f'<!ENTITY e{i} "' + f'&e{i-1};' * fanout + '">')
        return '<!DOCTYPE r [' + ''.join(declarations) + ']><r/>'

    cases = [
        ("elements", '<r>' * 10000 + '</r>' * 10000, (), "nesting"),
        ("model-depth", '<!DOCTYPE r [<!ELEMENT r ' + '(' * 10000 + 'r' + ')' * 10000 + '>]><r/>', (), "nesting"),
        ("model-width", '<!DOCTYPE r [<!ELEMENT r (' + ','.join(['r'] * 10000) + ')>]><r/>', (), "content-model"),
        ("unused-entities", expansion(12, 10), (), "limit exceeded"),
        ("entity-chain", expansion(10000, 1), (), "limit exceeded"),
        ("attribute", '<r a="' + 'x' * (1024 * 1024 + 1) + '"/>', (), "attribute value"),
        ("input", '<r>' + 'x' * (16 * 1024 * 1024) + '</r>', (), "input byte"),
        ("long-name", '<' + 'x' * (16 * 1024 * 1024) + '/>', (), "input byte"),
        ("many-attributes", '<r ' + ' '.join(f'a{i}=""' for i in range(100000)) + '/>', (), "limit exceeded"),
        ("siblings", '<r>' + '<s/>' * 100000 + '</r>', (), "processing work"),
        ("invalid-controls", '<r>' + '\x01' * 200000 + '</r>', (), "processing work"),
        ("invalid-charrefs", '<r>' + '&#xZ;' * 200000 + '</r>', (), "processing work"),
    ]
    (args.work / "external.dtd").write_text('<![INCLUDE[' * 10000 + ']]>' * 10000)
    cases.append(("conditional-depth", '<!DOCTYPE r SYSTEM "external.dtd"><r/>', ("--external",), "nesting"))
    parameters = ['<!ENTITY % p0 "x">']
    for i in range(1, 30):
        parameters.append(f'<!ENTITY % p{i} "' + f'%p{i-1};' * 2 + '">')
    (args.work / "parameters.dtd").write_text(''.join(parameters))
    cases.append(("parameter-expansion", '<!DOCTYPE r SYSTEM "parameters.dtd"><r/>', ("--external",), "limit exceeded"))
    (args.work / "large.ent").write_text('x' * (16 * 1024 * 1024))
    (args.work / "internalize.dtd").write_text('<!ENTITY % p SYSTEM "large.ent"><!ENTITY e "%p;">')
    cases.append(("internalize", '<!DOCTYPE r SYSTEM "internalize.dtd"><r/>', ("--external",), "input byte"))
    cases = [(name + suffix, text, (*flags, *extra), diagnostic)
             for name, text, flags, diagnostic in cases
             for suffix, extra in (("", ()), ("-namespaces", ("--namespaces",)),
                                   ("-validation", ("--validate",)))]
    cases.extend([
        ("validation-idrefs", '<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a IDREFS #IMPLIED>]><r a="'
         + ' '.join(f'id{i}' for i in range(10000)) + '"/>', ("--validate",), "processing work"),
        ("validation-enumeration", '<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a ('
         + '|'.join(f't{i}' for i in range(10000)) + ') #IMPLIED>]><r/>', ("--validate",), "processing work"),
        ("validation-closure", '<!DOCTYPE r [<!ELEMENT r ('
         + '|'.join(f'a{i}?' for i in range(200)) + ')>]><r/>', ("--validate",), "processing work"),
        ("validation-aggregate", '<!DOCTYPE r [' + ''.join(
            f'<!ELEMENT e{i} (' + '|'.join(f'a{j}?' for j in range(40)) + ')>' for i in range(100))
         + '<!ELEMENT r EMPTY>]><r/>', ("--validate",), "processing work"),
        ("namespace-search", ''.join(f'<r xmlns:p{i}="urn:p{i}">' for i in range(100))
         + '<r ' + ' '.join(f'p0:a{i}=""' for i in range(300)) + '/>' + '</r>' * 100,
         ("--namespaces",), "processing work"),
        ("canonical-notations", '<!DOCTYPE r [' + ''.join(
            f'<!NOTATION n{i} SYSTEM "n{i}">' for i in range(3000)) + ']><r/>', ("--second",), "processing work"),
        ("canonical-output", '<r>' + '>' * (4 * 1024 * 1024) + '</r>', ("--canonical",), "output byte"),
        ("protocol-output", '<r>' + '>' * (4 * 1024 * 1024) + '</r>', ("--protocol",), "output byte"),
    ])
    failures = []
    for name, text, flags, diagnostic in cases:
        path = args.work / f"{name}.xml"
        path.write_text(text)
        log = args.work / f"{name}.log"
        try:
            with log.open("wb") as output:
                result = subprocess.run([str(executable), *flags, str(path.resolve())],
                                        stdout=output, stderr=subprocess.STDOUT,
                                        timeout=args.timeout + 2, preexec_fn=constrain)
            actual = log.read_text(errors="replace")
            if result.returncode != 1 or diagnostic not in actual:
                failures.append(f"{name}: exit {result.returncode}: {actual[:2000]}")
        except subprocess.TimeoutExpired:
            failures.append(f"{name}: timeout")
    report = f"XML resource limits: {len(cases) - len(failures)}/{len(cases)} passed"
    (args.work / "results.txt").write_text('\n'.join([report, *failures]) + '\n')
    print(report)
    if failures:
        raise SystemExit('\n'.join(failures))


if __name__ == "__main__":
    main()
