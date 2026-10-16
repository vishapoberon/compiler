#!/usr/bin/env python3
"""Opt-in build checks; examples are not dependencies of the release build."""

import argparse
import hashlib
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[3]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--build", type=Path, default=ROOT / "build/test/examples")
parser.add_argument("--image", type=Path, default=ROOT / "install")
parser.add_argument("--x11", action="store_true", help="also compile X11 demos/games")
parser.add_argument("--native", action="store_true", help="also test the modular examples")
args = parser.parse_args()
build = args.build.resolve()
image = args.image.resolve()
build.mkdir(parents=True, exist_ok=True)
env = dict(os.environ)
# Do not let an installed compiler/library from the caller mask a checkout error.
for name in ("VOC", "VOCROOT", "VOCLIBDIR", "OBERON", "VOC_MODULE_PATH", "MAKEFLAGS", "MFLAGS"):
    env.pop(name, None)

examples = {
    "language/events": ["clb"],
    "libraries/files": ["testFiles"],
    "libraries/md5": ["md5test"],
    "libraries/ooc": ["testArgs", "testReader"],
    "libraries/texts": ["testTexts", "argTexts"],
    "libraries/vt100": ["crttest"],
    "libraries/sts-q": ["Keys"],
    "libraries/sts-q/editor": ["Viewer.o"],
    "utilities/sound": ["beep"],
    "servers/sockets": ["s"],
}
if args.x11:
    examples.update({
        "gui/x11/simple": ["test"], "gui/x11/ifs": ["IFStest"],
        "games/mines": ["Minesweeper"], "games/pacman": ["PacMan"],
        "games/tetris": ["Tetris"], "games/tron": ["Tron"], "games/vier": ["Vier"],
    })

for example, outputs in examples.items():
    output = build / example
    with (build / (example.replace("/", "-") + ".log")).open("w") as log:
        subprocess.run([
            "make", "-C", str(ROOT / "src/examples" / example),
            "BUILD=" + str(output), "VOCROOT=" + str(image),
        ], env=env, stdout=log, stderr=subprocess.STDOUT, check=True)
    for name in outputs:
        assert (output / name).is_file(), (example, name)
    print(example, "built", flush=True)

# Running only noninteractive examples; never start a server, GUI, game or audio tool.
result = subprocess.run([str(build / "libraries/ooc/testArgs"), "hello", "42"],
                        env=env, capture_output=True, text=True, check=True)
assert "arg 0: hello" in result.stdout and "arg 1: 42" in result.stdout, result.stdout

for example, expected in (
    ("libraries/files", "MODULE testFiles;"),
    ("libraries/md5", hashlib.md5((ROOT / "src/examples/libraries/md5/hello.txt").read_bytes()).hexdigest()),
):
    result = subprocess.run([
        "make", "-C", str(ROOT / "src/examples" / example), "run",
        "BUILD=" + str(build / example), "VOCROOT=" + str(image),
    ], env=env, capture_output=True, text=True, check=True)
    assert expected in result.stdout, result.stdout

if args.native:
    for example in ("module-tutorial", "shared-libraries"):
        with (build / (example + ".log")).open("w") as log:
            subprocess.run([
                "make", "-C", str(ROOT / "src/examples" / example), "test",
                "BUILD=" + str(build / example), "VOCROOT=" + str(image),
                "HRESH_BUILD=" + str(build / "hresh"),
            ], env=env, stdout=log, stderr=subprocess.STDOUT, check=True)
        print(example, "passed", flush=True)

print("source-tree example build checks passed")
