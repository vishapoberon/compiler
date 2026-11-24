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
    overflow = "Fatal error: stack overflow (SIGSEGV).\n"
    warning = ("Warning: alternate signal stack unavailable; "
               "stack exhaustion may prevent fault reporting.\n")
    archive = image / "lib" / ("libvoc-O" + args.model + ".a")
    include = image / args.model / "include"

    for cc in compilers:
        common = [cc, "-O0", "-fno-strict-aliasing", "-DVOC_MAIN_PROGRAM=1", "-I" + str(include)]
        libraries = [archive, *(["-ldl"] if sys.platform.startswith("linux") else []), "-lm"]
        probe = work / ("StackBoundsProbe-" + cc)
        result = run([*common, source / "StackBoundsProbe.c", *libraries, "-o", probe])
        assert result.returncode == 0, result.stdout + result.stderr
        result = run([probe], limited=True)
        assert result.returncode in (0, 77, 78), (cc, result)
        classified = result.returncode == 0
        if (sys.platform.startswith("linux") and result.returncode != 78
                and os.access("/proc/self/maps", os.R_OK)):
            assert classified, (cc, "Linux main-stack discovery failed", result)
        executable = work / ("TestStackFaults-" + cc)
        result = run([*common, work / "TestStackFaults.c", *libraries, "-o", executable])
        assert result.returncode == 0, result.stdout + result.stderr
        for case in ("recursion", "array", "raw"):
            result = run([executable, case], limited=True)
            assert result.returncode == 128 + signal.SIGSEGV, (cc, case, result)
            expected = overflow if classified and case != "raw" else diagnostic
            assert result.stderr == expected, (cc, case, result)
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
        result = run([args.voc.resolve(), "-O" + args.model, "-sSF", runtime / "PlatformNativeunix.Mod"])
        assert result.returncode == 0, result.stdout + result.stderr
        unavailable = work / ("PlatformNative-failed-" + cc + ".o")
        result = run([*common, "-Dgetrlimit=TestGetrlimit", "-I" + str(runtime),
                      "-c", work / "PlatformNative.c", "-o", unavailable])
        assert result.returncode == 0, result.stdout + result.stderr
        for unlimited in (0, 1):
            executable = work / ("StackLimitFailure-" + cc + str(unlimited))
            result = run([*common, "-DTEST_UNLIMITED_STACK=" + str(unlimited),
                          work / "TestStackFaults.c", source / "StackLimitFailure.c", unavailable,
                          *libraries, "-o", executable])
            assert result.returncode == 0, result.stdout + result.stderr
            result = run([executable, "recursion"], limited=True)
            assert result.returncode == 128 + signal.SIGSEGV, (cc, unlimited, result)
            assert result.stderr == diagnostic and result.stdout == "entering fault test\n", result
        print(cc + ": stack classification/fallback, alternate-stack delivery and fatal-fault checks passed", flush=True)


if __name__ == "__main__":
    main()
