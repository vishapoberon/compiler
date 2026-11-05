#!/usr/bin/env python3
"""Compile known IEEE values and long literals through the Oberon front end."""

import argparse
from pathlib import Path
import struct
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--voc", type=Path, required=True)
parser.add_argument("--work", type=Path, required=True)
parser.add_argument("--model", choices=("2", "C"), required=True)
args = parser.parse_args()
voc = args.voc.resolve()
work = args.work.resolve()
work.mkdir(parents=True, exist_ok=True)
lines = ["MODULE TestNumericConstants;", "IMPORT SYSTEM, Out;", "VAR d: LONGREAL; r: REAL;", "BEGIN"]
seed = 1


def next_bits():
    global seed
    seed ^= seed << 13
    seed &= (1 << 64) - 1
    seed ^= seed >> 7
    seed ^= seed << 17
    seed &= (1 << 64) - 1
    return seed


for _ in range(512):
    bits = next_bits()
    if bits >> 52 & 2047 != 2047:
        value = struct.unpack(">d", bits.to_bytes(8, "big"))[0]
        literal = format(value, ".17e").replace("e", "D")
        lines.append(f"d := {literal}; ASSERT(SYSTEM.VAL(SYSTEM.INT64, d) = 0{bits:016X}H);")
    bits = next_bits() & 0xFFFFFFFF
    if bits >> 23 & 255 != 255:
        value = struct.unpack(">f", bits.to_bytes(4, "big"))[0]
        literal = format(value, ".9e").replace("e", "E")
        signed = bits if bits < 1 << 31 else bits - (1 << 32)
        lines.append(f"r := {literal}; ASSERT(SYSTEM.VAL(SYSTEM.INT32, r) = {signed});")

for literal, expected in (
    ("1" + "0" * 40000 + ".0D-40000", "1.0D0"),
    ("0." + "0" * 40000 + "1D40001", "1.0D0"),
    ("1.00000000000000011102230246251565404236316680908203125" + "0" * 40000 + "1D0",
     "1.0000000000000002D0"),
):
    lines.append(f"d := {literal}; ASSERT(d = {expected});")
lines += ['Out.String("compiler numeric constant vectors passed"); Out.Ln', "END TestNumericConstants."]
(work / "TestNumericConstants.Mod").write_text("\n".join(lines) + "\n")


def compile_module(name):
    result = subprocess.run([str(voc), "-Fsfm", "-O" + args.model, name + ".Mod"],
                            cwd=work, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (work / (name + ".log")).write_text(result.stdout)
    return result


result = compile_module("TestNumericConstants")
assert result.returncode == 0, result.stdout[-4096:]
subprocess.run([str(work / "TestNumericConstants")], cwd=work, check=True)

for literal in ("1.0D40000", "1.0D-40000", "1.0D9223372036854775808", "1" * 40000):
    (work / "BadNumericConstant.Mod").write_text(
        f"MODULE BadNumericConstant; CONST x = {literal}; END BadNumericConstant.\n")
    result = compile_module("BadNumericConstant")
    assert result.returncode != 0, "accepted out-of-range literal: " + literal[:80]

print("compiler numeric range rejection passed")
