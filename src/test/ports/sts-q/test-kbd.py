#!/usr/bin/env python3
"""Kbd regressions, without any private example modules."""
import fcntl
import os
from pathlib import Path
import select
import subprocess
import sys
import time

BUILD = Path(sys.argv[1]).resolve()
MODEL = sys.argv[2]
SHIFT, CTRL, META, DRAG = (n << 24 for n in (1, 2, 8, 16))
FUN, MOUSE = 2 << 29, 3 << 29

# Check that library builds contain no example modules.
if len(sys.argv) > 3 and sys.argv[3] == 'bundled':
    programs = {'TestKbd', 'TestKbdLibrary'}
    assert {p.stem for p in BUILD.glob('*.sym')} <= programs, 'unexpected local support module'
    assert not list(BUILD.glob('Kbd.*')), 'bundled test must use the ordinary library image'
    assert {p.name for p in BUILD.glob('lib*')} <= {
        f'libvoc-{name}-O{MODEL}.so' for name in programs
    }, 'unexpected local support library'
else:
    assert {p.stem for p in BUILD.glob('*.sym')} == {'Kbd'}
    archive = BUILD / f'libssq-O{MODEL}.a'
    shared = sorted(p.name for p in BUILD.glob('libvoc-*.so'))
    assert archive.is_file() or shared, 'missing Kbd library output'
    if archive.is_file():
        members = subprocess.check_output(['ar', 't', str(archive)], text=True).splitlines()
        assert members == ['Kbd.o'], members
    if shared:
        assert shared == [f'libvoc-Kbd-O{MODEL}.so'], shared


def mouse(button, row, col, modifiers=0):
    return MOUSE + modifiers + button + (row << 8) + (col << 16)


def ready(process):
    data = b""
    deadline = time.monotonic() + 5
    while not data.endswith(b"ready\n"):
        remaining = deadline - time.monotonic()
        if remaining <= 0 or not select.select([process.stdout], [], [], remaining)[0]:
            raise AssertionError(("waiting for ready", data))
        chunk = os.read(process.stdout.fileno(), 4096)
        if not chunk:
            raise AssertionError(("early exit", process.poll(), data, process.stderr.read()))
        data += chunk
    return data


def keys(chunks, expected):
    readfd, writefd = os.pipe()
    flags = fcntl.fcntl(readfd, fcntl.F_GETFL) | os.O_NONBLOCK
    fcntl.fcntl(readfd, fcntl.F_SETFL, flags)
    process = subprocess.Popen(
        [str(BUILD / "TestKbd"), str(len(expected))],
        stdin=readfd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=BUILD,
    )
    try:
        ready(process)
        for chunk in chunks:
            if isinstance(chunk, float):
                time.sleep(chunk)
            else:
                os.write(writefd, chunk)
        os.close(writefd)
        writefd = None
        out, err = process.communicate(timeout=7)
        assert process.returncode == 0, (process.returncode, out, err)
        assert [int(line) for line in out.splitlines()] == expected, (chunks, out, expected)
        assert fcntl.fcntl(readfd, fcntl.F_GETFL) == flags, "Kbd changed caller-owned stdin flags"
    finally:
        if process.poll() is None:
            process.kill()
        process.wait()
        os.close(readfd)
        if writefd is not None:
            os.close(writefd)


keys([b"a\x01\x1bz\t\r\x7f"], [ord("a"), 1, META + ord("z"), 9, 13, 127])
keys([b"\x1b[1;7A"], [FUN + CTRL + META + 41])
keys([b"\x1b[A\x1b[Z\x1b[2;5~\x1b[3;8~"],
     [FUN + 41, FUN + SHIFT + 51, FUN + CTRL + 31, FUN + SHIFT + CTRL + META + 34])
keys([b"\x1b[<0;34;12M\x1b[<0;34;12m\x1b[<64;2;3M\x1b[<60;5;6M"],
     [mouse(101, 12, 34), mouse(117, 12, 34), mouse(104, 3, 2),
      mouse(101, 6, 5, SHIFT + CTRL + META + DRAG)])
sequence = b"\x1b[1;7A"
for split in range(1, len(sequence)):
    keys([sequence[:split], 0.01, sequence[split:]], [FUN + CTRL + META + 41])
sequence = b"\x1b[<16;34;12M"
for split in range(1, len(sequence)):
    keys([sequence[:split], 0.01, sequence[split:]], [mouse(101, 12, 34, CTRL)])
keys([b"a" * 1200], [ord("a")] * 1200)  # Full reads and buffer compaction.
keys([b"\x1b"], [27])
keys([b"\x1b\x1b"], [27, 27])
for invalid in (b"\x1b[999~", b"\x1b[<0;256;1M", b"\x1b[<0;0;1M",
                b"\x1b[<999999999999999999999;1;2M", b"\x1b[<3;1;2M"):
    keys([invalid + b"x"], [ord("x")])
keys([b"\x1b[1;", 0.15, b"x"], [ord("x")])
keys([b"\x1b[" + b"1" * 90 + b"x"], [ord("1")] * 29 + [ord("x")])
result = subprocess.run([str(BUILD / 'TestKbd'), '0'], cwd=BUILD,
                        stdin=subprocess.DEVNULL, capture_output=True, timeout=5)
assert result.returncode == 0, result
result = subprocess.run([str(BUILD / 'TestKbd'), '1'], cwd=BUILD,
                        stdin=subprocess.DEVNULL, capture_output=True, timeout=5,
                        preexec_fn=lambda: os.close(0))
assert result.returncode == 1 and b'stdin read failed' in result.stdout, result
print('standalone Kbd stream tests passed')
