"""Exercise checked dereferences and fatal memory faults in separate processes."""
import argparse
import os
from pathlib import Path
import resource
import shutil
import signal
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument("--voc", required=True)
parser.add_argument("--vocroot", required=True)
parser.add_argument("--work", required=True, type=Path)
parser.add_argument("--model", choices=("2", "C"), default="2")
parser.add_argument("--cc", nargs="+")
args = parser.parse_args()
voc = str(Path(args.voc).resolve())
image = Path(args.vocroot).resolve()
work = args.work.resolve()
work.mkdir(parents=True, exist_ok=True)
source = Path(__file__).resolve().parent
env = dict(os.environ, VOCROOT=str(image), VOCLIBDIR=str(image / "lib"),
           OBERON=str(image / args.model / "sym"))
compilers = args.cc or [cc for cc in ("gcc", "clang", "tcc") if shutil.which(cc)]
assert compilers, "no C compiler found"
resource.setrlimit(resource.RLIMIT_CORE, (0, 0))


def run(command):
    return subprocess.run(list(map(str, command)), cwd=work, env=env,
                          text=True, capture_output=True, timeout=30)


def translate(path, options=""):
    result = run([voc, "-O" + args.model, "-sSFm" + options, path])
    assert result.returncode == 0, result.stdout + result.stderr
    return work / (path.stem + ".c")


def compile(csource, cc, optimization="-O2"):
    executable = work / (csource.stem + "-" + cc + optimization)
    result = run([cc, optimization, "-fno-strict-aliasing", "-DVOC_MAIN_PROGRAM=1",
                  "-I" + str(image / args.model / "include"), csource,
                  image / "lib" / ("libvoc-O" + args.model + ".a"),
                  *(["-ldl"] if sys.platform.startswith("linux") else []), "-lm", "-o", executable])
    assert result.returncode == 0, result.stdout + result.stderr
    return executable


declarations = """IMPORT SYSTEM, Out, Heap;
TYPE P = POINTER TO R;
  R = RECORD value: LONGINT; next: P; action: PROCEDURE END;
  E = RECORD (R) extra: LONGINT END;
  Q = POINTER TO E;
  Fixed = POINTER TO ARRAY 2 OF LONGINT;
  Dynamic = POINTER TO ARRAY OF LONGINT;
  Matrix = POINTER TO ARRAY OF ARRAY OF LONGINT;
  SR = RECORD value: LONGINT END;
  SP = POINTER TO SR;
VAR p, sentinel: P; q: Q; fixed: Fixed; dynamic: Dynamic; matrix: Matrix;
  simple: SP;
  action: PROCEDURE; function: PROCEDURE(): LONGINT;
  value: LONGINT; record: R; pointers: ARRAY 2 OF P;
  anonymous: RECORD dynamic: POINTER TO ARRAY OF LONGINT; fixed: POINTER TO ARRAY 2 OF LONGINT END;
PROCEDURE Finish(obj: SYSTEM.PTR);
BEGIN Out.String("finalizer ran"); Out.Ln; Out.Flush END Finish;
PROCEDURE Use(VAR x: LONGINT); BEGIN x := 1 END Use;
PROCEDURE Open(values: ARRAY OF LONGINT); BEGIN value := values[0] END Open;
PROCEDURE Copy(VAR x: R); BEGIN x.value := 1 END Copy;
PROCEDURE (p: P) Empty; BEGIN END Empty;
PROCEDURE (p: P) Get(): LONGINT; BEGIN RETURN 1 END Get;
PROCEDURE (VAR r: SR) RecordMethod; BEGIN END RecordMethod;
"""
cases = [
    ("ReadField", "value := p.value"),
    ("WriteField", "p.value := 1"),
    ("Explicit", "record := p^"),
    ("AssignRecord", "p^ := record"),
    ("Reference", "Use(p.value)"),
    ("RecordArgument", "Copy(p^)"),
    ("FixedRead", "value := fixed[0]"),
    ("FixedWrite", "fixed[0] := 1"),
    ("DynamicRead", "value := dynamic[0]"),
    ("DynamicWrite", "dynamic[0] := 1"),
    ("DynamicLength", "value := LEN(dynamic^)"),
    ("AnonymousDynamic", "value := anonymous.dynamic[0]"),
    ("AnonymousFixed", "value := anonymous.fixed[0]"),
    ("MatrixLength", "value := LEN(matrix^, 1)"),
    ("MatrixIndex", "value := matrix[0, 0]"),
    ("OpenArgument", "Open(dynamic^)"),
    ("Chain", "NEW(p); value := p.next.value"),
    ("PointerArray", "value := pointers[0].value"),
    ("Guard", "q := p(Q)"),
    ("Method", "p.Empty"),
    ("MethodResult", "value := p.Get()"),
    ("RecordMethod", "simple.RecordMethod"),
    ("Procedure", "action()"),
    ("Function", "value := function()"),
    ("ProcedureField", "NEW(p); p.action()"),
    ("Address", "value := SYSTEM.VAL(LONGINT, SYSTEM.ADR(p.value))"),
]


def module(name, body):
    path = work / (name + ".Mod")
    path.write_text("MODULE " + name + ";\n" + declarations + "\nBEGIN\n"
                    "NEW(sentinel); Heap.RegisterFinalizer(sentinel, Finish);\n"
                    "p := NIL; q := NIL; fixed := NIL; dynamic := NIL; matrix := NIL; simple := NIL;\n"
                    "action := NIL; function := NIL;\n" + body + ";\n"
                    'Out.Int(value, 0); Out.Ln;\n'
                    'Out.String("unexpected continuation"); Out.Ln\nEND ' + name + ".\n")
    return path


positive = translate(source / "TestNilChecks.Mod")
for cc in compilers:
    for optimization in (("-O0", "-O2") if cc != "tcc" else ("-O2",)):
        result = run([compile(positive, cc, optimization)])
        assert result.returncode == 0 and "checks, 0 failed" in result.stdout, result
    print(cc + ": valid pointers, NIL comparisons and single-evaluation checks passed", flush=True)

for name, body in cases:
    csource = translate(module("Nil" + name, body))
    for cc in compilers:
        result = run([compile(csource, cc)])
        assert result.returncode == (-10) % 256, (name, cc, result)
        assert "Terminated by Halt(-10). NIL pointer dereference." in result.stdout, result
        assert "finalizer ran" in result.stdout, result
        assert "SIGSEGV" not in result.stdout + result.stderr, result
        assert "unexpected continuation" not in result.stdout, result
print(str(len(cases)) + " NIL dereference cases trapped before memory access", flush=True)

for name, body, code, diagnostic in (
        ("WrongGuard", "NEW(p); q := p(Q)", -5, "Type guard failed."),
        ("WrongRecord", "NEW(q); p := q; p^ := record", -6,
         "Implicit type guard in record assignment failed."),
        ("WrongBounds", "NEW(dynamic, 1); value := dynamic[1]", -2, "Index out of range.")):
    csource = translate(module(name, body))
    for cc in compilers:
        result = run([compile(csource, cc)])
        assert result.returncode == code % 256, (name, cc, result)
        assert f"Terminated by Halt({code}). {diagnostic}" in result.stdout, result
        assert "SIGSEGV" not in result.stdout + result.stderr, result
print("Type-guard, record-assignment and bounds diagnostics preserved", flush=True)

# Other safety toggles must not disable NIL checking.
path = module("NilIndependent", "p.value := 1")
for options in ("t", "x", "p", "txp", "nn"):
    csource = translate(path, options)
    result = run([compile(csource, compilers[0])])
    assert "Halt(-10). NIL pointer dereference." in result.stdout, result

for name, body, options in (
        ("RawGet", "SYSTEM.GET(1, value)", ""),
        ("RawPut", "SYSTEM.PUT(1, value)", ""),
        ("Forged", "p := SYSTEM.VAL(P, 1); value := p.value", ""),
        ("Unchecked", "p.value := 1", "n")):
    csource = translate(module(name, body), options)
    if options == "n":
        assert "__NIL(" not in csource.read_text(), csource
    for cc in compilers:
        result = run([compile(csource, cc)])
        assert result.returncode == 128 + signal.SIGSEGV, (name, cc, result)
        assert result.stderr == "Fatal error: invalid memory access (SIGSEGV).\n", result
        assert "Halt(-10)" not in result.stdout + result.stderr, result
        assert "finalizer ran" not in result.stdout, result
        assert "unexpected continuation" not in result.stdout, result
print("SIGSEGV faults reported separately without running finalizers", flush=True)
