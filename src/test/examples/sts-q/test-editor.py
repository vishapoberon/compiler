#!/usr/bin/env python3
"""Testing only private example support, without starting the editor."""
import fcntl
import os
from pathlib import Path
import pty
import select
import struct
import subprocess
import sys
import termios
import time

BUILD = Path(sys.argv[1]).resolve()


def ready(process):
    data = b''
    deadline = time.monotonic() + 5
    while not data.endswith(b'ready\n'):
        remaining = deadline - time.monotonic()
        if remaining <= 0 or not select.select([process.stdout], [], [], remaining)[0]:
            raise AssertionError(('waiting for ready', data))
        chunk = os.read(process.stdout.fileno(), 4096)
        if not chunk:
            raise AssertionError(('early exit', process.poll(), data, process.stderr.read()))
        data += chunk
    return data


def terminal(mode, initial_nonblocking):
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', 24, 80, 0, 0))
    flags = fcntl.fcntl(slave, fcntl.F_GETFL)
    if initial_nonblocking:
        flags |= os.O_NONBLOCK
        fcntl.fcntl(slave, fcntl.F_SETFL, flags)
    original = termios.tcgetattr(slave)
    process = subprocess.Popen(
        [str(BUILD / 'TestSsqTerminal'), mode], stdin=slave,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=BUILD,
        env=dict(os.environ, PETMOUSE='true'),
    )
    try:
        prefix = ready(process)
        assert prefix.count(b'\x1b[?1049h') == 1, prefix
        raw = termios.tcgetattr(slave)
        assert not raw[3] & (termios.ECHO | termios.ICANON | termios.ISIG), raw
        assert fcntl.fcntl(slave, fcntl.F_GETFL) & os.O_NONBLOCK
        os.write(master, b'x')
        out, err = process.communicate(timeout=5)
        assert process.returncode == {'halt': 7, 'fail': 1}.get(mode, 0), (mode, out, err)
        assert out.count(b'\x1b[?1049l') == 1, out
        assert out.count(b'\x1b[?1002;1006;1015l') == 1, out
        assert termios.tcgetattr(slave) == original, (mode, 'terminal not restored')
        assert fcntl.fcntl(slave, fcntl.F_GETFL) == flags, (mode, 'flags not restored')
    finally:
        if process.poll() is None:
            process.kill()
        process.wait()
        os.close(master)
        os.close(slave)


for mode in ('return', 'explicit', 'halt', 'fail'):
    for nonblocking in (False, True):
        terminal(mode, nonblocking)
for data, expected in ((b'hello\n', b'5\nhello\n'), (b'\n', b'0\n\n'),
                       (b'', b'-1\n\n'), (b'last', b'4\nlast\n'),
                       (b'12345678\n', b'-1\n1234567\n')):
    result = subprocess.run([str(BUILD / 'TestSsqInput'), 'line'], cwd=BUILD,
                            input=data, capture_output=True, timeout=5)
    assert result.returncode == 0 and result.stdout == expected, result
for mode in ('eof', 'badfd'):
    result = subprocess.run([str(BUILD / 'TestSsqInput'), mode], cwd=BUILD,
                            stdin=subprocess.DEVNULL, capture_output=True, timeout=5,
                            preexec_fn=(lambda: os.close(0)) if mode == 'badfd' else None)
    assert result.returncode == 0, result
print('sts-q private example terminal and input tests passed')
