"""TLS 1.3 blocking/nonblocking interoperability, fragmented wire records and rejection."""
import os
from pathlib import Path
import socket
import ssl
import shlex
import subprocess
import sys
import tempfile
import threading
import time


def certificate(path, name, host):
    cert, key = path / (name + ".crt"), path / (name + ".key")
    subprocess.run(["openssl", "req", "-x509", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:P-256",
                    "-nodes", "-keyout", str(key), "-out", str(cert), "-days", "2", "-subj", "/CN=" + host,
                    "-addext", "subjectAltName=DNS:" + host], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return cert, key


def serve(server, context, failures, reject):
    connection, _ = server.accept()
    connection.settimeout(35)
    incoming, outgoing = ssl.MemoryBIO(), ssl.MemoryBIO()
    stream = context.wrap_bio(incoming, outgoing, server_side=True)

    def drain():
        wire = outgoing.read()
        # Split both headers and payloads, unlike fragmentation of application writes alone.
        for at in range(0, len(wire), 7):
            connection.sendall(wire[at:at + 7])
            time.sleep(0.0002)

    def receive():
        data = connection.recv(16384)
        if not data:
            raise EOFError("peer closed")
        incoming.write(data)

    try:
        while True:
            try:
                stream.do_handshake()
                drain()
                break
            except ssl.SSLWantReadError:
                drain(); receive()
        got = b""
        while len(got) < 5:
            try:
                got += stream.read(5 - len(got))
            except ssl.SSLWantReadError:
                drain(); receive()
        assert got == b"hello", got
        stream.write(b"world"); drain()
    except (ssl.SSLError, EOFError, OSError) as error:
        if not reject:
            failures.append(error)
    except BaseException as error:
        failures.append(error)
    finally:
        connection.close()


def main():
    source = Path(sys.argv[1]).resolve()
    compiler = sys.argv[2] if len(sys.argv) > 2 else "voc"
    flags = shlex.split(sys.argv[3]) if len(sys.argv) > 3 else ["-m"]
    probe_source = Path(__file__).with_name("TestAsync.Mod").resolve()
    with tempfile.TemporaryDirectory(prefix="tls-async-") as temporary:
        path = Path(temporary)
        if os.environ.get("TLS_ASYNC_INSTALLED") != "1":
            subprocess.run([compiler, "-s", str(source)], cwd=path, check=True)
        records = Path(__file__).with_name("TestAsyncRecords.Mod").resolve()
        subprocess.run([compiler, *flags, str(records)], cwd=path, check=True)
        runtime_env = {**os.environ}
        runtime_env["VOC_MODULE_PATH"] = os.pathsep.join(filter(None, (str(path), runtime_env.get("VOC_MODULE_PATH"))))
        subprocess.run([str(path / "TestAsyncRecords")], cwd=path, env=runtime_env, check=True, timeout=15)
        subprocess.run([compiler, *flags, str(probe_source)], cwd=path, check=True)
        cert, key = certificate(path, "server", "localhost")
        wrong, _ = certificate(path, "other", "localhost")
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.minimum_version = ssl.TLSVersion.TLSv1_3
        context.load_cert_chain(cert, key)
        for curve, mode, host, trust in (
            ("X25519", "async", "localhost", cert),
            ("prime256v1", "async", "localhost", cert),
            ("X25519", "blocking", "localhost", cert),
            ("X25519", "reject", "127.0.0.1", cert),
            ("X25519", "reject", "localhost", wrong),
        ):
            context.set_ecdh_curve(curve)
            with socket.socket() as server:
                server.bind(("127.0.0.1", 0)); server.listen(); server.settimeout(35)
                failures = []
                worker = threading.Thread(target=serve, args=(server, context, failures, mode == "reject"), daemon=True)
                worker.start()
                result = subprocess.run([str(path / "TestAsync"), host, str(server.getsockname()[1]), mode],
                                        env={**runtime_env, "SSL_CERT_FILE": str(trust)},
                                        capture_output=True, text=True, timeout=40)
                worker.join(3)
                assert not worker.is_alive(), "server did not finish"
                assert result.returncode == 0, (result.returncode, result.stdout, result.stderr)
                assert not failures, failures
                print("PASS:", curve, mode, host)


if __name__ == "__main__":
    main()
