"""Resumable pinned Ed25519 server interoperability and rejection; requires cryptography.

Usage: python3 pinned-server.py COMPILER BUILD MODEL FLAGS
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

from cryptography import x509
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.x509.oid import ExtendedKeyUsageOID, NameOID, ObjectIdentifier


compiler, directory, model, flags = sys.argv[1:]
tests = Path(__file__).resolve().parent
source = tests.parent/"src"
if not (source/"TLS13Auth.Mod").is_file():
    source = tests.parents[2]/"ports/norayr/tls"
build = Path(directory).resolve()
build.mkdir(parents=True, exist_ok=True)
env = dict(os.environ, OBERON=str(build)+";"+os.environ.get("OBERON", ""))
for module in ("TLSBytes", "TLSSHA512", "TLSEd25519", "TLSSig", "TLSIdentity", "TLSX509Ext", "TLSX509Chain",
               "TLS13Auth", "TLS13Handshake", "TLS13EncHandshake", "TLS13Live", "TLS13Server"):
    subprocess.run([str(Path(compiler).resolve()), "-O"+model, "-sF", str(source/(module+".Mod"))],
                   cwd=build, env=env, check=True)
for module in ("TestPinnedServer", "TestPinnedServerQueue", "TestPinnedClient"):
    subprocess.run([str(Path(compiler).resolve()), "-O"+model, *shlex.split(flags), str(tests/(module+".Mod"))],
                   cwd=build, env=env, check=True)
now = datetime.now(timezone.utc)


def identity(label, before=-1, after=1, usage=None, padding=0):
    private = Ed25519PrivateKey.generate()
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, label)])
    builder = (x509.CertificateBuilder().subject_name(name).issuer_name(name).public_key(private.public_key())
               .serial_number(1).not_valid_before(now+timedelta(days=before)).not_valid_after(now+timedelta(days=after)))
    if usage is not None:
        builder = builder.add_extension(x509.ExtendedKeyUsage([usage]), critical=True)
    if padding:
        builder = builder.add_extension(x509.UnrecognizedExtension(ObjectIdentifier("1.2.3.5"), bytes(padding)), critical=False)
    certificate = builder.sign(private, None)
    cert, key = build/(label+".pem"), build/(label+".key")
    cert.write_bytes(certificate.public_bytes(serialization.Encoding.PEM))
    key.write_bytes(private.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                                        serialization.NoEncryption()))
    public = private.public_key().public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw)
    return cert, key, public


server = identity("server")
client = identity("client")
expired = identity("expired", before=-2, after=-1)
server_only = identity("server-only", usage=ExtendedKeyUsageOID.SERVER_AUTH)
client_only = identity("client-only", usage=ExtendedKeyUsageOID.CLIENT_AUTH)
cases = [
    ("X25519", server, client, client[2], "accept", False, False),
    ("prime256v1", server, client, client[2], "accept", False, False),
    ("X25519", server, client, bytes(32), "reject", False, False),
    ("X25519", server, None, client[2], "reject", False, False),
    ("X25519", server, expired, expired[2], "reject", False, False),
    ("X25519", server, server_only, server_only[2], "reject", False, False),
    ("X25519", server, client, client[2][:-1], "begin-reject", False, False),
    ("X25519", client_only, client, client[2], "begin-reject", False, False),
    ("X25519", server, client, client[2], "reject", True, False),
    ("X25519", server, client, client[2], "reject", False, True),
]
for number, (curve, local, peer_identity, pin, expected, corrupt, downgrade) in enumerate(cases, 1):
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    context.minimum_version = context.maximum_version = ssl.TLSVersion.TLSv1_2 if downgrade else ssl.TLSVersion.TLSv1_3
    context.load_verify_locations(local[0]); context.set_ecdh_curve(curve)
    if peer_identity:
        context.load_cert_chain(peer_identity[0], peer_identity[1])
    incoming, outgoing = ssl.MemoryBIO(), ssl.MemoryBIO()
    stream = context.wrap_bio(incoming, outgoing, server_hostname=local[0].stem)
    native, connection = socket.socketpair(); connection.settimeout(20)
    process = subprocess.Popen([str(build/"TestPinnedServer"), str(local[0]), str(local[1]), pin.hex(),
                                str(native.fileno()), expected], cwd=build, env=env,
                               pass_fds=(native.fileno(),), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    native.close(); handshake_complete = False

    def drain():
        wire = bytearray(outgoing.read())
        if corrupt and handshake_complete and wire:
            wire[-1] ^= 1
        for at in range(0, len(wire), 7):
            connection.sendall(wire[at:at+7])

    def receive():
        wire = connection.recv(16384)
        if not wire:
            raise EOFError("native server closed")
        incoming.write(wire)

    try:
        try:
            while True:
                try:
                    stream.do_handshake(); handshake_complete = True; drain(); break
                except ssl.SSLWantReadError:
                    drain(); receive()
            if expected == "accept":
                stream.write(b"hello"); drain()
            reply = b""
            while len(reply) < 5:
                try:
                    reply += stream.read(5-len(reply))
                except ssl.SSLWantReadError:
                    drain(); receive()
            assert expected == "accept" and reply == b"world", (expected, reply)
        except (ssl.SSLError, OSError, EOFError):
            if expected == "accept":
                raise
        stdout, stderr = process.communicate(timeout=20)
        assert process.returncode == 0, (number, process.returncode, stdout, stderr)
        print("PASS pinned native server:", number, curve, expected)
    finally:
        connection.close()
        if process.poll() is None:
            process.kill(); process.wait()


large_client = identity("large-client", padding=2048)
with socket.socket() as listener:
    listener.bind(("127.0.0.1", 0)); listener.listen(); listener.settimeout(20)
    external = subprocess.Popen(["openssl", "s_client", "-connect", "127.0.0.1:"+str(listener.getsockname()[1]),
                                 "-tls1_3", "-groups", "P-384:X25519", "-max_send_frag", "512",
                                 "-cert", str(large_client[0]), "-key", str(large_client[1]),
                                 "-CAfile", str(server[0]), "-verify_return_error", "-quiet", "-ign_eof", "-ignore_unexpected_eof"],
                                stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    connection, _ = listener.accept()
    try:
        process = subprocess.Popen([str(build/"TestPinnedServer"), str(server[0]), str(server[1]), large_client[2].hex(),
                                    str(connection.fileno()), "accept"], cwd=build, env=env,
                                   pass_fds=(connection.fileno(),), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        connection.close()
        response, errors = external.communicate(input=b"hello", timeout=30)
        stdout, stderr = process.communicate(timeout=20)
        assert external.returncode == 0 and response == b"world", (external.returncode, response, errors)
        assert process.returncode == 0, (process.returncode, stdout, stderr)
        print("PASS pinned native server: HelloRetryRequest and fragmented client Certificate")
    finally:
        connection.close()
        if external.poll() is None:
            external.kill(); external.wait()
        if 'process' in locals() and process.poll() is None:
            process.kill(); process.wait()


native_server, native_client = socket.socketpair()
process = subprocess.Popen([str(build/"TestPinnedServer"), str(server[0]), str(server[1]), client[2].hex(),
                            str(native_server.fileno()), "accept"], cwd=build, env=env,
                           pass_fds=(native_server.fileno(),), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
native_server.close()
try:
    result = subprocess.run([str(build/"TestPinnedClient"), str(client[0]), str(client[1]), server[2].hex(),
                             str(native_client.fileno()), "accept"], cwd=build, env=env,
                            pass_fds=(native_client.fileno(),), capture_output=True, text=True, timeout=30)
    native_client.close(); stdout, stderr = process.communicate(timeout=20)
    assert result.returncode == 0, (result.returncode, result.stdout, result.stderr)
    assert process.returncode == 0, (process.returncode, stdout, stderr)
    print("PASS native-to-native pinned mutual TLS")
finally:
    native_client.close()
    if process.poll() is None:
        process.kill(); process.wait()


def raw_rejection(label, records):
    native, connection = socket.socketpair(); connection.settimeout(20)
    process = subprocess.Popen([str(build/"TestPinnedServer"), str(server[0]), str(server[1]), client[2].hex(),
                                str(native.fileno()), "reject"], cwd=build, env=env,
                               pass_fds=(native.fileno(),), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    native.close()
    try:
        connection.sendall(records)
        try:
            assert not connection.recv(16384), "server wrote data on a malformed ClientHello"
        except ConnectionResetError:
            pass
        stdout, stderr = process.communicate(timeout=20)
        assert process.returncode == 0, (label, process.returncode, stdout, stderr)
        print("PASS pinned native server malformed input:", label)
    finally:
        connection.close()
        if process.poll() is None:
            process.kill(); process.wait()


raw_rejection("empty record", b"\x16\x03\x03\x00\x00")
raw_rejection("application data before ClientHello", b"\x17\x03\x03\x00\x01\x00")
raw_rejection("oversized handshake header", b"\x16\x03\x03\x00\x04\x01\x00\x80\x01")
raw_rejection("oversized plaintext record", b"\x16\x03\x03\x40\x01"+bytes(16385))
context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
context.set_ecdh_curve("X25519")
incoming, outgoing = ssl.MemoryBIO(), ssl.MemoryBIO()
stream = context.wrap_bio(incoming, outgoing, server_hostname="server")
try:
    stream.do_handshake()
except ssl.SSLWantReadError:
    pass
hello = bytearray(outgoing.read()[5:])
at = 4+2+32; at += 1+hello[at]
at += 2+int.from_bytes(hello[at:at+2], "big"); at += 1+hello[at]
length_pos = at; at += 2; extensions = bytearray()
while at < len(hello):
    size = 4+int.from_bytes(hello[at+2:at+4], "big")
    if hello[at:at+2] != b"\x00\x15":
        extensions.extend(hello[at:at+size])
    at += size
hello = hello[:length_pos+2]
padding = 32768-len(hello)-len(extensions)-4
extensions.extend(b"\x00\x15"+padding.to_bytes(2, "big")+bytes(padding))
hello[length_pos:length_pos+2] = len(extensions).to_bytes(2, "big")
hello.extend(extensions); hello[1:4] = (len(hello)-4).to_bytes(3, "big")
records = b"".join(b"\x16\x03\x03"+len(hello[at:at+16384]).to_bytes(2, "big")+hello[at:at+16384]
                   for at in range(0, len(hello), 16384))
raw_rejection("bounded transcript", records)


def client_worker(connection, identity, failures):
    try:
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        context.minimum_version = context.maximum_version = ssl.TLSVersion.TLSv1_3
        context.load_verify_locations(server[0]); context.load_cert_chain(identity[0], identity[1])
        connection.settimeout(20)
        with context.wrap_socket(connection, server_hostname="server") as stream:
            stream.sendall(b"hello"); assert stream.recv(5) == b"world"
    except BaseException as error:
        failures.append(error)
    finally:
        connection.close()


for mode in ("complete", "stalled"):
    natives, peers, workers, arguments, failures = [], [], [], [], []
    for index, peer_identity in enumerate((client, identity("second-client"))):
        native, peer = socket.socketpair(); natives.append(native); peers.append(peer)
        arguments.extend([peer_identity[2].hex(), str(native.fileno())])
        if mode != "stalled" or index != 0:
            worker = threading.Thread(target=client_worker, args=(peer, peer_identity, failures), daemon=True)
            worker.start(); workers.append(worker)
    try:
        result = subprocess.run([str(build/"TestPinnedServerQueue"), str(server[0]), str(server[1]), *arguments, mode],
                                cwd=build, env=env, pass_fds=tuple(native.fileno() for native in natives),
                                capture_output=True, text=True, timeout=30)
    finally:
        for native in natives:
            native.close()
        if mode == "stalled":
            peers[0].close()
    for worker in workers:
        worker.join(21); assert not worker.is_alive(), "concurrent client did not finish"
    assert result.returncode == 0, (mode, result.returncode, result.stdout, result.stderr)
    assert not failures, (mode, failures)
    print("PASS pinned native server concurrency:", mode)
