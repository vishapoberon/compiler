#!/usr/bin/env python3
"""Compile and run against a staged VOC installation and explicit library overrides."""

import argparse
import os
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--voc", type=Path, required=True)
parser.add_argument("--work", type=Path, required=True)
args = parser.parse_args()
voc = args.voc.resolve()
image = voc.parent.parent
work = args.work.resolve()
work.mkdir(parents=True, exist_ok=True)
alternate = work / "alternate libraries"
alternate.mkdir(exist_ok=True)
for library in (image / "lib").iterdir():
    link = alternate / library.name
    if not link.exists():
        link.symlink_to(library)

(work / "StageProbe.Mod").write_text('''MODULE StageProbe;
IMPORT Out;
BEGIN Out.String("Staged library check passed."); Out.Ln
END StageProbe.
''')

base = dict(os.environ)
for name in ("VOCROOT", "VOCLIBDIR", "OBERON", "MODULES", "CFLAGS", "LDFLAGS", "LDLIBS"):
    base.pop(name, None)
for name in ("LD_LIBRARY_PATH", "DYLD_LIBRARY_PATH"):
    base[name] = str(image / "lib") + (os.pathsep + base[name] if base.get(name) else "")

for overrides, expected in (
    ({"VOCROOT": str(image)}, image / "lib"),
    ({"VOCROOT": str(image), "VOCLIBDIR": str(alternate)}, alternate),
    ({"VOCLIBDIR": str(alternate)}, alternate),
):
    env = dict(base, **overrides)
    result = subprocess.run([str(voc), "-FsfVm", "StageProbe.Mod"], cwd=work,
                            env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    assert result.returncode == 0, result.stdout
    assert '-L"' + str(expected) + '"' in result.stdout, result.stdout
    result = subprocess.run([str(work / "StageProbe")], cwd=work, env=env,
                            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    assert result.returncode == 0, result.stdout
    assert result.stdout.strip() == "Staged library check passed.", result.stdout

print("Staged installation and library overrides passed.")
