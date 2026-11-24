"""Exercise checked dereferences and fatal memory faults in separate processes."""
import argparse
import os
from pathlib import Path
import resource
import re
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


def compile(csource, cc, optimization="-O2", extra_sources=()):
    executable = work / (csource.stem + "-" + cc + optimization)
    result = run([cc, optimization, "-fno-strict-aliasing", "-DVOC_MAIN_PROGRAM=1",
                  "-I" + str(image / args.model / "include"), csource, *extra_sources,
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
  storage: ARRAY 2 OF LONGINT; grid: ARRAY 2, 3 OF LONGINT;
  anonymous: RECORD dynamic: POINTER TO ARRAY OF LONGINT; fixed: POINTER TO ARRAY 2 OF LONGINT END;
PROCEDURE Finish(obj: SYSTEM.PTR);
BEGIN
  sentinel.value := 0; value := 0; value := storage[value];
  Out.String("finalizer ran"); Out.Ln; Out.Flush
END Finish;
PROCEDURE Use(VAR x: LONGINT); BEGIN x := 1 END Use;
PROCEDURE Open(values: ARRAY OF LONGINT); BEGIN value := values[0] END Open;
PROCEDURE Copy(VAR x: R); BEGIN x.value := 1 END Copy;
PROCEDURE (p: P) Empty; BEGIN END Empty;
PROCEDURE (p: P) Get(): LONGINT; BEGIN RETURN 1 END Get;
PROCEDURE (VAR r: SR) RecordMethod; BEGIN END RecordMethod;
PROCEDURE BadIndex(): LONGINT;
BEGIN Out.String("index evaluated"); Out.Ln; RETURN 2 END BadIndex;
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


def check_location(result, path, marker=None, module_name=None):
    pattern = (rf"^{re.escape(str(path))}:(\d+):(\d+): runtime error: .*"
               rf"\(module {re.escape(module_name or path.stem)}, pos (\d+)\)$")
    match = re.search(pattern, result.stdout, re.MULTILINE)
    assert match, (path, result)
    data = path.read_bytes()
    pos = int(match[3])
    if marker is not None:
        assert pos == data.rindex(marker.encode()), (path, marker, result)
    prefix = data[:pos]
    line = prefix.replace(b"\r\n", b"\n").replace(b"\r", b"\n").count(b"\n") + 1
    column = pos - max(prefix.rfind(b"\r"), prefix.rfind(b"\n"))
    assert (int(match[1]), int(match[2])) == (line, column), (path, result)


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
        check_location(result, work / ("Nil" + name + ".Mod"))
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
        check_location(result, work / (name + ".Mod"))
        assert "SIGSEGV" not in result.stdout + result.stderr, result
print("Type-guard, record-assignment and bounds diagnostics preserved", flush=True)

locations = [
    ("LocNilField", "value := p.value", ".value", -10),
    ("LocNilChain", "NEW(p); value := p.next.value", ".value", -10),
    ("LocNilExplicit", "record := p^", "^", -10),
    ("LocNilLength", "value := LEN(dynamic^)", "^", -10),
    ("LocNilMethod", "p.Empty", ".Empty", -10),
    ("LocNilProcedure", "action()", "action()", -10),
    ("LocBounds", "value := 2; value := storage[value]", "value]", -2),
    ("LocNegative", "value := -1; value := storage[value]", "value]", -2),
    ("LocDynamic", "NEW(dynamic, 2); value := dynamic[2]", "2]", -2),
    ("LocMatrix", "value := 3; value := grid[0, value]", "value]", -2),
    ("LocIndexCall", "value := storage[BadIndex()]", "BadIndex()", -2),
    ("LocRepeated", "value := 1; storage[value] := 1;\nvalue := 2; value := storage[value]", "value]", -2),
]
for name, body, marker, code in locations:
    path = module(name, body)
    csource = translate(path)
    result = run([compile(csource, compilers[0])])
    assert result.returncode == code % 256, result
    check_location(result, path, marker)
    if name == "LocIndexCall":
        assert result.stdout.count("index evaluated") == 1, result

path = module("LocArrayCopy", "NEW(dynamic, 3); CopyTooMuch(dynamic^)")
procedure = """PROCEDURE CopyTooMuch(values: ARRAY OF LONGINT);
BEGIN storage := values END CopyTooMuch;
"""
path.write_text(path.read_text().replace("PROCEDURE Finish", procedure + "PROCEDURE Finish"))
csource = translate(path)
result = run([compile(csource, compilers[0])])
assert result.returncode == (-2) % 256, result
check_location(result, path, "storage := values")

for name, ending in (("LocCRLF", "\r\n"), ("LocCR", "\r"), ("LocLF", "\n")):
    path = module(name, "value := 2;\nvalue := storage[\n  (* index position *) value\n]")
    text = path.read_text().replace("BEGIN\nNEW(sentinel)", "(* source padding *)\n" * 300 + "BEGIN\nNEW(sentinel)")
    path.write_bytes(text.replace("\n", ending).encode())
    csource = translate(path)
    result = run([compile(csource, compilers[0])])
    assert result.returncode == (-2) % 256, result
    check_location(result, path, "value" + ending + "]")

callee = work / "LocationCallee.Mod"
callee.write_text("""MODULE LocationCallee;
IMPORT Out;
PROCEDURE Fail*;
VAR values: ARRAY 2 OF LONGINT; index: LONGINT;
BEGIN
  index := 2;
  Out.Int(values[index], 0)
END Fail;
END LocationCallee.
""")
result = run([voc, "-O" + args.model, "-sSF", callee])
assert result.returncode == 0, result
caller = work / "LocationCaller.Mod"
caller.write_text("MODULE LocationCaller; IMPORT LocationCallee; BEGIN LocationCallee.Fail END LocationCaller.\n")
csource = translate(caller)
result = run([compile(csource, compilers[0], extra_sources=[work / "LocationCallee.c"])])
assert result.returncode == (-2) % 256, result
check_location(result, callee, "index]")
original = module("LocationFilename", "value := p.value")
directory = work / 'source files'
directory.mkdir(exist_ok=True)
path = directory / 'actual "quoted"\\source.mod'
path.write_bytes(original.read_bytes())
result = run([voc, "-O" + args.model, "-sSFm", path])
assert result.returncode == 0, result
result = run([compile(work / 'LocationFilename.c', compilers[0])])
assert result.returncode == (-10) % 256, result
check_location(result, path, ".value", module_name="LocationFilename")
print("Exact source filenames, modules, lines, columns and offsets passed, including imports and line endings", flush=True)

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
        assert "__NIL(" not in csource.read_text() and "__NIL_AT(" not in csource.read_text(), csource
    for cc in compilers:
        result = run([compile(csource, cc)])
        assert result.returncode == 128 + signal.SIGSEGV, (name, cc, result)
        assert result.stderr == "Fatal error: invalid memory access (SIGSEGV).\n", result
        assert "Halt(-10)" not in result.stdout + result.stderr, result
        assert "finalizer ran" not in result.stdout, result
        assert "unexpected continuation" not in result.stdout, result
print("SIGSEGV faults reported separately without running finalizers", flush=True)

subprocess.run([sys.executable, str(source / "test-diagnostics.py"), "--voc", voc,
                "--vocroot", str(image), "--model", args.model, "--work", str(work / "diagnostics")],
               cwd=work, env=env, check=True, timeout=60)
