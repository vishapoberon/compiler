"""Strict pinned Ed25519 client interoperability and fail-closed cases; requires cryptography.

Usage: python3 pinned-client.py COMPILER BUILD MODEL FLAGS
"""
from datetime import datetime, timedelta, timezone
import os
from pathlib import Path
import shlex
import socket
import ssl
import subprocess
import sys
import threading
import time

from cryptography import x509
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.x509.oid import ExtendedKeyUsageOID, NameOID


compiler, directory, model, flags = sys.argv[1:]
tests = Path(__file__).resolve().parent
source = tests.parent/"src"
if not (source/"TLS13Auth.Mod").is_file():
    source = tests.parents[2]/"ports/norayr/tls"
build = Path(directory).resolve()
build.mkdir(parents=True, exist_ok=True)
env = dict(os.environ, OBERON=str(build)+";"+os.environ.get("OBERON", ""))
for module in ("TLSBytes", "TLSSHA512", "TLSEd25519", "TLSSig", "TLSIdentity", "TLSX509Ext", "TLSX509Chain",
               "TLS13Auth", "TLS13Handshake", "TLS13EncHandshake", "TLS13Live"):
    subprocess.run([str(Path(compiler).resolve()), "-O"+model, "-sF", str(source/(module+".Mod"))],
                   cwd=build, env=env, check=True)
for module in ("TestPinnedClient", "TestPinnedClientQueue"):
    subprocess.run([str(Path(compiler).resolve()), "-O"+model, *shlex.split(flags), str(tests/(module+".Mod"))],
                   cwd=build, env=env, check=True)
now = datetime.now(timezone.utc)


def identity(label, before=-1, after=1, usage=None):
    private = Ed25519PrivateKey.generate()
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, label)])
    builder = (x509.CertificateBuilder().subject_name(name).issuer_name(name).public_key(private.public_key())
               .serial_number(1).not_valid_before(now+timedelta(days=before)).not_valid_after(now+timedelta(days=after)))
    if usage is not None:
        builder = builder.add_extension(x509.ExtendedKeyUsage([usage]), critical=True)
    certificate = builder.sign(private, None)
    cert, key = build/(label+".pem"), build/(label+".key")
    cert.write_bytes(certificate.public_bytes(serialization.Encoding.PEM))
    key.write_bytes(private.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                                        serialization.NoEncryption()))
    public = private.public_key().public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw)
    return cert, key, public, certificate.public_bytes(serialization.Encoding.DER)


client = identity("client")
server = identity("server")
expired = identity("expired", before=-2, after=-1)
client_only = identity("client-only", usage=ExtendedKeyUsageOID.CLIENT_AUTH)
server_only = identity("server-only", usage=ExtendedKeyUsageOID.SERVER_AUTH)


def serve(connection, context, expected, peer_cert, failures):
    incoming, outgoing = ssl.MemoryBIO(), ssl.MemoryBIO()
    stream = context.wrap_bio(incoming, outgoing, server_side=True)
    connection.settimeout(20)

    def drain():
        wire = outgoing.read()
        for at in range(0, len(wire), 7):
            connection.sendall(wire[at:at+7])
            time.sleep(0.0001)

    def receive():
        data = connection.recv(16384)
        if not data:
            raise EOFError("native client closed")
        incoming.write(data)

    try:
        while True:
            try:
                stream.do_handshake(); drain(); break
            except ssl.SSLWantReadError:
                drain(); receive()
        assert expected == "accept", "a rejected connection completed TLS"
        assert stream.getpeercert(binary_form=True) == peer_cert
        received = b""
        while len(received) < 5:
            try:
                received += stream.read(5-len(received))
            except ssl.SSLWantReadError:
                drain(); receive()
        assert received == b"hello", received
        stream.write(b"world"); drain()
    except (ssl.SSLError, OSError, EOFError) as error:
        if expected == "accept":
            failures.append(error)
    except BaseException as error:
        failures.append(error)
    finally:
        connection.close()


cases = [
    ("X25519", server, client, server[2], True, "accept", False),
    ("prime256v1", server, client, server[2], True, "accept", False),
    ("X25519", server, client, bytes(32), True, "reject", False),
    ("X25519", server, client, server[2], False, "reject", False),
    ("X25519", expired, client, expired[2], True, "reject", False),
    ("X25519", client_only, client, client_only[2], True, "reject", False),
    ("X25519", server, client, server[2][:-1], True, "begin-reject", False),
    ("X25519", server, server_only, server[2], True, "begin-reject", False),
    ("X25519", server, client, b"", True, "begin-reject", False),
    ("X25519", server, client, server[2], True, "reject", True),
]
for number, (curve, remote, local, pin, required, expected, downgrade) in enumerate(cases, 1):
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.minimum_version = context.maximum_version = ssl.TLSVersion.TLSv1_2 if downgrade else ssl.TLSVersion.TLSv1_3
    context.load_cert_chain(remote[0], remote[1]); context.set_ecdh_curve(curve)
    if required:
        context.verify_mode = ssl.CERT_REQUIRED
        context.load_verify_locations(local[0])
    client_messages = []

    def observe(connection, direction, version, content_type, message_type, data):
        if direction == "read" and int(content_type) == 22 and int(message_type) in (11, 15):
            client_messages.append(int(message_type))

    context._msg_callback = observe
    native, peer = socket.socketpair()
    failures = []
    worker = threading.Thread(target=serve, args=(peer, context, expected, local[3], failures), daemon=True)
    worker.start()
    try:
        # A valid CA certificate cannot override an exact-key mismatch. Successful cases need no CA bundle.
        trust = str(remote[0]) if pin == bytes(32) else str(build/"absent-ca-bundle.pem")
        result = subprocess.run([str(build/"TestPinnedClient"), str(local[0]), str(local[1]), pin.hex(),
                                 str(native.fileno()), expected], cwd=build, env=dict(env, SSL_CERT_FILE=trust),
                                pass_fds=(native.fileno(),), capture_output=True, text=True, timeout=40)
    finally:
        native.close()
    worker.join(21)
    assert not worker.is_alive(), "Python server did not finish"
    assert result.returncode == 0, (number, result.returncode, result.stdout, result.stderr)
    assert not failures, (number, failures)
    assert client_messages == ([11, 15] if expected == "accept" else []), (number, client_messages)
    print("PASS pinned native client:", number, curve, remote[0].stem, expected)


with socket.socket() as reservation:
    reservation.bind(("127.0.0.1", 0)); address = reservation.getsockname()
with (build/"unsupported-client-signature.log").open("w+") as log:
    process = subprocess.Popen(["openssl", "s_server", "-accept", "127.0.0.1:"+str(address[1]), "-tls1_3",
                                "-cert", str(server[0]), "-key", str(server[1]), "-CAfile", str(client[0]),
                                "-verify", "1", "-client_sigalgs", "ecdsa_secp256r1_sha256",
                                "-www", "-msg", "-quiet", "-naccept", "1"],
                               stdin=subprocess.DEVNULL, stdout=log, stderr=log)
    try:
        deadline = time.monotonic()+15
        while True:
            if process.poll() is not None:
                log.seek(0); raise AssertionError(log.read())
            assert time.monotonic() < deadline, "OpenSSL did not listen"
            try:
                connection = socket.create_connection(address, timeout=1); break
            except ConnectionRefusedError:
                time.sleep(0.01)
        with connection:
            connection.setblocking(True)
            result = subprocess.run([str(build/"TestPinnedClient"), str(client[0]), str(client[1]), server[2].hex(),
                                     str(connection.fileno()), "reject"], cwd=build, env=env,
                                    pass_fds=(connection.fileno(),), capture_output=True, text=True, timeout=40)
        process.wait(timeout=15); log.seek(0); wire = log.read()
        assert result.returncode == 0, (result.returncode, result.stdout, result.stderr, wire)
        assert "did not request Ed25519 client authentication" in result.stdout, result.stdout
        assert not any(line.startswith("<<<") and "Certificate" in line for line in wire.splitlines()), wire
        print("PASS pinned native client: unsupported client signature scheme")
    finally:
        if process.poll() is None:
            process.kill(); process.wait()


for mode in ("complete", "cancel"):
    natives, workers, failures, arguments = [], [], [], []
    for index, remote in enumerate((server, identity("second-server"))):
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.minimum_version = context.maximum_version = ssl.TLSVersion.TLSv1_3
        context.load_cert_chain(remote[0], remote[1]); context.verify_mode = ssl.CERT_REQUIRED
        context.load_verify_locations(client[0])
        native, peer = socket.socketpair(); natives.append(native)
        arguments.extend([remote[2].hex(), str(native.fileno())])
        expected = "reject" if mode == "cancel" and index == 0 else "accept"
        worker = threading.Thread(target=serve, args=(peer, context, expected, client[3], failures), daemon=True)
        worker.start(); workers.append(worker)
    try:
        result = subprocess.run([str(build/"TestPinnedClientQueue"), str(client[0]), str(client[1]), *arguments, mode],
                                cwd=build, env=env, pass_fds=tuple(native.fileno() for native in natives),
                                capture_output=True, text=True, timeout=40)
    finally:
        for native in natives:
            native.close()
    for worker in workers:
        worker.join(21)
        assert not worker.is_alive(), "queued server did not finish"
    assert result.returncode == 0, (mode, result.returncode, result.stdout, result.stderr)
    assert not failures, (mode, failures)
    print("PASS pinned native client queue:", mode)


native, peer = socket.socketpair(); peer.settimeout(20)
process = subprocess.Popen([str(build/"TestPinnedClient"), str(client[0]), str(client[1]), server[2].hex(),
                            str(native.fileno()), "reject"], cwd=build, env=env,
                           pass_fds=(native.fileno(),), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
native.close()
try:
    def exact(length):
        data = bytearray()
        while len(data) < length:
            chunk = peer.recv(length-len(data))
            assert chunk, "client closed before its ClientHello"
            data.extend(chunk)
        return data

    header = exact(5); hello = exact(int.from_bytes(header[3:5], "big"))
    session = hello[39:39+hello[38]]
    cookie = bytes(16290)
    extensions = b"\x00\x2b\x00\x02\x03\x04"+b"\x00\x2c"+(len(cookie)+2).to_bytes(2, "big")+len(cookie).to_bytes(2, "big")+cookie
    random = bytes.fromhex("cf21ad74e59a6111be1d8c021e65b891c2a211167abb8c5e079e09e2c8a8339c")
    body = b"\x03\x03"+random+bytes([len(session)])+session+b"\x13\x01\x00"+len(extensions).to_bytes(2, "big")+extensions
    retry = b"\x02"+len(body).to_bytes(3, "big")+body
    assert len(retry) <= 16384
    peer.sendall(b"\x16\x03\x03"+len(retry).to_bytes(2, "big")+retry)
    assert not peer.recv(16384), "client sent a second ClientHello beyond its transcript limit"
    stdout, stderr = process.communicate(timeout=20)
    assert process.returncode == 0 and "transcript is too long" in stdout, (process.returncode, stdout, stderr)
    print("PASS pinned native client: bounded HelloRetryRequest transcript")
finally:
    peer.close()
    if process.poll() is None:
        process.kill(); process.wait()
