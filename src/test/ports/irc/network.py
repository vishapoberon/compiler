"""Standalone local-server IRC tests (Python 3; OpenSSL CLI for TLS fixtures)."""
import base64
import contextlib
import os
from pathlib import Path
import signal
import socket
import ssl
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

    def line(self, timeout=5):
        deadline = time.monotonic() + timeout
        while b"\n" not in self.buffer:
            self.connection.settimeout(max(0.001, deadline - time.monotonic()))
            data = self.connection.recv(65536)
            assert data, f"unexpected EOF: {self.buffer!r}"
            self.buffer += data
        line, self.buffer = self.buffer.split(b"\n", 1)
        assert line.endswith(b"\r"), line
        assert len(line) + 1 <= 512, len(line)
        return line[:-1].decode()

    def expect(self, text, timeout=5):
        actual = self.line(timeout)
        assert actual == text, (actual, text)

    def closed(self, timeout=5):
        self.connection.settimeout(timeout)
        assert self.connection.recv(65536) == b"", "expected EOF"

    def close(self):
        self.connection.close()


def listener():
    server = socket.socket()
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("127.0.0.1", 0))
    return server


def accept(server, context=None):
    server.settimeout(10)
    connection, _ = server.accept()
    connection.settimeout(10)
    if context:
        connection = context.wrap_socket(connection, server_side=True)
    return Peer(connection)


@contextlib.contextmanager
def running(command, directory, extra_env=None):
    with tempfile.TemporaryFile() as output:
        process = subprocess.Popen(command, cwd=directory, env={**os.environ, **(extra_env or {})},
                                   stdout=output, stderr=output)
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
                    process.kill()
                    process.wait()
            if failed or process.returncode:
                output.seek(0)
                print(output.read().decode(errors="replace"), file=sys.stderr)
            if not failed:
                assert process.returncode == 0, process.returncode


def register(peer, nick="probe", sasl=False, fragmented=False, chunk=False):
    peer.expect("CAP LS 302")
    peer.expect(f"NICK {nick}")
    peer.expect("USER user 0 * :owner")
    if fragmented:
        for part in (":s CA", "P * LS :", "sasl=PLAIN" if sasl else "", "\r", "\n"):
            peer.send(part)
            time.sleep(0.03)
    else:
        peer.send(":s CAP * LS :sasl=PLAIN\r\n" if sasl else ":s CAP * LS :\r\n")
    if sasl:
        peer.expect("CAP REQ :sasl")
        peer.send(":s CAP probe ACK :sasl\r\n")
        peer.expect("AUTHENTICATE PLAIN")
        peer.send("AUTHENTICATE +\r\n")
        data = ""
        while True:
            line = peer.line()
            assert line.startswith("AUTHENTICATE "), line
            payload = line.removeprefix("AUTHENTICATE ")
            if payload == "+":
                break
            assert len(payload) <= 400
            data += payload
            if len(payload) < 400:
                break
        expected = b"\0" + b"a" * 255 + b"\0" + b"x" * 43 if chunk else b"\0account\0secret"
        assert base64.b64decode(data) == expected
        peer.send(":s 903 probe :SASL successful\r\n")
    peer.expect("CAP END")
    peer.send(f":s 001 {nick} :welcome\r\n")
    peer.expect("JOIN #one")
    peer.expect("JOIN #two")


def plaintext(probe, directory):
    with listener() as server:
        command = [str(probe), "127.0.0.1", str(server.getsockname()[1]), "plain"]
        with running(command, directory) as process:
            time.sleep(0.25)  # initially refuse connections
            server.listen()
            peer = accept(server)
            register(peer, fragmented=True)
            peer.send("\r\n:bob!u@h PRIVMSG #one :hello\r\nPING :first\r\nPING :second\r\n")
            peer.expect("PONG :first")
            peer.expect("PONG :second")
            peer.expect("PRIVMSG #events :echo hello")
            peer.send(":bob!u@h PRIVMSG #one :abandoned")
            time.sleep(0.03)
            peer.close()
            peer = accept(server)
            register(peer)
            peer.send("ERROR :maintenance\r\n")
            peer.closed(); peer.close()
            peer = accept(server)
            peer.expect("CAP LS 302"); peer.expect("NICK probe"); peer.expect("USER user 0 * :owner")
            peer.closed()  # no CAP reply / welcome
            peer.close()
            peer = accept(server)
            register(peer)
            peer.expect("PING :voc-keepalive")
            peer.send(":s PONG s :wrong\r\n")
            peer.closed(); peer.close()
            peer = accept(server)
            register(peer)
            for _ in range(2):
                peer.expect("PING :voc-keepalive")
                peer.send(":s PONG s :voc-keepalive\r\n")
            peer.send("bad\x00stream\r\n")
            peer.closed(); peer.close()
            peer = accept(server)
            register(peer)
            peer.send(":s 433 probe probe :in use\r\n")
            peer.closed(); peer.close()
            peer = accept(server)
            register(peer)
            peer.send(":bob!u@h PRIVMSG probe :stop\r\n")
            peer.closed(); peer.close()
            process.wait(timeout=2)
            server.settimeout(0.2)
            try:
                extra, _ = server.accept()
            except socket.timeout:
                pass
            else:
                extra.close()
                raise AssertionError("Stop reconnected")
    for mode in ("sasl", "chunk"):
        with listener() as server:
            server.listen()
            with running([str(probe), "127.0.0.1", str(server.getsockname()[1]), mode], directory):
                peer = accept(server)
                register(peer, sasl=True, chunk=mode == "chunk")
                peer.send(":bob!u@h PRIVMSG probe :stop\r\n")
                peer.closed(); peer.close()
    with listener() as server:
        server.listen()
        with running([str(probe), "127.0.0.1", str(server.getsockname()[1]), "policy"], directory) as process:
            peer = accept(server)
            peer.closed(); peer.close()
            process.wait(timeout=2)
    for reply in (":s CAP probe NAK :sasl", ":s 904 probe :authentication failed"):
        with listener() as server:
            server.listen()
            with running([str(probe), "127.0.0.1", str(server.getsockname()[1]), "sasl"], directory) as process:
                peer = accept(server)
                peer.expect("CAP LS 302"); peer.expect("NICK probe"); peer.expect("USER user 0 * :owner")
                peer.send(":s CAP * LS :sasl=PLAIN\r\n"); peer.expect("CAP REQ :sasl")
                peer.send(reply + "\r\n"); peer.closed(); peer.close(); process.wait(timeout=2)
    print("PASS: TCP framing, reconnects, deadlines, stop, SASL framing and plaintext credential policy")


def certificate(directory, name, hostname):
    cert, key = directory / f"{name}.crt", directory / f"{name}.key"
    subprocess.run(["openssl", "req", "-x509", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:P-256",
                    "-nodes", "-keyout", str(key), "-out", str(cert), "-days", "2", "-subj", f"/CN={hostname}",
                    "-addext", f"subjectAltName=DNS:{hostname}"], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return cert, key


def tls_tests(probe, directory):
    cert, key = certificate(directory, "server", "localhost")
    wrong, _ = certificate(directory, "untrusted", "localhost")
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.minimum_version = ssl.TLSVersion.TLSv1_3
    context.load_cert_chain(cert, key)
    for curve in ("X25519", "prime256v1"):
        context.set_ecdh_curve(curve)
        with listener() as server:
            server.listen()
            with running([str(probe), "localhost", str(server.getsockname()[1]), "tls"], directory,
                         {"SSL_CERT_FILE": str(cert)}):
                peer = accept(server, context)
                register(peer, sasl=True, fragmented=True)
                peer.send("PING :encrypted\r\n:bob!u@h PRIVMSG probe :stop\r\n")
                # Stop closes immediately, including any queued PONG.
                peer.closed(); peer.close()
    for host, trust in (("127.0.0.1", cert), ("localhost", wrong)):
        with listener() as server:
            server.listen()
            with running([str(probe), host, str(server.getsockname()[1]), "tls"], directory,
                         {"SSL_CERT_FILE": str(trust)}):
                try:
                    peer = accept(server, context)
                except (ssl.SSLError, ConnectionResetError):
                    pass
                else:
                    peer.closed(); peer.close()
    print("PASS: verified TLS 1.3, HelloRetryRequest, SASL over TLS, hostname and CA rejection")


def main():
    probe = Path(sys.argv[1]).resolve()
    with tempfile.TemporaryDirectory(prefix="irc-network-") as temporary:
        directory = Path(temporary)
        plaintext(probe, directory)
        tls_tests(probe, directory)


if __name__ == "__main__":
    main()
