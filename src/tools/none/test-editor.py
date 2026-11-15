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


def comparable_settings(settings):
    # Canonical-mode restoration may change the kernel-managed PENDIN bit.
    # Preserve all other flags, speeds and control characters for comparison.
    result = list(settings)
    result[3] &= ~getattr(termios, "PENDIN", 0)
    return result


def check_settings_comparison():
    original = [0, 0, 0, termios.ICANON, termios.B9600, termios.B9600, [b"\x00"]]
    pending = list(original)
    pending[3] ^= getattr(termios, "PENDIN", 0)
    assert comparable_settings(pending) == comparable_settings(original)
    assert comparable_settings(original) == comparable_settings(pending)
    assert original[3] == termios.ICANON, "comparison modified the original settings"
    for field in range(6):
        changed = list(original)
        changed[field] ^= termios.ECHO if field == 3 else 1
        assert comparable_settings(changed) != comparable_settings(original), field
    changed = list(original)
    changed[6] = [b"\x01"]
    assert comparable_settings(changed) != comparable_settings(original)


def edit(command, work, actions, size=(24, 80), env=None):
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", *size, 0, 0))
    original = termios.tcgetattr(slave)
    output = bytearray()
    process = subprocess.Popen(command, cwd=work, stdin=slave, stdout=slave, stderr=slave,
                               env={**os.environ, **env} if env is not None else None)
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
        restored = termios.tcgetattr(slave)
        assert comparable_settings(restored) == comparable_settings(original), (
            "terminal settings were not restored", "actual", restored, "expected", original)
    finally:
        if process.poll() is None:
            process.kill()
        process.wait()
        os.close(master)
        os.close(slave)
    return bytes(output)


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


def check_completion(command, work):
    prefix = (
        b"MODULE Editing; IMPORT (* outer (* nested *) *) F := CompletionFixture; "
        b"CONST LocalConstant = 7; TYPE LocalType = RECORD field: INTEGER END; "
        b"VAR localVariable: INTEGER; "
        b"PROCEDURE LocalCall(first, second: INTEGER); BEGIN END LocalCall; BEGIN\n"
    )
    source = work / "Editing.Mod"

    def run(keys, expected, steps=(), size=(24, 80)):
        source.write_bytes(prefix)
        output = edit(command(source), work, [
            (b"^X", b"\x1b[B" + keys),
            *steps,
            (b"^X", b"\x0f"),
            (b"File Name to Write", b"\r"),
            (b"Wrote ", b"\x18"),
        ], size=size)
        assert source.read_bytes() == prefix + expected, source.read_bytes()
        return output

    output = run(b"F.", b"F.Swap(", [
        (b"arrows choose", b"sWaP"),
        (b"1/1", b"\t"),
    ])
    assert b"\x1b[0;1;38;5;234;48;5;250m" in output, "missing selected-entry colour"
    assert b"\x1b[1;38;5;231mleft" in output, "missing imported parameter hint"
    assert b"proc  private" not in output, "private procedure was offered"

    run(b"F.", b"F.Swap(", [
        (b"arrows choose", b"SwaZ"),
        (b"^X", b"\x7f"),
        (b"1/1", b"\r"),
    ])
    run(b"F.", b"F.Alpha", [
        (b"1/15", b"\x1b[B"),
        (b"2/15", b"\x1b[A"),
        (b"1/15", b"\r"),
    ])
    run(b"F.", b"F.Lambda", [
        (b"1/15", b"\x1b[6~"),
        (b"9/15", b"\t"),
    ])
    run(b"F.", b"F.Alpha", [
        (b"1/15", b"\x1b[6~"),
        (b"9/15", b"\x1b[5~"),
        (b"1/15", b"\t"),
    ])
    for typed, completed in [
        (b"Counter", b"Counter"), (b"Answer", b"Answer"),
        (b"Item", b"Item"), (b"ReadOnly", b"ReadOnly"), (b"Value", b"Value"),
    ]:
        run(b"F.", b"F." + completed, [
            (b"arrows choose", typed), (b"1/1", b"\t"),
        ])
    run(b"CompletionFixture.Swa\x00", b"CompletionFixture.Swap(", [(b"1/1", b"\t")])
    run(b"F.", b"F.", [(b"arrows choose", b"\x1b")])
    for typed, completed in [
        (b"localv", b"localVariable"), (b"localca", b"LocalCall("),
        (b"localcon", b"LocalConstant"), (b"localt", b"LocalType"),
        (b"ash", b"ASH("),
    ]:
        run(typed + b"\x00", completed, [(b"1/1", b"\t")])

    output = run(b"LocalCall(1,\r", b"LocalCall(1,\n")
    assert b"\x1b[1;38;5;231msecond" in output, "missing multiline local parameter hint"
    output = run(b"ASH(1,", b"ASH(1,")
    assert b"\x1b[1;38;5;231mn" in output, "missing predeclared parameter hint"
    output = run(b"F.Swap(1,\r", b"F.Swap(1,\n")
    assert b"\x1b[1;38;5;231mright" in output, "missing multiline imported parameter hint"

    output = run(b"MissingModule.\x00", b"MissingModule.")
    assert b"Nothing to complete here" in output
    output = run(b"123\x00", b"123")
    assert b"Nothing to complete here" in output
    run(b"\x00", b"F", [
        (b"arrows choose", b"F"), (b"1/1", b"\t"),
    ])

    for remove in [False, True]:
        expected = b"freshV\t" if remove else b"VAR freshVariable: INTEGER; BEGIN\nfreshVariable"
        steps = [
            (b"arrows choose", b"\x1b"),
            (b"^X", b"\x1b[200~VAR freshVariable: INTEGER; BEGIN\n\x1b[201~"),
            (b"^X", b"\x00"),
            (b"arrows choose", b"\x1b"),
        ]
        if remove:
            steps.append((b"^X", b"\x1b[H\x1b[A\x0bfreshV\x00\t"))
        else:
            steps.extend([(b"^X", b"freshV\x00"), (b"1/1", b"\t")])
        run(b"\x00", expected, steps)

    run(b"F.Swa\x00\t", b"F.Swap(", size=(5, 10))
    run(b"F.", b"F.Swap(", [
        (b"arrows choose", b"Swap"), (b"1/1", b"\t"),
    ], size=(24, 600))

    plain = work / "completion.txt"
    plain.write_bytes(b"")
    output = edit(command(plain), work, [
        (b"^X", b"CompletionFixture.\x00\x0f"),
        (b"File Name to Write", b"\r"), (b"Wrote ", b"\x18"),
    ])
    assert plain.read_bytes() == b"CompletionFixture."
    assert b"arrows choose" not in output, "completion was enabled for a plain file"


def check_symbol_paths(command, work, hresh=None, modules=None):
    symbols = work / "symbols"
    symbols.mkdir(exist_ok=True)
    symbol = work / "CompletionFixture.sym"
    relocated = symbols / symbol.name
    symbol.replace(relocated)
    try:
        for variable in ["VOC_SYM_PATH", "OBERON", "MODULES", "VOC_MODULE_PATH"]:
            source = work / "Lookup.Mod"
            source.write_bytes(b"MODULE Lookup; IMPORT F := CompletionFixture;\n")
            output = edit(command(source), work, [
                (b"^X", b"\x1b[BF."),
                (b"arrows choose", b"Swa"),
                (b"1/1", b"\t\x0f"),
                (b"File Name to Write", b"\r"), (b"Wrote ", b"\x18"),
            ], env={variable: str(symbols)})
            assert source.read_bytes().endswith(b"F.Swap("), (variable, output[-1000:])

        source = symbols / "Lookup.Mod"
        source.write_bytes(b"MODULE Lookup; IMPORT F := CompletionFixture;\n")
        edit(command(source), work, [
            (b"^X", b"\x1b[BF."), (b"arrows choose", b"Swa"), (b"1/1", b"\t\x18"),
            (b"Save modified buffer?", b"n"),
        ])
        if hresh:
            source = work / "Lookup.Mod"
            edit([hresh, f"-P{symbols}:{modules}", "none.Open", source.name], work, [
                (b"^X", b"\x1b[BF."), (b"arrows choose", b"\x18"),
                (b"Save modified buffer?", b"n"),
            ])
    finally:
        relocated.replace(symbol)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    parser.add_argument("--work", type=Path, required=True)
    parser.add_argument("--hresh", type=Path)
    parser.add_argument("--modules", type=Path)
    parser.add_argument("--voc", default="voc")
    args = parser.parse_args()
    check_settings_comparison()
    work = args.work.resolve()
    work.mkdir(parents=True, exist_ok=True)
    fixture = Path(__file__).resolve().with_name("CompletionFixture.Mod")
    voc = str(Path(args.voc).resolve()) if "/" in args.voc else args.voc
    subprocess.run([voc, "-O2", "-sS", str(fixture)], cwd=work, check=True, timeout=30)
    check_standalone(str(args.executable.resolve()), work)
    standalone = lambda source: [str(args.executable.resolve()), str(source.relative_to(work))]
    check_completion(standalone, work)
    check_symbol_paths(standalone, work)
    if args.hresh:
        assert args.modules, "--hresh requires --modules"
        check_loadable(str(args.hresh.resolve()), args.modules.resolve(), work)
        hosted = lambda source: [str(args.hresh.resolve()), f"-P{args.modules.resolve()}",
                                 "none.Open", str(source.relative_to(work))]
        check_completion(hosted, work)
        check_symbol_paths(hosted, work, str(args.hresh.resolve()), args.modules.resolve())
    print("none editor tests passed")


if __name__ == "__main__":
    main()
