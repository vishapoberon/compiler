"""Optional application tests: generated fixtures and loopback connections only."""
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
from email.utils import parsedate_to_datetime
import os
from pathlib import Path
import selectors
import shlex
import socket
import ssl
import stat
import subprocess
import sys
import tempfile
import time


build = Path(sys.argv[1]).resolve()
profile = sys.argv[2]
hresh = Path(sys.argv[3]).resolve()
fixtures = Path(tempfile.mkdtemp(prefix="fixtures with spaces-", dir=build))
home = fixtures / "home"
home.mkdir(exist_ok=True)
site = fixtures / "site"
site.mkdir(exist_ok=True)
(site / "listing").mkdir(exist_ok=True)
(site / "listing/a&b.txt").write_text("entry\n")
(site / "listing/.hidden").write_text("hidden\n")
(site / "index.gmi").write_bytes(b"# VOC Gemini\n")
(site / "index.html").write_bytes(b"<h1>VOC HTTP</h1>\n")
(site / ".secret").write_text("do not serve\n")
payload = bytes((i * 7 + i // 251) % 256 for i in range(65537))
(site / "bytes.bin").write_bytes(payload)
os.utime(site / "index.html", (946771200, 946771200))
for name in ["cert", "rotated"]:
    result = subprocess.run(["openssl", "req", "-x509", "-newkey", "ec", "-pkeyopt",
                             "ec_paramgen_curve:P-256", "-nodes", "-keyout", name + ".key",
                             "-out", name + ".pem", "-days", "2", "-subj", "/CN=localhost",
                             "-addext", "subjectAltName=DNS:localhost,IP:127.0.0.1"], cwd=fixtures,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)
    assert result.returncode == 0, result.stdout
(fixtures / "empty-ca.pem").write_text("")
env = os.environ.copy()
env.update(HOME=str(home), XDG_CONFIG_HOME=str(home / "config"),
           SSL_CERT_FILE=str(fixtures / "empty-ca.pem"), TZ="Pacific/Honolulu")


def command(application, arguments):
    if profile == "conventional":
        return [str(build / application / application), *arguments]
    action = "Serve" if application != "dcs" else "Get"
    if application == "dcs" and arguments and arguments[0] in ["NewIdent", "Idents", "Help"]:
        action, *arguments = arguments
    text = application + "." + action
    for arg in arguments:
        text += " " + shlex.quote(arg)
    return [str(hresh / "hresh"), "-P" + str(build / application) + ":" + str(hresh / "modules/2"), text]


def dcs(*arguments, input=None):
    result = subprocess.run(command("dcs", list(arguments)), cwd=fixtures, env=env, input=input,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=60)
    assert result.returncode == 0, result.stdout
    return result.stdout


def free_port():
    with socket.socket() as reservation:
        reservation.bind(("127.0.0.1", 0))
        return reservation.getsockname()[1]


@contextmanager
def server(application, arguments, count, port=None, certificate="cert", configuration=None):
    port = port or free_port()
    if application == "agena":
        if configuration:
            args = ["/config", str(configuration), str(port), *arguments]
        else:
            args = [str(site), str(fixtures / (certificate + ".pem")),
                    str(fixtures / (certificate + ".key")), str(port), *arguments]
    else:
        args = [str(site), str(port), *arguments]
    args += ["/listen", "127.0.0.1", "/n", str(count), "/timeout", "10"]
    if not configuration:
        args += ["/host", "localhost"]
    process = subprocess.Popen(command(application, args), cwd=fixtures, env=env,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    prefix = []
    try:
        with selectors.DefaultSelector() as selector:
            selector.register(process.stdout, selectors.EVENT_READ)
            deadline = time.monotonic() + 30
            while time.monotonic() < deadline:
                assert selector.select(timeout=10), "server startup timed out: " + "".join(prefix)
                line = process.stdout.readline()
                prefix.append(line)
                assert line, "server failed: " + "".join(prefix)
                if application + ": serving" in line or (application == "agena" and "agena: listening on" in line):
                    break
            else:
                raise AssertionError("server did not become ready")
        yield port
        output, _ = process.communicate(timeout=45)
        assert process.returncode == 0, "".join(prefix) + output
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()


# Peer trust is tested in the library suite and below with TOFU/pins. This
# context is deliberately unauthenticated for generated loopback-only fixtures.
context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
context.check_hostname = False
context.verify_mode = ssl.CERT_NONE
context.minimum_version = ssl.TLSVersion.TLSv1_3


def request(port, data, secure=True, server_name="localhost"):
    with socket.create_connection(("127.0.0.1", port), timeout=30) as connection:
        if secure:
            connection = context.wrap_socket(connection, server_hostname=server_name)
        with connection:
            connection.sendall(data)
            response = b""
            while True:
                part = connection.recv(32768)
                if not part:
                    break
                response += part
            return response


with server("agena", [], 14) as port:
    def gemini(path, status, host="localhost"):
        response = request(port, ("gemini://%s:%d%s\r\n" % (host, port, path)).encode())
        head, body = response.split(b"\r\n", 1)
        assert int(head[:2]) == status, (path, response[:200])
        return body

    assert gemini("/", 20) == b"# VOC Gemini\n"
    assert gemini("/bytes.bin", 20) == payload
    gemini("/.secret", 51)
    gemini("/../index.gmi", 51)
    gemini("/%2e%2e/index.gmi", 51)
    gemini("/missing", 51)
    gemini("/listing", 31)
    listing = gemini("/listing/", 20)
    assert b"a%26b.txt" in listing and b".hidden" not in listing, listing
    gemini("/", 53, "wrong.test")
    assert request(port, b"bad request\r\n").startswith(b"59 ")
    url = "gemini://localhost:%d/index.gmi" % port
    target = fixtures / "saved body.gmi"
    output = dcs(url, "/tofu", "/output", str(target))
    assert "status:   20" in output and "wrote:" in output, output
    assert target.read_bytes() == b"# VOC Gemini\n"
    pins = (home / ".gemini_hosts").read_bytes()
    output = dcs(url, "/tofu")
    assert "VOC Gemini" in output and "error:" not in output, output
    assert (home / ".gemini_hosts").read_bytes() == pins
    output = dcs(url, "/input", "-", "/tofu", input="two words")
    assert "?two%20words" in output and "VOC Gemini" in output, output
    output = dcs(url, "/save", "/tofu")
    assert "wrote:" in output and (fixtures / "index.gmi").read_bytes() == b"# VOC Gemini\n", output
    output = dcs(url, "/save", "/tofu")
    assert "exists" in output and "wrote:" not in output, output
print("Agena serving, traversal refusal, listings, DCS downloads and TOFU: passed", flush=True)

# Reuse the host:port with a different key: the recorded key must be refused.
with server("agena", [], 1, port=port, certificate="rotated"):
    output = dcs(url, "/tofu")
    assert "error:" in output and "VOC Gemini" not in output, output
print("DCS TOFU key change refused: passed", flush=True)

with server("agena", [], 3) as port:
    url = "gemini://localhost:%d/index.gmi" % port
    fingerprint = dcs(url, "/fingerprint").strip().splitlines()[-1]
    assert len(fingerprint) == 64, fingerprint
    output = dcs(url, "/pin", fingerprint)
    assert "VOC Gemini" in output and "error:" not in output, output
    output = dcs(url, "/pin", "0" * 64)
    assert "error:" in output and "VOC Gemini" not in output, output
print("DCS certificate fingerprint and pin: passed", flush=True)

(site / "one.gmi").write_text("default host\n")
(site / "two.gmi").write_text("localhost host\n")
(site / "x.zq").write_text("custom type\n")
configuration = fixtures / "agena.toml"
text = ""
for host, index in [("default.test", "one.gmi"), ("localhost", "two.gmi")]:
    text += ('[[server]]\nname = "%s"\nroot = "%s"\nindex = "%s"\n'
             'cert = "%s"\nkey = "%s"\n\n' %
             (host, site, index, fixtures / "cert.pem", fixtures / "cert.key"))
configuration.write_text(text + '[types]\nzq = "text/x-test"\n')
with server("agena", [], 5, configuration=configuration) as port:
    def virtual(host, name, path="/"):
        return request(port, ("gemini://%s:%d%s\r\n" % (host, port, path)).encode(), server_name=name)
    assert virtual("localhost", "localhost").endswith(b"localhost host\n")
    assert virtual("default.test", "default.test").endswith(b"default host\n")
    assert virtual("localhost", None).endswith(b"localhost host\n")
    assert virtual("localhost", "localhost", "/x.zq") == b"20 text/x-test\r\ncustom type\n"
    assert virtual("wrong.test", "localhost").startswith(b"53 ")
print("Agena TOML configuration, SNI/URL virtual hosts and custom types: passed", flush=True)

output = dcs("NewIdent", "Ada Example", "ada@example.org", "/years", "2")
assert "Ada Example" in output and "error:" not in output, output
output = dcs("Idents")
assert "Ada Example" in output, output
identities = home / "config/dcs/idents"
assert stat.S_IMODE(identities.stat().st_mode) == 0o700
assert len(list(identities.glob("*.key"))) == 1
for key in identities.glob("*.key"):
    assert stat.S_IMODE(key.stat().st_mode) == 0o600
print("DCS identities, private permissions and argv with spaces: passed", flush=True)

# A small Spartan peer checks the exact request and input framing.
with socket.socket() as listener, ThreadPoolExecutor(max_workers=1) as pool:
    listener.bind(("127.0.0.1", 0)); listener.listen(1); listener.settimeout(30)
    def spartan():
        connection, _ = listener.accept()
        with connection:
            connection.settimeout(30)
            data = b""
            while b"\r\n" not in data:
                data += connection.recv(4096)
            header, body = data.split(b"\r\n", 1)
            assert header == b"localhost /query 11", header
            while len(body) < 11:
                body += connection.recv(4096)
            assert body == b"hello world", body
            connection.sendall(b"2 text/plain\r\nhello world\n")
    future = pool.submit(spartan)
    output = dcs("spartan://localhost:%d/query" % listener.getsockname()[1], "hello world")
    future.result(timeout=30)
    assert "status:   2" in output and "hello world" in output, output
print("DCS Spartan framing: passed", flush=True)

for secure in [False, True]:
    options = ["/tls", str(fixtures / "cert.pem"), str(fixtures / "cert.key")] if secure else []
    with server("cobweb", options, 11) as port:
        def http(method, path, status, host="localhost"):
            response = request(port, ("%s %s HTTP/1.1\r\nHost: %s\r\n\r\n" %
                                      (method, path, host)).encode(), secure)
            head, body = response.split(b"\r\n\r\n", 1)
            lines = head.split(b"\r\n")
            assert int(lines[0].split()[1]) == status, (path, response[:200])
            fields = dict(line.lower().split(b": ", 1) for line in lines[1:])
            if method != "HEAD":
                assert len(body) == int(fields[b"content-length"]), (fields, len(body))
            else:
                assert body == b""
            return fields, body
        fields, body = http("GET", "/", 200)
        assert body == b"<h1>VOC HTTP</h1>\n", body
        assert fields[b"last-modified"] == b"sun, 02 jan 2000 00:00:00 gmt", fields
        assert abs(parsedate_to_datetime(fields[b"date"].decode()).timestamp() - time.time()) < 30
        fields, body = http("HEAD", "/", 200)
        assert int(fields[b"content-length"]) == len(b"<h1>VOC HTTP</h1>\n")
        assert http("GET", "/bytes.bin", 200)[1] == payload
        assert http("GET", "/listing", 301)[0][b"location"] == b"/listing/"
        listing = http("GET", "/listing/", 200)[1]
        assert b"a%26b.txt" in listing and b".hidden" not in listing, listing
        http("GET", "/.secret", 404)
        http("GET", "/../index.html", 404)
        http("GET", "/%2e%2e/index.html", 404)
        http("GET", "/missing", 404)
        http("GET", "/", 421, "wrong.test")
        http("POST", "/", 405)
    print("Cobweb %s files, HEAD, UTC dates, listings and refusal cases: passed" %
          ("HTTPS" if secure else "HTTP"), flush=True)

if profile == "native":
    paths = [str(build / app) for app in ["dcs", "agena", "cobweb"]]
    paths.append(str(hresh / "modules/2"))
    lines = []
    for _ in range(2):
        for application in ["agena", "cobweb"]:
            arguments = [str(site)]
            if application == "agena":
                arguments += [str(fixtures / "cert.pem"), str(fixtures / "cert.key")]
            arguments += [str(free_port()), "/n", "0", "/listen", "127.0.0.1"]
            lines.append(application + ".Serve " + " ".join(shlex.quote(arg) for arg in arguments))
            lines.append("system.Free " + application)
        lines += ["dcs.Help", "system.Free dcs"]
    result = subprocess.run([str(hresh / "hresh"), "-P" + ":".join(paths)],
                            input="\n".join(lines + ["quit", ""]), text=True, cwd=fixtures, env=env,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
    assert result.returncode == 0, result.stdout
    for application in ["agena", "cobweb", "dcs"]:
        assert result.stdout.count(application + ": freed") == 2, result.stdout
    assert "cannot listen" not in result.stdout, result.stdout
    print("Same-shell application cleanup, free and reload: passed", flush=True)
print("Optional network application tests passed (" + profile + ")", flush=True)
