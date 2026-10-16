#!/usr/bin/env python3
"""Checking the Polpo command ports against Python's gzip and zipfile readers."""

import gzip
import os
from pathlib import Path
import random
import subprocess
import sys
import tempfile
import zipfile


host, modules, build = map(Path, sys.argv[1:])
env = dict(os.environ, OBERON=".", TZ="UTC0")


def run(directory, command):
    result = subprocess.run(
        [str(host), "-P" + str(modules), *command.split(" ", 1)],
        cwd=directory, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, timeout=20,
    )
    assert result.returncode == 0, (command, result.stdout)
    return result.stdout


with tempfile.TemporaryDirectory(prefix="archives-", dir=build) as temporary:
    root = Path(temporary)
    rng = random.Random(12345)
    for size in (0, 1, 8192, 16384, 65536, 190000):
        data = rng.randbytes(size)
        (root / "input").write_bytes(data)
        output = run(root, "gzip.Compress input")
        assert "compression failed" not in output, output
        compressed = (root / "input.gz").read_bytes()
        assert gzip.decompress(compressed) == data
        run(root, "gzip.Decompress input.gz decoded")
        assert (root / "decoded").read_bytes() == data
        (root / "python.gz").write_bytes(gzip.compress(data, mtime=0))
        run(root, "gzip.Decompress python.gz python-output")
        assert (root / "python-output").read_bytes() == data

    data = b"repeated text\n" * 50000
    (root / "space name").write_bytes(data)
    run(root, 'gzip.Compress "space name" "quoted output.gz"')
    assert gzip.decompress((root / "quoted output.gz").read_bytes()) == data
    run(root, 'gzip.Decompress "quoted output.gz" "quoted output"')
    assert (root / "quoted output").read_bytes() == data
    os.link(root / "space name", root / "same-input")
    output = run(root, 'gzip.Compress "space name" same-input')
    assert "same file" in output and (root / "space name").read_bytes() == data
    assert "usage:" in run(root, "gzip.Compress input out extra")
    assert "usage:" in run(root, 'gzip.Compress "unclosed')
    assert "usage:" in run(root, "gzip.Compress " + "x" * 256)
    assert "output name too long" in run(root, "gzip.Compress " + "x" * 253)

    valid = gzip.compress(data, mtime=0)
    corruptions = [valid[:-8], valid[:18], b"not gzip", valid + valid]
    for offset in (-8, -4):
        damaged = bytearray(valid)
        damaged[offset] ^= 1
        corruptions.append(damaged)
    for damaged in corruptions:
        (root / "bad.gz").write_bytes(damaged)
        (root / "protected").write_bytes(b"unchanged")
        output = run(root, "gzip.Decompress bad.gz protected")
        assert (root / "protected").read_bytes() == b"unchanged", output

    (root / "nested").mkdir()
    (root / "nested/data").write_bytes(data)
    (root / "empty").write_bytes(b"")
    # Stay within both date APIs' shared century: their differing treatment
    # of two-digit years is separate from the native time_t-width regression.
    for name in ("space name", "nested/data", "empty"):
        os.utime(root / name, (825597296, 825597296))  # 1996-02-29 12:34:56 UTC
    run(root, 'zip.Add made.zip "space name" nested/data empty')
    with zipfile.ZipFile(root / "made.zip") as arc:
        assert arc.testzip() is None
        assert all(entry.date_time == (1996, 2, 29, 12, 34, 56) for entry in arc.infolist())
        assert arc.read("space name") == data
        assert arc.read("nested/data") == data
        assert arc.read("empty") == b""
    assert "3 entries" in run(root, "zip.Directory made.zip")
    run(root, "zip.Delete made.zip empty")
    with zipfile.ZipFile(root / "made.zip") as arc:
        assert arc.namelist() == ["space name", "nested/data"]
        assert arc.testzip() is None
    run(root, 'zip.Delete made.zip "space name" nested/data')
    with zipfile.ZipFile(root / "made.zip") as arc:
        assert arc.namelist() == []

    for compression in (zipfile.ZIP_STORED, zipfile.ZIP_DEFLATED):
        with zipfile.ZipFile(root / "python.zip", "w", compression=compression) as arc:
            arc.comment = b"archive comment"
            arc.writestr("newdir/", b"")
            arc.writestr("newdir/bytes", data)
            arc.writestr("selected", b"select me")
        run(root, "zip.Extract python.zip selected")
        assert (root / "selected").read_bytes() == b"select me"
        run(root, "zip.Extract python.zip")
        assert (root / "newdir/bytes").read_bytes() == data

    with zipfile.ZipFile(root / "unsafe.zip", "w") as arc:
        for name in ("../outside", "/absolute", "a/../../outside", "C:/outside", "a\\outside"):
            arc.writestr(name, b"unsafe")
        arc.writestr("link/escaped", b"unsafe")
        arc.writestr("final-link", b"unsafe")
        arc.writestr("safe-output", b"safe")
    (root / "outside-dir").mkdir()
    (root / "target").write_bytes(b"unchanged")
    (root / "link").symlink_to("outside-dir", target_is_directory=True)
    (root / "final-link").symlink_to("target")
    output = run(root, "zip.Extract unsafe.zip")
    assert "unsafe or invalid name" in output, output
    assert not (root / "outside-dir/escaped").exists()
    assert (root / "target").read_bytes() == b"unchanged"
    assert (root / "safe-output").read_bytes() == b"safe"

    with zipfile.ZipFile(root / "damaged.zip", "w") as arc:
        arc.writestr("protected", b"original payload")
    damaged = bytearray((root / "damaged.zip").read_bytes())
    damaged[30 + len("protected")] ^= 1
    (root / "damaged.zip").write_bytes(damaged)
    (root / "protected").write_bytes(b"unchanged")
    output = run(root, "zip.Extract damaged.zip")
    assert "damaged" in output and (root / "protected").read_bytes() == b"unchanged"

    with zipfile.ZipFile(root / "deflated.zip", "w", compression=zipfile.ZIP_DEFLATED) as arc:
        arc.writestr("protected", data)
    damaged = bytearray((root / "deflated.zip").read_bytes())
    damaged[30 + len("protected")] |= 6  # reserved deflate block type
    (root / "deflated.zip").write_bytes(damaged)
    output = run(root, "zip.Extract deflated.zip")
    assert "damaged" in output and (root / "protected").read_bytes() == b"unchanged"

    with zipfile.ZipFile(root / "flagged.zip", "w") as arc:
        arc.writestr("protected", b"payload")
    flagged = bytearray((root / "flagged.zip").read_bytes())
    central = flagged.index(b"PK\x01\x02")
    flagged[6] |= 1
    flagged[central + 8] |= 1  # encryption flag, not the version field
    (root / "flagged.zip").write_bytes(flagged)
    output = run(root, "zip.Extract flagged.zip")
    assert "unsupported format or encrypted" in output, output
    assert (root / "protected").read_bytes() == b"unchanged"
    flagged[central + 20:central + 24] = b"\xff" * 4
    (root / "flagged.zip").write_bytes(flagged)
    assert "not a zip archive" in run(root, "zip.Directory flagged.zip")

    for length in (255, 256):
        with zipfile.ZipFile(root / "long.zip", "w") as arc:
            arc.writestr("x" * length, b"data")
        output = run(root, "zip.Directory long.zip")
        assert ("1 entries" in output) == (length == 255), output
    (root / "broken.zip").write_bytes(b"invalid")
    assert "not a zip archive" in run(root, "zip.Directory broken.zip")
    assert "not a zip archive" in run(root, "zip.Add broken.zip input")
    assert (root / "broken.zip").read_bytes() == b"invalid"
    assert "unsafe or invalid name" in run(root, "zip.Add made.zip made.zip")
    assert "usage:" in run(root, "zip.Directory made.zip extra")
    assert "usage:" in run(root, "zip.Add made.zip " + " ".join(["input"] * 129))

print("gzip/zip command interoperability and rejection tests passed")
