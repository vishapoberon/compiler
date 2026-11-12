import argparse
import os
from pathlib import Path
import re
import select
import signal
import shutil
import subprocess
import sys
import time

parser = argparse.ArgumentParser()
parser.add_argument("--voc", required=True)
parser.add_argument("--vocroot", required=True)
parser.add_argument("--work", required=True)
parser.add_argument("--model", choices=("2", "C"), default="2")
parser.add_argument("--benchmark", action="store_true")
parser.add_argument("--hresh")
parser.add_argument("--modules")
args = parser.parse_args()
voc = str(Path(args.voc).resolve())
image = Path(args.vocroot).resolve()
work = Path(args.work).resolve()
work.mkdir(parents=True, exist_ok=True)
sources = Path(__file__).resolve().parent
env = dict(os.environ, VOCROOT=str(image), VOCLIBDIR=str(image / "lib"),
           OBERON=str(image / args.model / "sym"), CFLAGS="-O3 -fno-strict-aliasing",
           LDFLAGS="", LDLIBS="", VOC_OPENMP_CFLAGS="", VOC_OPENMP_LDFLAGS="",
           LD_LIBRARY_PATH=str(image / "lib") + os.pathsep + os.environ.get("LD_LIBRARY_PATH", ""))


def run(command, extra_env=None, success=True):
    result = subprocess.run(list(map(str, command)), cwd=work,
                            env=dict(env, **(extra_env or {})), text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
    assert (result.returncode == 0) == success, (command, result.stdout)
    return result.stdout


compilers = [cc for cc in ("gcc", "clang") if shutil.which(cc)]
assert compilers, "no OpenMP C compiler found"
output = run([voc, "-O" + args.model, "-sVjm", sources / "TestAll.Mod"], {
    "VOC_OPENMP_CFLAGS": "-invalid-openmp-compile-option",
    "VOC_OPENMP_LDFLAGS": "-invalid-openmp-link-option"})
assert "-fopenmp" not in output and "-invalid-openmp" not in output
for cc in compilers:
    output = run([voc, "-O" + args.model, "-sVjmP", sources / "TestAll.Mod"], {"CC": cc})
    assert "-fopenmp" in output
    for threads in (1, 2, 4):
        output = run([work / "TestAll"], {"OMP_NUM_THREADS": str(threads),
                                        "OMP_DYNAMIC": "FALSE", "OMP_THREAD_LIMIT": str(threads)})
        assert "ALL tests passed" in output
    print(cc + ": automatic OpenMP compilation and linking passed")

    output = run([voc, "-O" + args.model, "-sVjmP", sources / "TestAll.Mod"], {
        "CC": cc, "VOC_OPENMP_CFLAGS": "-fopenmp -DCPUFLAG_TEST=1",
        "VOC_OPENMP_LDFLAGS": "-fopenmp -Wl,--as-needed"})
    assert "-DCPUFLAG_TEST=1" in output and "-Wl,--as-needed" in output

    output = run([voc, "-O" + args.model, "-sVcjP", sources / "Vectorize.Mod"], {"CC": cc})
    assert "-fopenmp" in output and "-c Vectorize.c" in output
    assert (work / "Vectorize.o").exists()
    importer = work / "ParallelImport.Mod"
    importer.write_text("MODULE ParallelImport; IMPORT Vectorize; VAR i: LONGINT;\n"
                        "BEGIN FOR i := 0 TO LEN(Vectorize.b)-1 DO Vectorize.b[i] := i MOD 16 END;\n"
                        "Vectorize.Scale;\n"
                        "FOR i := 0 TO LEN(Vectorize.a)-1 DO ASSERT(Vectorize.a[i] = (i MOD 16)*2) END\n"
                        "END ParallelImport.\n")
    output = run([voc, "-O" + args.model, "-sVjmP", importer], {"CC": cc})
    assert "-fopenmp" in output and "Vectorize.o" in output
    run([work / "ParallelImport"], {"OMP_NUM_THREADS": "4", "OMP_DYNAMIC": "FALSE"})
    print(cc + ": separate OpenMP object linking passed")

if shutil.which("tcc"):
    output = run([voc, "-O" + args.model, "-sjmP", sources / "TestAll.Mod"],
                 {"CC": "tcc"}, success=False)
    assert "No OpenMP options configured for tcc" in output
    run([voc, "-O" + args.model, "-sSjmP", sources / "TestAll.Mod"], {"CC": "tcc"})

wrapper = work / "customcc"
wrapper.write_text('#!/bin/sh\nexec ' + compilers[0] + ' "$@"\n')
wrapper.chmod(0o755)
run([voc, "-O" + args.model, "-sjmP", sources / "TestAll.Mod"], {
    "CC": str(wrapper), "VOC_OPENMP_CFLAGS": "-fopenmp", "VOC_OPENMP_LDFLAGS": "-fopenmp"})
assert "ALL tests passed" in run([work / "TestAll"], {"OMP_NUM_THREADS": "4", "OMP_DYNAMIC": "FALSE"})
print("custom compiler OpenMP options passed")

if args.hresh or args.modules:
    assert args.hresh and args.modules, "--hresh and --modules must be used together"
    modules = str(Path(args.modules).resolve())
    shared_env = dict(env, CC=compilers[0], VOCLIBDIR=modules, OBERON=modules,
                      OMP_NUM_THREADS="4", OMP_DYNAMIC="FALSE", OMP_THREAD_LIMIT="4")
    for cc in compilers:
        run([voc, "-O" + args.model, "-sjmPL", sources / "TestAll.Mod"], dict(shared_env, CC=cc))
        assert "ALL tests passed" in run([work / "TestAll"], shared_env)
    run([voc, "-O" + args.model, "-sjlP", sources / "ParallelCommand.Mod"], shared_env)
    generated = (work / "ParallelCommand.c").read_text()
    for region in generated.split("#pragma omp parallel for")[1:]:
        start = region.index("{")
        depth = 0
        for end in range(start, len(region)):
            if region[end] == "{":
                depth += 1
            elif region[end] == "}":
                depth -= 1
                if depth == 0:
                    break
        assert depth == 0
        assert "SYSTEM_CheckCommandInterrupt" not in region[start:end]
    process = subprocess.Popen([str(Path(args.hresh).resolve()), "-P" + str(work) + ":" + modules],
                               cwd=work, env=shared_env, text=True,
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    try:
        process.stdin.write("ParallelCommand.Run\n")
        process.stdin.flush()
        output = ""
        deadline = time.monotonic() + 30
        while "parallel command started" not in output:
            assert process.poll() is None and time.monotonic() < deadline, output
            ready, _, _ = select.select([process.stdout], [], [], 1)
            if ready:
                output += os.read(process.stdout.fileno(), 4096).decode()
        time.sleep(0.05)
        process.send_signal(signal.SIGINT)
        output += process.communicate("ParallelCommand.Check\nquit\n", timeout=30)[0]
        assert process.returncode == 0, output
        assert "hresh: command stopped" in output and "parallel command recovered" in output, output
        assert "parallel command finished" not in output, output
    finally:
        if process.poll() is None:
            process.kill()
            process.communicate()
    print("shared OpenMP execution and command interruption passed")
    for cc in compilers:
        run([voc, "-O" + args.model, "-sjlP", sources / "ParallelCommand.Mod"], dict(shared_env, CC=cc))
        commands = "".join("ParallelCommand.Check\nsystem.Free ParallelCommand\n" for _ in range(3)) + "quit\n"
        result = subprocess.run([str(Path(args.hresh).resolve()), "-P" + str(work) + ":" + modules],
                                input=commands, cwd=work, env=shared_env, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
        assert result.returncode == 0 and result.stdout.count("parallel command recovered") == 3, result.stdout
        print(cc + ": shared OpenMP unload and reload passed")

if args.benchmark:
    cc = compilers[0]
    for mode in ("sequential", "cpu"):
        run([voc, "-O" + args.model, "-sSjm" + ("P" if mode == "cpu" else ""),
             sources / "ParallelArrays.Mod"])
        executable = work / ("ParallelArrays-" + mode)
        run([cc, "-O3", "-fno-strict-aliasing", *(["-fopenmp"] if mode == "cpu" else []),
             "-I" + str(image / args.model / "include"), work / "ParallelArrays.c",
             image / "lib" / ("libvoc-O" + args.model + ".a"),
             *(["-ldl"] if sys.platform.startswith("linux") else []), "-lm", "-o", executable])
        for threads in ((1, 2, 4) if mode == "cpu" else (1,)):
            process = subprocess.Popen([str(executable)], cwd=work, text=True,
                                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                       env=dict(env, OMP_NUM_THREADS=str(threads), OMP_DYNAMIC="FALSE",
                                                OMP_THREAD_LIMIT=str(threads)))
            maximum_threads = 0
            worker_ticks = 0
            deadline = time.monotonic() + 120
            while process.poll() is None:
                if time.monotonic() > deadline:
                    process.kill()
                    raise AssertionError("parallel array test timed out")
                tasks = Path("/proc") / str(process.pid) / "task"
                if tasks.exists():
                    try:
                        entries = list(tasks.iterdir())
                        maximum_threads = max(maximum_threads, len(entries))
                        for entry in entries:
                            if entry.name != str(process.pid):
                                fields = (entry / "stat").read_text().rpartition(")")[2].split()
                                worker_ticks = max(worker_ticks, int(fields[11]) + int(fields[12]))
                    except (FileNotFoundError, ProcessLookupError):
                        pass
                time.sleep(0.01)
            output = process.communicate()[0]
            assert process.returncode == 0 and "parallel array tests passed" in output, output
            elapsed = re.search(r"array elapsed ms: ([0-9]+)", output)
            assert elapsed, output
            if mode == "cpu" and threads > 1 and sys.platform.startswith("linux"):
                assert maximum_threads >= threads and worker_ticks > 0, (maximum_threads, worker_ticks)
            print(mode + ", threads=" + str(threads) + ": " + elapsed.group(1) +
                  " ms, observed threads=" + str(maximum_threads) + ", worker CPU ticks=" + str(worker_ticks))
