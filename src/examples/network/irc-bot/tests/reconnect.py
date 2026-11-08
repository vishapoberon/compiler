"""Application regressions against a local fake IRC server."""
import contextlib
import os
from pathlib import Path
import signal
import socket
import subprocess
import sys
import tempfile
import time


class Peer:
    def __init__(self, connection):
        self.connection = connection
        self.buffer = b""

    def send(self, text):
        self.connection.sendall(text.encode())

    def line(self, timeout=4):
        deadline = time.monotonic() + timeout
        while b"\n" not in self.buffer:
            self.connection.settimeout(max(0.001, deadline - time.monotonic()))
            data = self.connection.recv(65536)
            assert data, self.buffer
            self.buffer += data
        line, self.buffer = self.buffer.split(b"\n", 1)
        assert line.endswith(b"\r") and len(line) + 1 <= 512, line
        return line[:-1].decode()

    def expect(self, text, timeout=4):
        actual = self.line(timeout)
        assert actual == text, (actual, text)

    def close(self):
        self.connection.close()


@contextlib.contextmanager
def running(command, directory):
    with tempfile.TemporaryFile() as output:
        process = subprocess.Popen(command, cwd=directory, stdout=output, stderr=output)
        failed = False
        try:
            yield process
        except BaseException:
            failed = True
            raise
        finally:
            if process.poll() is None:
                process.send_signal(signal.SIGINT)
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill(); process.wait()
            if failed or process.returncode:
                output.seek(0)
                print(output.read().decode(errors="replace"), file=sys.stderr)
            if not failed:
                assert process.returncode == 0, process.returncode


def accept(server, timeout=4):
    server.settimeout(timeout)
    connection, _ = server.accept()
    peer = Peer(connection)
    peer.expect("CAP LS 302"); peer.expect("NICK bot"); peer.expect("USER testuser 0 * :owner")
    peer.send(":s CAP * LS :\r\n")
    peer.expect("CAP END")
    peer.send(":s 001 bot :welcome\r\n")
    peer.expect("JOIN #room")
    return peer


def main():
    bot = str(Path(sys.argv[1]).resolve())
    with tempfile.TemporaryDirectory(prefix="irc-bot-tests-") as temporary:
        directory = Path(temporary)
        log = directory / "#room"
        log.write_text("x" * 13000 + "\n2026-1-1 (0:0:0) old: preloaded")
        with socket.socket() as server:
            server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            server.bind(("127.0.0.1", 0)); server.listen()
            command = [bot, "-h", "127.0.0.1", "-p", str(server.getsockname()[1]), "-x", "plain",
                       "-o", "owner", "-u", "testuser", "-n", "bot", "-r", "#room", "-l", "3"]
            with running(command, directory):
                peer = accept(server)
                peer.send(":bob!u@h PRIVMSG bot :last 1\r\nPING :loaded\r\n")
                peer.expect("PONG :loaded"); peer.expect("PRIVMSG bob :old: preloaded")
                peer.send(":alice!u@h PRIVMSG #room :first\r\n"
                          ":alice!u@h PRIVMSG #room :second\r\n"
                          ":alice!u@h PRIVMSG #room :բարեւ\r\n"
                          ":bob!u@h PRIVMSG BOT :last 3\r\nPING :during-history\r\n")
                peer.expect("PONG :during-history", 1)
                peer.expect("PRIVMSG bob :alice: first")
                started = time.monotonic()
                peer.send("PING :between-replies\r\n")
                peer.expect("PONG :between-replies", 1)
                peer.expect("PRIVMSG bob :alice: second")
                assert time.monotonic() - started >= 1.7
                peer.expect("PRIVMSG bob :alice: բարեւ")
                peer.send(":bob!u@h PRIVMSG bot :  SeArCh 1 second\r\n")
                peer.expect("PRIVMSG bob :Found 1 matches. Showing last 1:")
                peer.expect("PRIVMSG bob :alice: second")
                peer.send(":s NOTICE bot :help\r\nPING :notice\r\n")
                peer.expect("PONG :notice")
                peer.send(":bob!u@h PRIVMSG bot :last 0\r\n")
                peer.expect("PRIVMSG bob :Use 'last n' with a positive message count.")
                peer.close()
                peer = accept(server, 27)
                peer.send(":bob!u@h PRIVMSG bot :last 1\r\nPING :reconnected\r\n")
                peer.expect("PONG :reconnected"); peer.expect("PRIVMSG bob :alice: բարեւ")
            peer.close()
            assert "alice: բարեւ" in log.read_text()
            # Restart and restore history written by the new example.
            with running(command, directory):
                peer = accept(server)
                peer.send(":bob!u@h PRIVMSG bot :last 1\r\n")
                peer.expect("PRIVMSG bob :alice: բարեւ")
            peer.close()
            log.write_text("")
            with running(command, directory):
                peer = accept(server)
                peer.send(":bob!u@h PRIVMSG bot :last 1\r\nPING :empty\r\n")
                peer.expect("PONG :empty"); peer.expect("PRIVMSG bob :I do not remember any messages yet.")
            peer.close()
            # Explicit plaintext transport must not leak configured SASL credentials.
            with tempfile.TemporaryFile() as output:
                process = subprocess.Popen(command + ["-a", "account"], cwd=directory,
                                           env={**os.environ, "IRC_SASL_PASSWORD": "synthetic-secret"},
                                           stdout=output, stderr=output)
                try:
                    server.settimeout(4)
                    connection, _ = server.accept()
                    with connection:
                        connection.settimeout(4)
                        assert connection.recv(1024) == b""
                    assert process.wait(timeout=4) == 3
                    output.seek(0)
                    assert b"synthetic-secret" not in output.read()
                finally:
                    if process.poll() is None:
                        process.kill(); process.wait()
    print("PASS: bot history, search, pacing, responsive PINGs, reconnect, UTF-8 and restart")


if __name__ == "__main__":
    main()
