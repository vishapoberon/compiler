#!/usr/bin/env python3
"""Exercise NetSystem async opening using isolated IPv4 loopback peers."""
from contextlib import closing
from pathlib import Path
import select
import socket
import subprocess
import sys
import threading
import time

program = str(Path(sys.argv[1]).resolve())


def run(*args):
    subprocess.run([program, *map(str, args)], check=True, timeout=15)


def bound_socket():
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.bind(("127.0.0.1", 0))
    sock.settimeout(10)
    return sock


run("basic")
with closing(bound_socket()) as refused:
    # Keep the port reserved without listening, so connect must fail locally.
    run("refused", refused.getsockname()[1])

with closing(bound_socket()) as listener, closing(bound_socket()) as reservation:
    listener.listen(1)
    fillers = []
    try:
        # Fill the completed-connection queue until a handshake cannot finish.
        # A zero SO_ERROR on that next socket does not mean it is connected.
        for _ in range(16):
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            fillers.append(sock)
            sock.setblocking(False)
            sock.connect_ex(listener.getsockname())
            if not select.select([], [sock], [], 0.1)[1]:
                assert sock.getsockopt(socket.SOL_SOCKET, socket.SO_ERROR) == 0
                break
        else:
            raise AssertionError("could not saturate loopback listener backlog")
        port = listener.getsockname()[1]
        local_port = reservation.getsockname()[1]
        reservation.close()
        run("pending", port, local_port)
        # Closing the fillers leaves their completed connections queued until
        # accept drains them; a new attempt must still start in waitCon.
        for sock in fillers:
            sock.close()
        resume_errors = []

        def drain():
            try:
                while True:
                    with closing(listener.accept()[0]) as sock:
                        sock.settimeout(10)
                        data = sock.recv(1)
                        if data:
                            assert data == b"Q"
                            sock.sendall(b"R")
                            return
            except BaseException as error:
                resume_errors.append(error)

        thread = threading.Thread(target=drain, daemon=True)
        process = subprocess.Popen([program, "resume", str(port)], stdout=subprocess.PIPE, text=True)
        try:
            assert select.select([process.stdout], [], [], 5)[0], "no pending-state confirmation"
            assert process.stdout.readline() == "NetSystem resume pending\n"
            thread.start()
            output, _ = process.communicate(timeout=15)
            print(output, end="")
            if process.returncode:
                raise subprocess.CalledProcessError(process.returncode, process.args)
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
            process.stdout.close()
        thread.join(12)
        assert not thread.is_alive(), "pending connection did not resume"
        if resume_errors:
            raise resume_errors[0]
    finally:
        for sock in fillers:
            sock.close()

with closing(bound_socket()) as listener:
    listener.listen(1)
    errors = []

    def peer():
        try:
            with closing(listener.accept()[0]) as sock:
                sock.settimeout(10)
                time.sleep(0.1)
                for fragment in (b"ab", b"cd", b"efg\0"):
                    sock.sendall(fragment)
                    time.sleep(0.1)
                # Leave enough data outstanding to force a blocking send.
                time.sleep(0.2)
                remaining = 128 * 65536
                while remaining:
                    data = sock.recv(min(65536, remaining))
                    assert data and data == b"x" * len(data)
                    remaining -= len(data)
                sock.sendall(b"Y")
        except BaseException as error:
            errors.append(error)

    thread = threading.Thread(target=peer, daemon=True)
    thread.start()
    run("blocking", listener.getsockname()[1])
    thread.join(12)
    assert not thread.is_alive(), "blocking peer did not finish"
    if errors:
        raise errors[0]

print("NetSystem async loopback regressions passed")
