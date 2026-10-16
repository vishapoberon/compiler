"""HTTP/TLS interoperability against Python/OpenSSL, using loopback only."""
import concurrent.futures
import os
from pathlib import Path
import selectors
import socket
import ssl
import subprocess
import sys


build = Path(sys.argv[1]).resolve()
fixtures = build / "loopback"
fixtures.mkdir(exist_ok=True)
env = os.environ.copy()
env["SSL_CERT_FILE"] = str(fixtures / "ca.pem")


def openssl(*args):
    result = subprocess.run(["openssl", *args], cwd=fixtures,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            text=True, timeout=30)
    if result.returncode:
        raise RuntimeError(result.stdout)


openssl("req", "-x509", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:P-256",
        "-nodes", "-keyout", "ca.key", "-out", "ca.pem", "-days", "2",
        "-subj", "/CN=VOC loopback CA", "-addext", "basicConstraints=critical,CA:TRUE",
        "-addext", "keyUsage=critical,keyCertSign,cRLSign")
for name, san, keytype in [("ec", "DNS:localhost,IP:127.0.0.1", "ec"),
                           ("rsa", "DNS:localhost,IP:127.0.0.1", "rsa:2048"),
                           ("wrong", "DNS:wrong.test", "ec")]:
    options = ["-pkeyopt", "ec_paramgen_curve:P-256"] if keytype == "ec" else []
    openssl("req", "-new", "-newkey", keytype, *options, "-nodes",
            "-keyout", name + ".key", "-out", name + ".csr", "-subj", "/CN=localhost")
    (fixtures / (name + ".ext")).write_text(
        "basicConstraints=critical,CA:FALSE\nkeyUsage=critical,digitalSignature\n"
        "extendedKeyUsage=serverAuth\nsubjectAltName=" + san + "\n")
    openssl("x509", "-req", "-in", name + ".csr", "-CA", "ca.pem", "-CAkey", "ca.key",
            "-CAcreateserial", "-out", name + ".pem", "-days", "2", "-extfile", name + ".ext")
openssl("req", "-x509", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:P-256",
        "-nodes", "-keyout", "untrusted.key", "-out", "untrusted.pem", "-days", "2",
        "-subj", "/CN=localhost", "-addext", "subjectAltName=DNS:localhost,IP:127.0.0.1")


def client_case(name, mode="complete", size=4097, framing="length", certificate=None,
                tls12=False):
    payload = bytes((i * 7 + i // 251) % 256 for i in range(size))
    context = None
    if certificate:
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(fixtures / (certificate + ".pem"), fixtures / (certificate + ".key"))
        context.minimum_version = ssl.TLSVersion.TLSv1_2 if tls12 else ssl.TLSVersion.TLSv1_3
        context.maximum_version = context.minimum_version

    with socket.socket() as listener, concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
        listener.bind(("127.0.0.1", 0))
        listener.listen(1)
        listener.settimeout(20)

        def serve():
            connection, _ = listener.accept()
            with connection:
                connection.settimeout(20)
                if context:
                    try:
                        connection = context.wrap_socket(connection, server_side=True)
                    except ssl.SSLError:
                        if mode == "refused":
                            return
                        raise
                with connection:
                    request = b""
                    while b"\r\n\r\n" not in request:
                        part = connection.recv(4096)
                        if not part:
                            if mode == "refused":
                                return
                            raise RuntimeError("client ended its request early")
                        request += part
                        if len(request) > 16384:
                            raise RuntimeError("request too long")
                    if mode == "refused":
                        raise RuntimeError("client accepted an invalid TLS peer")
                    assert request.startswith(b"GET /test HTTP/1.1\r\n"), request
                    if mode == "auth":
                        assert b"Authorization: Basic dXNlcjpwYXNzd29yZA==\r\n" in request, request
                    header = b"HTTP/1.1 200 OK\r\nConnection: close\r\n"
                    if framing == "length":
                        announced = size + 10 if mode == "incomplete" else size
                        header += b"Content-Length: %d\r\n\r\n" % announced
                        body = payload
                    elif framing == "chunked":
                        header += b"Transfer-Encoding: chunked\r\n\r\n"
                        body = b""
                        for offset in range(0, size, 301):
                            chunk = payload[offset:offset + 301]
                            body += b"%x\r\n" % len(chunk) + chunk + b"\r\n"
                        body += b"0\r\n\r\n"
                    else:
                        header += b"\r\n"
                        body = payload
                    connection.sendall(header + body)
                    if context and not (framing == "end" and mode == "incomplete"):
                        try:
                            connection.unwrap().close()
                        except (ssl.SSLError, ConnectionResetError):
                            pass  # a client with a length may close without reading our alert

        server = pool.submit(serve)
        scheme = "https" if context else "http"
        url = "%s://127.0.0.1:%d/test" % (scheme, listener.getsockname()[1])
        result = subprocess.run([str(build / "TestNetworkClient"), url, mode, str(size)],
                                cwd=build, env=env, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True, timeout=45)
        server.result(timeout=25)
        if result.returncode:
            raise RuntimeError(name + ":\n" + result.stdout)
        print(name + ": passed", flush=True)


client_case("HTTP Basic authentication", mode="auth")
client_case("HTTP binary Content-Length", size=65537)
client_case("HTTP chunked binary body", framing="chunked")
client_case("HTTP clean end", framing="end")
client_case("HTTP truncated body", mode="incomplete")
client_case("TLS ECDSA Content-Length", certificate="ec", size=65537)
client_case("TLS RSA Content-Length", certificate="rsa")
client_case("TLS chunked binary body", certificate="ec", framing="chunked")
client_case("TLS close_notify", certificate="ec", framing="end")
client_case("TLS missing close_notify", certificate="ec", framing="end", mode="incomplete")
client_case("TLS truncated body", certificate="ec", mode="incomplete")
client_case("TLS wrong host refused", certificate="wrong", mode="refused")
client_case("TLS untrusted CA refused", certificate="untrusted", mode="refused")
client_case("TLS 1.2 refused", certificate="ec", mode="refused", tls12=True)

# Interoperate in the other direction: Python's TLS client and the Oberon server.
with socket.socket() as reservation:
    reservation.bind(("127.0.0.1", 0))
    port = reservation.getsockname()[1]
process = subprocess.Popen([str(build / "TestTLSListener"), str(fixtures / "ec.pem"),
                            str(fixtures / "ec.key"), str(port)], cwd=build, env=env,
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
try:
    with selectors.DefaultSelector() as selector:
        selector.register(process.stdout, selectors.EVENT_READ)
        if not selector.select(timeout=30):
            raise RuntimeError("TLS listener did not start")
        assert process.stdout.readline().strip() == "ready"
    context = ssl.create_default_context(cafile=fixtures / "ca.pem")
    context.minimum_version = ssl.TLSVersion.TLSv1_3
    with socket.create_connection(("127.0.0.1", port), timeout=20) as connection:
        with context.wrap_socket(connection, server_hostname="localhost") as secure:
            assert secure.version() == "TLSv1.3"
            secure.sendall(b"ping")
            answer = b""
            while True:
                part = secure.recv(32)
                if not part:
                    break
                answer += part
            assert answer == b"pong", answer
            secure.unwrap().close()
    output, _ = process.communicate(timeout=20)
    assert process.returncode == 0, output
    print("Oberon TLS server / Python client: passed", flush=True)
finally:
    if process.poll() is None:
        process.kill()
        process.wait()
