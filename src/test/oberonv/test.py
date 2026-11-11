import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument("--voc", required=True)
parser.add_argument("--vocroot", required=True)
parser.add_argument("--work", required=True)
parser.add_argument("--model", choices=("2", "C"), default="2")
args = parser.parse_args()
voc = str(Path(args.voc).resolve())
image = Path(args.vocroot).resolve()
work = Path(args.work).resolve()
work.mkdir(parents=True, exist_ok=True)
sources = Path(__file__).resolve().parent
headers = image / args.model / "include"
library = image / "lib" / ("libvoc-O" + args.model + ".a")
env = dict(os.environ, VOCROOT=str(image), VOCLIBDIR=str(image / "lib"),
           OBERON=str(image / args.model / "sym"))


def run(command, success=True):
    if command[0] == voc:
        command = [voc, "-O" + args.model, *command[1:]]
    result = subprocess.run(list(map(str, command)), cwd=work, env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)
    assert (result.returncode == 0) == success, (command, result.stdout)
    return result.stdout


def source(name, declarations, body):
    path = work / (name + ".Mod")
    path.write_text("MODULE " + name + ";\n" + declarations + "\nBEGIN\n" + body +
                    "\nEND " + name + ".\n")
    return path


run([voc, "-sSjm", sources / "TestAll.Mod"])
generated = (work / "TestAll.c").read_text()
assert "#pragma omp" not in generated
assert "__all" in generated and "__X(" in generated

compilers = [cc for cc in ("gcc", "clang", "tcc") if shutil.which(cc)]
assert compilers, "no C compiler found"
for cc in compilers:
    executable = work / ("TestAll-" + cc)
    run([cc, "-O2", "-fno-strict-aliasing", "-DVOC_MAIN_PROGRAM=1",
         "-I" + str(headers), work / "TestAll.c",
         library, *(["-ldl"] if sys.platform.startswith("linux") else []),
         "-lm", "-o", executable])
    assert "ALL tests passed" in run([executable])
    print(cc + ": sequential ALL passed")

declarations = "VAR a, b: ARRAY 16 OF INTEGER; i, s, n: INTEGER;"
invalid = [
    ("RealBound", "ALL r = 0.0 .. 3 DO a[r] := r END", 164),
    ("BooleanBound", "ALL r = FALSE .. TRUE DO a[r] := r END", 164),
    ("TypeBound", "ALL r = INTEGER .. 3 DO a[r] := r END", 164),
    ("CharacterBound", 'ALL r = "A" .. "Z" DO a[r] := 0 END', 164),
    ("ReadOnly", "ALL r = 0 .. 3 DO r := 1 END", 76),
    ("Escaping", "ALL r = 0 .. 3 DO a[r] := r END; s := r", 0),
    ("Scalar", "ALL r = 0 .. 3 DO s := s+r END", 163),
    ("SharedElement", "ALL r = 0 .. 3 DO a[0] := r END", 163),
    ("ForwardDependence", "ALL r = 1 .. 3 DO a[r] := a[r-1] END", 166),
    ("BackwardDependence", "ALL r = 0 .. 3 DO a[r] := a[r+1] END", 166),
    ("CrossStatement", "ALL r = 0 .. 3 DO a[r] := b[r]; b[r+1] := a[r] END", 166),
    ("DynamicDependence", "ALL r = 1 .. n DO a[r] := a[r-1] END", 166),
    ("OverlappingWrites", "ALL r = 0 .. 3 DO a[r] := 1; a[r+1] := 2 END", 166),
    ("BroadcastDependence", "ALL r = 0 .. 3 DO a[r] := a[0] END", 166),
    ("WrongType", "ALL r = 0 .. 3 DO a[r] := TRUE END", 113),
    ("Procedure", "ALL r = 0 .. 3 DO INC(a[r]) END", 161),
    ("ControlFlow", "ALL r = 0 .. 3 DO IF r = 0 THEN a[r] := 1 END END", 161),
    ("Nested", "ALL r = 0 .. 3 DO ALL t = 0 .. 3 DO a[r] := t END END", 161),
    ("Multiple", "ALL r, t = 0 .. 3 DO a[r] := t END", 160),
    ("MultipleRanges", "ALL r = 0 .. 3, t = 1 .. 4 DO a[r] := t END", 160),
    ("Private", "ALL r = 0 .. 3 WITH t: INTEGER DO a[r] := t END", 165),
    ("MissingRange", "ALL r = 0 DO a[r] := r END", 21),
    ("TrailingSemicolon", "ALL r = 0 .. 3 DO a[r] := r; END", 161),
    ("MissingSeparator", "ALL r = 0 .. 3 DO a[r] := r END ALL r = 0 .. 3 DO b[r] := r END", 39),
]
for name, body, error in invalid:
    path = source("Bad" + name, declarations, body)
    output = run([voc, "-sSjm", path], success=False)
    assert "err " + str(error) + " " in output, (name, output)

path = source("BadCall", declarations +
              "\nPROCEDURE F(x: INTEGER): INTEGER; BEGIN RETURN x END F;",
              "ALL r = 0 .. 3 DO a[r] := F(r) END")
assert "err 162 " in run([voc, "-sSjm", path], success=False)
path = source("Disjoint", declarations, "ALL r = 0 .. 3 DO a[r] := a[r+8] END")
run([voc, "-sSjm", path])

compat = source("Compatibility", "VAR ALL: INTEGER;", "ALL := 4; ASSERT(ALL = 4)")
run([voc, "-sSm", compat])
run([voc, "-sSmjj", compat])
run([voc, "-sSm", compat, "-j"], success=False)
run([voc, "-sSmj", compat, "-j"])
all_source = source("PerFile", declarations, "ALL r = 0 .. 3 DO a[r] := r END")
run([voc, "-sSm", all_source, "-j", compat])
run([voc, "-sSmj", all_source, compat, "-j"])
for flags, message in (("P", "require -j"), ("G", "require -j"),
                       ("jPG", "mutually exclusive"), ("jP", "not implemented"),
                       ("jG", "not implemented")):
    assert message in run([voc, "-sSm" + flags, compat], success=False)
run([voc, "-sSmPPGGjj", compat])
ordinary_for = source("OrdinaryFor", declarations, "FOR i := 0 TO 3 DO a[i] := i END")
run([voc, "-sSm", ordinary_for])
ordinary_c = (work / "OrdinaryFor.c").read_text().splitlines()[1:]
run([voc, "-sSmj", ordinary_for])
assert ordinary_c == (work / "OrdinaryFor.c").read_text().splitlines()[1:]

for name, bounds in (("Below", "-1 .. 0"), ("Above", "15 .. 16")):
    path = source("Bounds" + name, declarations, "ALL r = " + bounds + " DO a[r] := r END")
    run([voc, "-sSjm", path])
    for cc in compilers:
        executable = work / ("Bounds" + name + "-" + cc)
        run([cc, "-DVOC_MAIN_PROGRAM=1", "-I" + str(headers),
             work / ("Bounds" + name + ".c"), library,
             *(["-ldl"] if sys.platform.startswith("linux") else []), "-lm", "-o", executable])
        assert "Halt(-2)" in run([executable], success=False)

print(str(len(invalid) + 1) + " invalid ALL cases rejected")
print("scope, bounds checks, option toggling and Oberon-2 compatibility passed")
