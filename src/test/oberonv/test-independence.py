"""Check mandatory ALL independence before backend-specific lowering."""
import argparse
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument("--voc", required=True)
parser.add_argument("--vocroot", required=True)
parser.add_argument("--model", choices=("2", "C"), default="2")
parser.add_argument("--work", required=True)
parser.add_argument("--cpu", action="store_true")
parser.add_argument("--cc")
args = parser.parse_args()
voc = str(Path(args.voc).resolve())
image = Path(args.vocroot).resolve()
work = Path(args.work).resolve()
work.mkdir(parents=True, exist_ok=True)
env = dict(os.environ, VOCROOT=str(image), VOCLIBDIR=str(image / "lib"),
           OBERON=str(image / args.model / "sym"))
source = Path(__file__).resolve().parent
declarations = """IMPORT SYSTEM;
TYPE Vector = ARRAY 100 OF INTEGER;
  Buffer = POINTER TO Vector;
  Cell = RECORD value: INTEGER END;
  Link = POINTER TO Cell;
VAR a, b: Vector; p, q: Buffer; links: ARRAY 100 OF Link;
  cells: ARRAY 100 OF Cell; matrix: ARRAY 10, 10 OF INTEGER;
  flags: ARRAY 100 OF BOOLEAN;
  counter: INTEGER;
"""
cases = [
    ("Shift", "VAR dst, src: ARRAY OF INTEGER", "dst[i] := src[i+1]", 181),
    ("Copy", "VAR dst, src: ARRAY OF INTEGER", "dst[i] := src[i]", 181),
    ("ReadOnly", "VAR dst: ARRAY OF INTEGER; src-: ARRAY OF INTEGER", "dst[i] := src[i+1]", 181),
    ("Fixed", "VAR dst, src: Vector", "dst[i] := src[i+1]", 181),
    ("Writes", "VAR dst, src: ARRAY OF INTEGER", "dst[i] := 1; src[i+1] := 2", 181),
    ("Scalar", "VAR dst: ARRAY OF INTEGER; VAR x: INTEGER", "dst[i] := x", 181),
    ("IndexAlias", "VAR dst: ARRAY OF INTEGER; VAR x: INTEGER", "dst[i+x] := i", 181),
    ("Capture", "VAR dst: ARRAY OF INTEGER", "dst[i] := a[i+1]", 181),
    ("Pointers", "", "p[i] := q[i+1]", 181),
    ("PointerTable", "", "links[i].value := i", 180),
    ("RecordShift", "", "cells[i].value := cells[i+1].value", 166),
    ("RecordScatter", "", "cells[i MOD 2].value := i", 180),
    ("Modulo", "", "a[i MOD 2] := i", 180),
    ("Division", "", "a[i DIV 2] := i", 180),
    ("Cancellation", "", "a[i-i] := i", 180),
    ("Scatter", "", "a[b[i]] := i", 180),
    ("Narrow", "", "a[SHORT(i)] := i", 180),
    ("NarrowOffset", "", "a[SHORT(LONG(i)+65536)] := i", 180),
    ("UnknownRead", "", "a[i] := a[b[i]]", 181),
    ("IndexRead", "", "a[i] := b[a[i+1]]", 166),
    ("RecordIndexRead", "", "cells[i].value := b[cells[i+1].value]", 166),
    ("PointerRef", "VAR dst: Buffer", "dst[i] := i", 181),
    ("HeapAlias", "VAR src: ARRAY OF INTEGER", "p[i] := src[i+1]", 181),
    ("RecordRef", "VAR src: Cell", "cells[i].value := src.value", 181),
    ("Transpose", "", "matrix[i, j] := matrix[j, i]", 181),
    ("Flatten", "", "a[i+j] := i", 180),
    ("MemoryBit", "", "flags[i] := SYSTEM.BIT(SYSTEM.ADR(a), i)", 181),
    ("ConditionCode", "", "flags[i] := SYSTEM.CC(0)", 219),
]


def run(command, success=True):
    result = subprocess.run(list(map(str, command)), cwd=work, env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)
    assert (result.returncode == 0) == success, (command, result.stdout)
    return result.stdout


for mode in ("j", "jP", "jG"):
    for name, parameters, body, diagnostic in cases:
        module = "StrictBad" + name
        ranges = "i, j = 0 .. 3" if name in ("Transpose", "Flatten") else "i = 0 .. 98"
        path = work / (module + ".Mod")
        call = "BEGIN Test(a, a)\n" if name == "Shift" else ""
        path.write_text(f"MODULE {module};\n{declarations}\n"
                        f"PROCEDURE Test({parameters});\nBEGIN\n"
                        f"ALL {ranges} DO {body} END\nEND Test;\n{call}END {module}.\n")
        output = run([voc, "-O" + args.model, "-sSF" + mode, path], success=False)
        assert f"err {diagnostic} " in output, (mode, name, output)
        if diagnostic == 180:
            assert "destination mapping is not provably one-to-one" in output, output
        elif diagnostic == 181:
            assert "memory independence cannot be established" in output, output
        assert "Terminated by Halt" not in output, (mode, name, output)
    captured = work / "StrictCaptured.Mod"
    captured.write_text("MODULE StrictCaptured;\n" + declarations + """
PROCEDURE Outer;
  VAR local: Vector;
  PROCEDURE Inner(VAR dst: Vector);
  BEGIN ALL i = 0 .. 98 DO dst[i] := local[i+1] END END Inner;
BEGIN Inner(local) END Outer;
END StrictCaptured.
""")
    assert "err 181 " in run([voc, "-O" + args.model, "-sSF" + mode, captured], success=False)
    store = work / "StrictStore.Mod"
    store.write_text("MODULE StrictStore; VAR items*: ARRAY 100 OF INTEGER; END StrictStore.\n")
    run([voc, "-O" + args.model, "-sSF", store])
    aliases = work / "StrictImports.Mod"
    aliases.write_text("MODULE StrictImports; IMPORT X := StrictStore, Y := StrictStore;\n"
                       "BEGIN ALL i = 0 .. 98 DO X.items[i] := Y.items[i+1] END END StrictImports.\n")
    assert "err 166 " in run([voc, "-O" + args.model, "-sSF" + mode, aliases], success=False)
    print(f"{mode}: {len(cases) + 2} ambiguous or dependent ALL cases rejected")

compiler = shlex.split(args.cc) if args.cc else [next(
    (cc for cc in (("gcc", "clang", "cc") if args.cpu else ("gcc", "clang", "cc", "tcc"))
     if shutil.which(cc)), "")]
assert compiler[0], "no C compiler found"
for mode in (("jP",) if args.cpu else ("j",)):
    run([voc, "-O" + args.model, "-sSFm" + mode, source / "TestAllStrict.Mod"])
    executable = work / ("TestAllStrict-" + mode)
    run([*compiler, "-O2", "-fno-strict-aliasing", *(["-fopenmp"] if mode == "jP" else []),
         "-DVOC_MAIN_PROGRAM=1", "-I" + str(image / args.model / "include"),
         work / "TestAllStrict.c", image / "lib" / ("libvoc-O" + args.model + ".a"),
         *(["-ldl"] if sys.platform.startswith("linux") else []), "-lm", "-o", executable])
    for threads in ((1, 2, 4) if mode == "jP" else (1,)):
        env.update(OMP_NUM_THREADS=str(threads), OMP_THREAD_LIMIT=str(threads), OMP_DYNAMIC="FALSE")
        output = run([executable])
        assert "checks, 0 failed" in output, output
    print(mode + ": independent arrays, record fields, heap accesses and copied parameters passed")
