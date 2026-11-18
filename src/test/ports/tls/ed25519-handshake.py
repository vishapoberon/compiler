"""Ed25519 TLS 1.3 interoperability with Python ssl; requires cryptography.

Usage: python3 ed25519-handshake.py COMPILER BUILD MODEL FLAGS
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
from cryptography.x509.oid import NameOID


compiler, directory, model, flags = sys.argv[1:]
tests = Path(__file__).resolve().parent
source = tests.parent / "src"
if not (source/"TLSIdentity.Mod").is_file():
    source = tests.parents[2] / "ports/norayr/tls"
build = Path(directory).resolve()
build.mkdir(parents=True, exist_ok=True)
env = dict(os.environ, OBERON=str(build)+";"+os.environ.get("OBERON", ""))
for module in ("TLSBytes", "TLSSHA512", "TLSEd25519", "TLSSig", "TLSIdentity", "TLSCertGen",
               "TLSX509Ext", "TLSX509Chain", "TLS13Auth",
               "TLS13Handshake", "TLS13EncHandshake", "TLS13ClientFinished", "TLS13Live", "TLS13Server"):
    subprocess.run([str(Path(compiler).resolve()), "-O"+model, "-sF", str(source/(module+".Mod"))],
                   cwd=build, env=env, check=True)
for module in ("TestEd25519Server", "TestAsync", "TestClientIdentity"):
    subprocess.run([str(Path(compiler).resolve()), "-O"+model, *shlex.split(flags), str(tests/(module+".Mod"))],
                   cwd=build, env=env, check=True)
private = Ed25519PrivateKey.generate()
name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "localhost")])
now = datetime.now(timezone.utc)
certificate = (x509.CertificateBuilder().subject_name(name).issuer_name(name)
               .public_key(private.public_key()).serial_number(1)
               .not_valid_before(now-timedelta(days=1)).not_valid_after(now+timedelta(days=2))
               .add_extension(x509.SubjectAlternativeName([x509.DNSName("localhost")]), critical=False)
               .sign(private, None))
cert, key = build/"server.pem", build/"server.key"
cert.write_bytes(certificate.public_bytes(serialization.Encoding.PEM))
key.write_bytes(private.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                                    serialization.NoEncryption()))


def without_ed25519(wire):
    """Keep ClientHello lengths unchanged while removing its Ed25519 offer."""
    wire = bytearray(wire)
    at = 9+2+32
    at += 1+wire[at]
    at += 2+int.from_bytes(wire[at:at+2], "big")
    at += 1+wire[at]
    end = at+2+int.from_bytes(wire[at:at+2], "big")
    at += 2
    found = False
    while at < end:
        kind = int.from_bytes(wire[at:at+2], "big")
        length = int.from_bytes(wire[at+2:at+4], "big")
        if kind == 13:
            for pos in range(at+6, at+4+length, 2):
                if wire[pos:pos+2] == b"\x08\x07":
                    wire[pos:pos+2] = b"\x04\x03"
                    found = True
        at += 4+length
    assert found
    return wire


for curve, reject in (("X25519", False), ("prime256v1", False), ("X25519", True)):
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    context.minimum_version = context.maximum_version = ssl.TLSVersion.TLSv1_3
    context.load_verify_locations(cert)
    context.set_ecdh_curve(curve)
    incoming, outgoing = ssl.MemoryBIO(), ssl.MemoryBIO()
    stream = context.wrap_bio(incoming, outgoing, server_hostname="localhost")
    native, peer = socket.socketpair()
    peer.settimeout(15)
    process = subprocess.Popen([str(build/"TestEd25519Server"), str(cert), str(key), str(native.fileno()),
                                "reject" if reject else "accept"], cwd=build, env=env,
                               pass_fds=(native.fileno(),), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    native.close()

    def drain():
        wire = outgoing.read()
        for at in range(0, len(wire), 7):
            peer.sendall(wire[at:at+7])

    try:
        if reject:
            try:
                stream.do_handshake()
            except ssl.SSLWantReadError:
                pass
            peer.sendall(without_ed25519(outgoing.read()))
            alert = bytearray()
            while len(alert) < 7:
                chunk = peer.recv(7-len(alert))
                assert chunk, "missing rejection alert"
                alert.extend(chunk)
            assert alert == b"\x15\x03\x03\x00\x02\x02\x28", alert
        else:
            while True:
                try:
                    stream.do_handshake(); drain(); break
                except ssl.SSLWantReadError:
                    drain()
                    chunk = peer.recv(16384)
                    assert chunk, "closed during handshake"
                    incoming.write(chunk)
            assert stream.version() == "TLSv1.3"
            stream.write(b"hello"); drain()
            reply = b""
            while len(reply) < 5:
                try:
                    reply += stream.read(5-len(reply))
                except ssl.SSLWantReadError:
                    chunk = peer.recv(16384)
                    assert chunk, "closed before reply"
                    incoming.write(chunk)
            assert reply == b"world", reply
        stdout, stderr = process.communicate(timeout=15)
        assert process.returncode == 0, (process.returncode, stdout, stderr)
        if reject:
            assert "the client does not accept the signatures of the certificate" in stdout, stdout
        print("PASS native Ed25519 server:", curve, "signature rejection" if reject else "fragmented handshake")
    finally:
        peer.close()
        if process.poll() is None:
            process.kill(); process.wait()


def serve(listener, context, failures):
    try:
        connection, _ = listener.accept()
        connection.settimeout(15)
        with context.wrap_socket(connection, server_side=True) as stream:
            assert stream.version() == "TLSv1.3"
            assert stream.recv(5) == b"hello"
            stream.sendall(b"world")
    except BaseException as error:
        failures.append(error)


for curve, mode in (("X25519", "async"), ("prime256v1", "async"), ("X25519", "blocking")):
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.minimum_version = context.maximum_version = ssl.TLSVersion.TLSv1_3
    context.load_cert_chain(cert, key)
    context.set_ecdh_curve(curve)
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0)); listener.listen(); listener.settimeout(15)
        failures = []
        worker = threading.Thread(target=serve, args=(listener, context, failures), daemon=True)
        worker.start()
        result = subprocess.run([str(build/"TestAsync"), "localhost", str(listener.getsockname()[1]), mode],
                                cwd=build, env=dict(env, SSL_CERT_FILE=str(cert)), capture_output=True, text=True, timeout=40)
        worker.join(16)
        assert not worker.is_alive(), "Python server did not finish"
        assert result.returncode == 0, (result.returncode, result.stdout, result.stderr)
        assert not failures, failures
        print("PASS native client with Ed25519 server:", curve, mode)


for mode in ("blocking", "async"):
    for schemes, expected in (("ed25519", "sent"), ("ecdsa_secp256r1_sha256", "empty")):
        with socket.socket() as reservation:
            reservation.bind(("127.0.0.1", 0))
            address = reservation.getsockname()
        with (build/"certificate-request.log").open("w+") as log:
            server = subprocess.Popen(["openssl", "s_server", "-accept", "127.0.0.1:"+str(address[1]), "-tls1_3",
                                       "-cert", str(cert), "-key", str(key), "-CAfile", str(cert), "-verify", "1",
                                       "-verify_return_error", "-client_sigalgs", schemes, "-www", "-msg", "-quiet", "-naccept", "1"],
                                      stdin=subprocess.DEVNULL, stdout=log, stderr=log)
            try:
                deadline = time.monotonic()+15
                while True:
                    if server.poll() is not None:
                        log.seek(0)
                        raise AssertionError("OpenSSL server exited before listening: "+log.read())
                    assert time.monotonic() < deadline, "OpenSSL server did not listen"
                    try:
                        connection = socket.create_connection(address, timeout=1)
                        break
                    except ConnectionRefusedError:
                        time.sleep(0.01)
                with connection:
                    connection.setblocking(True)
                    result = subprocess.run([str(build/"TestClientIdentity"), str(cert), str(key),
                                             str(connection.fileno()), mode, expected], cwd=build,
                                            env=dict(env, SSL_CERT_FILE=str(cert)), pass_fds=(connection.fileno(),),
                                            capture_output=True, text=True, timeout=40)
                server.wait(timeout=15)
                log.seek(0); wire = log.read()
                assert result.returncode == 0, (result.returncode, result.stdout, result.stderr, wire)
                assert server.returncode == 0, wire
                client_verified = any(line.startswith("<<<") and "CertificateVerify" in line for line in wire.splitlines())
                assert client_verified == (expected == "sent"), wire
                print("PASS native client certificate negotiation:", mode, schemes, expected)
            finally:
                if server.poll() is None:
                    server.kill(); server.wait()
