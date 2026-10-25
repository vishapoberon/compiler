#!/usr/bin/env python3
"""Exercise standalone and loadable none editing through a pseudo-terminal."""

import argparse
import errno
import fcntl
import os
from pathlib import Path
import pty
import select
import struct
import subprocess
import termios
import time


def edit(command, work, actions):
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))
    original = termios.tcgetattr(slave)
    output = bytearray()
    process = subprocess.Popen(command, cwd=work, stdin=slave, stdout=slave, stderr=slave)
    deadline = time.monotonic() + 15

    def receive(marker):
        start = len(output)
        while marker not in output[start:]:
            if time.monotonic() >= deadline:
                raise AssertionError(f"timeout waiting for {marker!r}: {output[-1000:]!r}")
            if select.select([master], [], [], 0.1)[0]:
                try:
                    chunk = os.read(master, 65536)
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
                    chunk = b""
                output.extend(chunk)
            if process.poll() is not None and marker not in output[start:]:
                raise AssertionError(f"editor exited before {marker!r}: {output[-1000:]!r}")

    try:
        for marker, keys in actions:
            receive(marker)
            os.write(master, keys)
        while process.poll() is None:
            if time.monotonic() >= deadline:
                raise AssertionError(f"editor did not exit: {output[-1000:]!r}")
            if select.select([master], [], [], 0.1)[0]:
                output.extend(os.read(master, 65536))
        assert process.returncode == 0, (process.returncode, output[-1000:])
        assert termios.tcgetattr(slave) == original, "terminal settings were not restored"
    finally:
        if process.poll() is None:
            process.kill()
        process.wait()
        os.close(master)
        os.close(slave)


def check_standalone(executable, work):
    for args, status, message in [
        ([], 2, b"usage: none file"),
        (["--help"], 0, b"usage: none file"),
        (["one", "two"], 2, b"usage: none file"),
        ([""], 2, b"file name must contain"),
        (["a" * 256], 2, b"file name must contain"),
        (["a" * 255], 2, b"an interactive terminal is required"),
        (["plain.txt"], 2, b"an interactive terminal is required"),
    ]:
        result = subprocess.run([executable, *args], cwd=work, input=b"", capture_output=True, timeout=10)
        assert result.returncode == status, (args, result)
        assert message in result.stdout, (args, result)

    plain = work / "plain file.txt"
    plain.write_bytes(b"first\nsecond\r\n")
    edit([executable, plain.name], work, [
        (b"^X", b"prefix \x0f"),
        (b"File Name to Write", b"\r"),
        (b"Wrote ", b"\x18"),
    ])
    assert plain.read_bytes() == b"prefix first\nsecond\r\n"

    rich = work / "rich file.Text"
    rich.unlink(missing_ok=True)
    edit([executable, rich.name], work, [
        (b"^X", b"rich text\x0f"),
        (b"File Name to Write", b"\x14\r"),
        (b"Wrote ", b"\x18"),
    ])
    stored = rich.read_bytes()
    assert stored.startswith(b"\xf0\x01"), stored[:20]
    edit([executable, rich.name], work, [(b"^X", b"\x18")])
    assert rich.read_bytes() == stored


def check_loadable(hresh, modules, work):
    result = subprocess.run(
        [hresh, f"-P{modules}", "system.ShowCommands", "none"],
        cwd=work, input=b"", capture_output=True, timeout=10,
    )
    assert result.returncode == 0, result
    assert b"Open" in result.stdout and b"Fit" not in result.stdout, result
    assert b"interactive terminal" not in result.stdout, "loading none started the editor"

    plain = work / "hosted file.txt"
    plain.write_bytes(b"original\n")
    edit([hresh, f"-P{modules}", "none.Open", f'"{plain.name}"'], work, [
        (b"^X", b"hosted \x0f"),
        (b"File Name to Write", b"\r"),
        (b"Wrote ", b"\x18"),
    ])
    assert plain.read_bytes() == b"hosted original\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    parser.add_argument("--work", type=Path, required=True)
    parser.add_argument("--hresh", type=Path)
    parser.add_argument("--modules", type=Path)
    args = parser.parse_args()
    work = args.work.resolve()
    work.mkdir(parents=True, exist_ok=True)
    check_standalone(str(args.executable.resolve()), work)
    if args.hresh:
        assert args.modules, "--hresh requires --modules"
        check_loadable(str(args.hresh.resolve()), args.modules.resolve(), work)
    print("none editor tests passed")


if __name__ == "__main__":
    main()
