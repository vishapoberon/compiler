#!/usr/bin/env python3
"""Opt-in build/staging regression for the base and extra-native binding profiles."""

import argparse
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[3]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--image", type=Path, default=ROOT / "install")
parser.add_argument("--build", type=Path, required=True, help="fresh output directory")
parser.add_argument("--cc", default="cc")
args = parser.parse_args()
build = args.build.resolve()
image = args.image.resolve()
modules = build / "modules/2"
if modules.exists():
    parser.error("use a fresh --build directory; existing builds are never removed")
build.mkdir(parents=True, exist_ok=True)
env = dict(os.environ)
for name in ("VOC", "VOCROOT", "VOCLIBDIR", "OBERON", "MODULES", "VOC_MODULE_PATH",
             "VOC_SYM_PATH", "VOC_RUNPATH", "MAKEFLAGS", "MFLAGS"):
    env.pop(name, None)
common = ["make", "-j1", "-f", "src/tools/hresh/Makefile",
          "VOCROOT=" + str(image), "VOCLIBDIR=" + str(image / "lib"),
          "VOC=" + str(image / "bin/voc"), "BUILD=" + str(build), "CC=" + args.cc,
          "INSTALL_ROOT=/usr/share/voc", "INSTALL_LIBDIR=/usr/lib"]


def make(label, *targets):
    with (build / (label + ".log")).open("w") as log:
        subprocess.run(common + list(targets), cwd=ROOT, env=env,
                       stdout=log, stderr=subprocess.STDOUT, check=True)


def names(filename):
    return set((modules / filename).read_text().splitlines())


def library_times():
    return {p.name: p.stat().st_mtime_ns for p in modules.glob("*.so")}


bindings = {"oocX11", "oocXutil", "oocXYplane", "Cairo", "RaylibNative", "Raylib"}
# The base target must not invoke pkg-config, even when no binding is disabled.
make("base", "libraries", "PKG_CONFIG=/bin/false")
base = names("libraries.list")
assert len(base) > 100 and not base & bindings, base & bindings
for name in bindings:
    assert not (modules / ("libvoc-" + name + "-O2.so")).exists(), name
times = library_times()
make("bindings", "bindings")
assert names("bindings.list") == bindings
assert names("libraries.list") == base
for name, time in times.items():
    assert (modules / name).stat().st_mtime_ns == time, name
make("base-again", "libraries", "PKG_CONFIG=/bin/false")
for name, time in times.items():
    assert (modules / name).stat().st_mtime_ns == time, name
make("tests", "test-bindings")

for target, with_bindings in (("install-modular", False),
                              ("install-modular-bindings", True)):
    stage = build / target
    make(target, target, "DESTDIR=" + str(stage))
    libraries = stage / "usr/lib/voc/modular/2"
    for name in bindings:
        assert (libraries / ("libvoc-" + name + "-O2.so")).exists() == with_bindings
    assert (stage / "usr/share/voc/modular/2/bindings.list").exists() == with_bindings

# An empty selection must produce an empty manifest, not an empty module name.
make("no-bindings", "bindings", "WITH_X11=0", "WITH_CAIRO=0", "WITH_RAYLIB=0")
assert not names("bindings.list")
assert names("libraries.list") == base
print("base/binding separation, headless tests and staged manifests passed")
