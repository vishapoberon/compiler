"""Compile PICL fixtures and generate, build and run Coco/R parsers."""

import argparse
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile


def run(command, work, env, success=True):
    result = subprocess.run(
        [str(arg) for arg in command], cwd=work, env=env,
        text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30,
    )
    if (result.returncode == 0) != success:
        raise AssertionError(f"{command}: exit {result.returncode}\n{result.stdout}")
    return result.stdout


def compile_module(args, work, env, name, main=False):
    run([args.voc, f"-O{args.model}", "-sm" if main else "-Fs", name], work, env)


def picl(args, work, env):
    for name in ("Assignments", "WhileStatements"):
        shutil.copy2(args.source / "tests" / f"{name}.picl", work)
        output = run([args.build / "PICL", f"{name}.picl"], work, env)
        assert f"PIC compiling {name}" in output, output
        assert not re.search(r"\berr\s+\d+", output), output
        data = (work / f"{name}.bin").read_bytes()
        assert data and len(data) % 4 == 0, (name, len(data))
        words = struct.unpack(f"<{len(data) // 4}I", data)
        assert all(word < 0x4000 for word in words), words
        if name == "Assignments":
            assert words == (0x080C, 0x008D, 0x300A, 0x008D, 0x018D), words
        else:
            assert len(words) > 10, words
        print(f"PICL: {name}: {len(words)} instructions")


def frames(args, work):
    for frame in args.source.glob("*.FRM"):
        shutil.copy2(frame, work)


def coco_native(args, work, env):
    frames(args, work)
    shutil.copy2(args.source / "examples" / "EBNF.atg", work)
    output = run([args.build / "Coco", "EBNF.atg"], work, env)
    assert "EBNF" in output, output
    for name in ("EBNFS", "EBNFP"):
        assert (work / f"{name}.Mod").is_file(), output
        compile_module(args, work, env, f"{name}.Mod")
    (work / "GrammarCheck.Mod").write_text("""MODULE GrammarCheck;
IMPORT Modules, Texts, Out, S := EBNFS, P := EBNFP;
VAR name: ARRAY 256 OF CHAR; text: Texts.Text;
PROCEDURE Error(n: INTEGER; pos: LONGINT);
BEGIN INC(S.errors) END Error;
BEGIN
  Modules.GetArg(1, name); NEW(text); Texts.Open(text, name);
  S.Reset(text, 0, Error); P.Parse;
  Out.Int(S.errors, 0); Out.String(" errors"); Out.Ln;
  IF S.errors # 0 THEN HALT(1) END
END GrammarCheck.
""")
    compile_module(args, work, env, "GrammarCheck.Mod", main=True)
    (work / "valid.ebnf").write_text("Start = 'word' .\n")
    output = run([work / "GrammarCheck", "valid.ebnf"], work, env)
    assert "0 errors" in output, output
    (work / "invalid.ebnf").write_text("Start = 'word'\n")
    run([work / "GrammarCheck", "invalid.ebnf"], work, env, success=False)
    print("Coco/R native: generated EBNF scanner/parser accept and reject inputs")


def coco_aixp(args, work, env):
    frames(args, work)
    shutil.copy2(args.source / "tests" / "A.ATG", work)
    output = run([args.build / "Coco", "A.ATG"], work, env)
    for name in ("AS", "AP", "ACompile"):
        assert (work / f"{name}.Mod").is_file(), output
        compile_module(args, work, env, f"{name}.Mod", main=name == "ACompile")
    assert b"ZZZ()" in (work / "AP.Mod").read_bytes()
    shutil.copy2(args.source / "tests" / "1.A", work / "input.A")
    output = run([work / "ACompile", "input.A"], work, env)
    assert "0 errors" in output and "D 3 " in output, output
    assert "D 1 " not in output, output
    (work / "invalid.A").write_text("AAA Z\n")
    output = run([work / "ACompile", "invalid.A"], work, env)
    assert re.search(r"\b[1-9]\d* errors\b", output), output
    print("Coco/R aixp: generated scanner/parser/driver, resolver and invalid input")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("tool", choices=("picl", "coco-native", "coco-aixp"))
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--build", type=Path, required=True)
    parser.add_argument("--voc", type=Path, required=True)
    parser.add_argument("--model", choices=("2", "C"), required=True)
    args = parser.parse_args()
    args.source = args.source.resolve()
    args.build = args.build.resolve()
    args.voc = args.voc.resolve()
    with tempfile.TemporaryDirectory(prefix="test-", dir=args.build) as directory:
        work = Path(directory)
        env = dict(os.environ)
        env["OBERON"] = str(work) + ";" + env.get("OBERON", "")
        {"picl": picl, "coco-native": coco_native, "coco-aixp": coco_aixp}[args.tool](args, work, env)


if __name__ == "__main__":
    main()
