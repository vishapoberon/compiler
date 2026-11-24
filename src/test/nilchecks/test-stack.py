"""Check Unix alternate-stack delivery and bounded stack exhaustion."""

import argparse
import os
from pathlib import Path
import resource
import shutil
import signal
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--voc", required=True, type=Path)
    parser.add_argument("--vocroot", required=True, type=Path)
    parser.add_argument("--work", required=True, type=Path)
    parser.add_argument("--model", choices=("2", "C"), default="2")
    parser.add_argument("--cc", nargs="+")
    args = parser.parse_args()
    if sys.platform == "win32":
        parser.error("alternate signal stacks require Unix")
    source = Path(__file__).resolve().parent
    runtime = source.parents[1] / "runtime"
    image = args.vocroot.resolve()
    work = args.work.resolve()
    work.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, VOCROOT=str(image), VOCLIBDIR=str(image / "lib"),
               OBERON=str(image / args.model / "sym"))
    compilers = args.cc or [cc for cc in ("gcc", "clang", "tcc") if shutil.which(cc)]
    assert compilers, "no C compiler found"

    def run(command, limited=False):
        def constrain():
            resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
            if limited:
                _, hard = resource.getrlimit(resource.RLIMIT_STACK)
                limit = 256 * 1024
                assert hard == resource.RLIM_INFINITY or hard >= limit, hard
                resource.setrlimit(resource.RLIMIT_STACK, (limit, hard))

        return subprocess.run(list(map(str, command)), cwd=work, env=env,
                              text=True, capture_output=True, timeout=20,
                              preexec_fn=constrain)

    result = run([args.voc.resolve(), "-O" + args.model, "-sSFm", source / "TestStackFaults.Mod"])
    assert result.returncode == 0, result.stdout + result.stderr
    diagnostic = "Fatal error: invalid memory access (SIGSEGV).\n"
    warning = ("Warning: alternate signal stack unavailable; "
               "stack exhaustion may prevent fault reporting.\n")
    archive = image / "lib" / ("libvoc-O" + args.model + ".a")
    include = image / args.model / "include"

    for cc in compilers:
        common = [cc, "-O0", "-fno-strict-aliasing", "-DVOC_MAIN_PROGRAM=1", "-I" + str(include)]
        libraries = [archive, *(["-ldl"] if sys.platform.startswith("linux") else []), "-lm"]
        executable = work / ("TestStackFaults-" + cc)
        result = run([*common, work / "TestStackFaults.c", *libraries, "-o", executable])
        assert result.returncode == 0, result.stdout + result.stderr
        for case in ("recursion", "array", "raw"):
            result = run([executable, case], limited=True)
            assert result.returncode == 128 + signal.SIGSEGV, (cc, case, result)
            assert result.stderr == diagnostic, (cc, case, result)
            assert result.stdout == "entering fault test\n", (cc, case, result)

        executable = work / ("AltStackProbe-" + cc)
        result = run([*common, source / "AltStackProbe.c", *libraries, "-o", executable])
        assert result.returncode == 0, result.stdout + result.stderr
        for case in ("runtime", "host"):
            result = run([executable, case])
            assert result.returncode == 0, (cc, case, result)
            assert result.stdout == "alternate signal stack used\n" and not result.stderr, result

        failed = work / ("SYSTEM-failed-" + cc + ".o")
        result = run([*common, "-Dsigaltstack=TestSigaltstack", "-I" + str(runtime),
                      "-c", runtime / "SYSTEM.c", "-o", failed])
        assert result.returncode == 0, result.stdout + result.stderr
        executable = work / ("AltStackFailure-" + cc)
        result = run([*common, source / "AltStackFailure.c", failed, *libraries, "-o", executable])
        assert result.returncode == 0, result.stdout + result.stderr
        for case in ("query", "install"):
            result = run([executable, case])
            assert result.returncode == 128 + signal.SIGSEGV, (cc, case, result)
            assert result.stderr == warning + diagnostic and not result.stdout, result
        print(cc + ": 7 alternate-stack and fatal-fault checks passed", flush=True)


if __name__ == "__main__":
    main()
