"""Exercise caller-driven XMPP over nonblocking local TCP and verified TLS."""
import base64
import concurrent.futures
import os
from pathlib import Path
import socket
import ssl
import subprocess
import sys
import xml.etree.ElementTree as ET

build = Path(sys.argv[1]).resolve()
fixtures = build / "xmpp-async-loopback"
fixtures.mkdir(exist_ok=True)
environment = {**os.environ, "SSL_CERT_FILE": str(fixtures / "ca.pem")}
bridge = len(sys.argv) > 2
streams = "http://etherx.jabber.org/streams"
client = "jabber:client"
sasl = "urn:ietf:params:xml:ns:xmpp-sasl"
tls = "urn:ietf:params:xml:ns:xmpp-tls"
bind = "urn:ietf:params:xml:ns:xmpp-bind"


def openssl(*arguments):
    subprocess.run(["openssl", *arguments], cwd=fixtures, check=True,
                   stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30)


openssl("req", "-x509", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:P-256",
        "-nodes", "-keyout", "ca.key", "-out", "ca.pem", "-days", "2",
        "-subj", "/CN=XMPP async fixture CA", "-addext", "basicConstraints=critical,CA:TRUE",
        "-addext", "keyUsage=critical,keyCertSign,cRLSign")
for name, san in [("server", "DNS:localhost,DNS:xn--cbbu1a.xn--y9a3aq"), ("wrong", "DNS:wrong.test")]:
    openssl("req", "-new", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:P-256",
            "-nodes", "-keyout", name + ".key", "-out", name + ".csr", "-subj", "/CN=localhost")
    (fixtures / (name + ".ext")).write_text(
        "basicConstraints=critical,CA:FALSE\nkeyUsage=critical,digitalSignature\n"
        "extendedKeyUsage=serverAuth\nsubjectAltName=" + san + "\n")
    openssl("x509", "-req", "-in", name + ".csr", "-CA", "ca.pem", "-CAkey", "ca.key",
            "-CAcreateserial", "-out", name + ".pem", "-days", "2", "-extfile", name + ".ext")
openssl("req", "-x509", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:P-256",
        "-nodes", "-keyout", "untrusted.key", "-out", "untrusted.pem", "-days", "2",
        "-subj", "/CN=localhost", "-addext", "subjectAltName=DNS:localhost")


class Peer:
    def __init__(self, connection):
        self.connection = connection
        self.parser = ET.XMLPullParser(events=("start", "end"))
        self.depth = 0

    def event(self):
        while True:
            data = self.connection.recv(1)
            if not data:
                raise EOFError("XMPP stream ended early")
            self.parser.feed(data)
            self.parser.flush()
            for event, item in self.parser.read_events():
                if event == "start":
                    self.depth += 1
                    if self.depth == 1:
                        return item
                else:
                    self.depth -= 1
                    if self.depth <= 1:
                        return item


def header(domain):
    return f'<s:stream xmlns:s="{streams}" xmlns="{client}" from="{domain}" version="1.0">'


def send(connection, text):
    data = text.encode()
    for position in range(0, len(data), 7):
        connection.sendall(data[position:position + 7])


def serve(listener, mode, direct, domain):
    connection, _ = listener.accept()
    connection.settimeout(10)
    try:
        if mode == "cancel":
            try:
                while connection.recv(4096):
                    pass
            except ConnectionResetError:
                pass
            return
        if mode == "eof":
            return
        if mode == "stall":
            while connection.recv(4096):
                pass
            return
        if not direct:
            peer = Peer(connection)
            assert peer.event().get("to") == domain
            send(connection, header(domain) + f'<s:features><starttls xmlns="{tls}"/></s:features>')
            assert peer.event().tag == f"{{{tls}}}starttls"
            if mode == "bad-tail":
                connection.sendall(f'<proceed xmlns="{tls}"/><message><body>extra plaintext</body></message>'.encode())
                received = b""
                try:
                    while data := connection.recv(4096):
                        received += data
                except ConnectionResetError:
                    pass
                assert b"<auth" not in received
                return
            send(connection, f'<proceed xmlns="{tls}"/>')
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.minimum_version = context.maximum_version = ssl.TLSVersion.TLSv1_3
        name = "wrong" if mode == "wrong-host" else "untrusted" if mode == "untrusted" else "server"
        context.load_cert_chain(fixtures / (name + ".pem"), fixtures / (name + ".key"))
        try:
            connection = context.wrap_socket(connection, server_side=True)
        except (ssl.SSLError, ConnectionResetError):
            if mode in ("wrong-host", "untrusted"):
                return
            raise
        peer = Peer(connection)
        if mode in ("wrong-host", "untrusted"):
            assert connection.recv(4096) == b""
            return
        assert peer.event().get("to") == domain
        send(connection, header(domain) + f'<s:features><mechanisms xmlns="{sasl}"><mechanism>PLAIN</mechanism></mechanisms></s:features>')
        auth = peer.event()
        assert auth.tag == f"{{{sasl}}}auth"
        assert base64.b64decode(auth.text) == "\0օգտվող\0գաղտնիք😀".encode()
        if mode == "auth-fail":
            send(connection, f'<failure xmlns="{sasl}"><not-authorized/></failure>')
            return
        send(connection, f'<success xmlns="{sasl}"/>')
        peer = Peer(connection)
        assert peer.event().get("to") == domain
        send(connection, header(domain) + f'<s:features><bind xmlns="{bind}"/></s:features>')
        request = peer.event()
        assert request.find(f"{{{bind}}}bind/{{{bind}}}resource").text == "մուտք😀"
        send(connection, f'<iq type="result" id="{request.get("id")}"><bind xmlns="{bind}"><jid>օգտվող@{domain}/մուտք😀</jid></bind></iq>')
        message = peer.event()
        if bridge:
            assert message.tag == f"{{{client}}}presence"
            message = peer.event()
        assert message.find(f"{{{client}}}body").text == "Բարեւ <աշխարհ> & 😀"
        send(connection, '<message from="peer@localhost/r"><body>Բարեւ &lt;աշխարհ&gt; &amp; 😀</body></message>')
        if bridge:
            send(connection, "</s:stream>")
            assert peer.event().tag == f"{{{streams}}}stream"
        else:
            assert peer.event().tag == f"{{{streams}}}stream"
            send(connection, "</s:stream>")
    finally:
        connection.close()


cases = [(direct, mode, "localhost") for direct in (False, True)
         for mode in ("success", "wrong-host", "untrusted", "auth-fail", "stall", "cancel", "eof")]
cases += [(direct, "success", "ծոց.հայ") for direct in (False, True)]
cases += [(False, "bad-tail", "localhost")]
for direct, mode, domain in cases:
    with socket.socket() as listener:
        listener.settimeout(10)
        listener.bind(("127.0.0.1", 0))
        listener.listen(1)
        with concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
            server = pool.submit(serve, listener, mode, direct, domain)
            command = [str(Path(sys.argv[2]).resolve()) if bridge else str(build / "TestXmppAsync"),
                       str(listener.getsockname()[1]), mode, "yes" if direct else "no", domain]
            if bridge:
                command.append(str(Path(sys.argv[3]).resolve()))
            result = subprocess.run(command, env=environment, text=True, capture_output=True, timeout=20)
            server.result(timeout=15)
        assert result.returncode == 0, result.stdout + result.stderr
        print(result.stdout.strip(), "(direct TLS," if direct else "(STARTTLS,", domain + ")")
