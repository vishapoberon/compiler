"""Check editor-readable compiler diagnostics and source excerpts."""
import argparse
import os
from pathlib import Path
import re
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--voc", required=True)
parser.add_argument("--vocroot", required=True)
parser.add_argument("--model", choices=("2", "C"), default="2")
parser.add_argument("--work", required=True, type=Path)
args = parser.parse_args()
voc = str(Path(args.voc).resolve())
image = Path(args.vocroot).resolve()
work = args.work.resolve()
work.mkdir(parents=True, exist_ok=True)
env = dict(os.environ, VOCROOT=str(image), VOCLIBDIR=str(image / "lib"),
           OBERON=str(image / args.model / "sym"))


def compile_source(path, success=False, options="-sSFf", relative=False):
    name = path.name if relative else str(path)
    result = subprocess.run([voc, "-O" + args.model, options, name], cwd=work,
                            env=env, text=True, capture_output=True, timeout=30)
    output = result.stdout + result.stderr
    assert (result.returncode == 0) == success, (path, result)
    pattern = (rf"^{re.escape(name)}:(\d+):(\d+): (error|warning): (.*?) "
               r"\[(err|warning) (\d+) at pos (\d+)\]$")
    matches = list(re.finditer(pattern, output, re.MULTILINE))
    assert matches, output
    data = path.read_bytes()
    lines = data.replace(b"\r\n", b"\n").replace(b"\r", b"\n").split(b"\n")
    rows = output.splitlines()
    for match in matches:
        line, column, pos = int(match[1]), int(match[2]), int(match[7])
        assert 0 <= pos <= len(data), (path, output)
        prefix = data[:pos]
        expected_line = prefix.replace(b"\r\n", b"\n").replace(b"\r", b"\n").count(b"\n") + 1
        expected_column = pos - max(prefix.rfind(b"\r"), prefix.rfind(b"\n"))
        assert (line, column) == (expected_line, expected_column), output
        assert (match[3] == "error") == (match[5] == "err"), output
        row = rows.index(match[0])
        assert rows[row + 1] == f"{line:4d}: " + lines[line - 1].decode(), output
        padding = " " * (max(4, len(str(line))) + 2)
        padding += "".join("\t" if ch == 9 else " " for ch in lines[line - 1][:column - 1])
        assert rows[row + 2] == padding + "^", output
    return matches, output


for ending in ("\n", "\r\n", "\r"):
    path = work / 'syntax "quoted" source.mod'
    text = "MODULE DiagnosticSyntax\n\tVAR value: INTEGER;\nEND DiagnosticSyntax.\n"
    path.write_bytes(text.replace("\n", ending).encode())
    matches, output = compile_source(path)
    assert (matches[0][1], matches[0][2], matches[0][6]) == ("2", "2", "39"), output

path = work / "relative source.mod"
path.write_text("MODULE DiagnosticRelative\nVAR value: INTEGER; END DiagnosticRelative.\n")
compile_source(path, relative=True)

for name, text, code, success in (
        ("DiagnosticEOF", "MODULE DiagnosticEOF;\nBEGIN\n", "41", False),
        ("DiagnosticString", 'MODULE DiagnosticString;\nCONST text = "unfinished\nEND DiagnosticString.\n', "3", False),
        ("DiagnosticType", "MODULE DiagnosticType; VAR value: INTEGER; BEGIN value := TRUE END DiagnosticType.\n", "113", False),
        ("DiagnosticWarning", "MODULE DiagnosticWarning; VAR value: INTEGER;\nBEGIN value := 0; CASE value OF 0: value := 1 END END DiagnosticWarning.\n", "307", True)):
    path = work / (name + ".Mod")
    path.write_text(text)
    matches, output = compile_source(path, success=success)
    assert any(match[6] == code for match in matches), output

path = work / "DiagnosticSymbols.Mod"
path.write_text("MODULE DiagnosticSymbols; VAR value*: INTEGER; END DiagnosticSymbols.\n")
result = subprocess.run([voc, "-O" + args.model, "-sSFf", str(path)], cwd=work,
                        env=env, text=True, capture_output=True, timeout=30)
assert result.returncode == 0, result
path.write_text("MODULE DiagnosticSymbols; VAR value*: REAL; END DiagnosticSymbols.\n")
matches, output = compile_source(path, options="-Sf")
assert any(match[6] in ("251", "252") for match in matches), output

missing = work / "missing source.mod"
result = subprocess.run([voc, "-O" + args.model, "-sSf", str(missing)], cwd=work,
                        env=env, text=True, capture_output=True, timeout=30)
assert result.returncode != 0 and f"{missing}: error:" in result.stdout, result
print("Compiler errors, warnings, symbol diagnostics, filenames, line endings and carets passed", flush=True)
