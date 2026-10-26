"""Exercise VOC XMPP negotiation against a local Python/OpenSSL peer."""

import base64
import concurrent.futures
import os
from pathlib import Path
import socket
import ssl
import subprocess
import sys
import xml.etree.ElementTree as ET


BUILD = Path(sys.argv[1]).resolve()
FIXTURES = BUILD / "xmpp-loopback"
FIXTURES.mkdir(exist_ok=True)
ENV = {**os.environ, "SSL_CERT_FILE": str(FIXTURES / "ca.pem")}
STREAMS = "http://etherx.jabber.org/streams"
CLIENT = "jabber:client"
TLS = "urn:ietf:params:xml:ns:xmpp-tls"
SASL = "urn:ietf:params:xml:ns:xmpp-sasl"
BIND = "urn:ietf:params:xml:ns:xmpp-bind"


def openssl(*args):
    result = subprocess.run(["openssl", *args], cwd=FIXTURES,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            text=True, timeout=30)
    if result.returncode:
        raise RuntimeError(result.stdout)


openssl("req", "-x509", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:P-256",
        "-nodes", "-keyout", "ca.key", "-out", "ca.pem", "-days", "2",
        "-subj", "/CN=VOC XMPP loopback CA", "-addext", "basicConstraints=critical,CA:TRUE",
        "-addext", "keyUsage=critical,keyCertSign,cRLSign")
for name, san in [("server", "DNS:localhost"), ("wrong", "DNS:wrong.test"),
                  ("idn", "DNS:xn--cbbu1a.xn--y9a3aq")]:
    openssl("req", "-new", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:P-256",
            "-nodes", "-keyout", name + ".key", "-out", name + ".csr", "-subj", "/CN=localhost")
    (FIXTURES / (name + ".ext")).write_text(
        "basicConstraints=critical,CA:FALSE\nkeyUsage=critical,digitalSignature\n"
        "extendedKeyUsage=serverAuth\nsubjectAltName=" + san + "\n")
    openssl("x509", "-req", "-in", name + ".csr", "-CA", "ca.pem", "-CAkey", "ca.key",
            "-CAcreateserial", "-out", name + ".pem", "-days", "2", "-extfile", name + ".ext")
openssl("req", "-x509", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:P-256",
        "-nodes", "-keyout", "untrusted.key", "-out", "untrusted.pem", "-days", "2",
        "-subj", "/CN=localhost", "-addext", "subjectAltName=DNS:localhost")


class Peer:
    """Receive completed client elements under one open XML stream."""

    def __init__(self, connection, domain="localhost"):
        self.connection = connection
        self.parser = ET.XMLPullParser(events=("start", "end"))
        self.depth = 0
        self.domain = domain

    def event(self):
        while True:
            data = self.connection.recv(1)
            if not data:
                raise EOFError("client ended the XML stream early")
            self.parser.feed(data)
            self.parser.flush()
            for event, element in self.parser.read_events():
                if event == "start":
                    self.depth += 1
                    if self.depth == 1:
                        assert element.tag == f"{{{STREAMS}}}stream"
                        assert element.get("to") == self.domain
                        assert element.get("version") == "1.0"
                        return element
                else:
                    self.depth -= 1
                    if self.depth <= 1:
                        return element


def header(prefix, domain="localhost"):
    return (f'<{prefix}:stream xmlns:{prefix}="{STREAMS}" xmlns="{CLIENT}" '
            f'from="{domain}" id="loopback" version="1.0" xml:lang="hy">')


def send(connection, text, fragment=0):
    data = text.encode("utf-8")
    if fragment:
        for offset in range(0, len(data), fragment):
            connection.sendall(data[offset:offset + fragment])
    else:
        connection.sendall(data)


def case(mode, direct=False, certificate="server", tls12=False, domain="localhost"):
    wire_domain = domain.encode("idna").decode("idna")
    server_domain = domain if mode == "alabel" else wire_domain
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(FIXTURES / (certificate + ".pem"), FIXTURES / (certificate + ".key"))
    context.minimum_version = context.maximum_version = (
        ssl.TLSVersion.TLSv1_2 if tls12 else ssl.TLSVersion.TLSv1_3)
    context.set_ciphers("ECDHE-ECDSA-AES128-GCM-SHA256")
    def check_sni(connection, name, context):
        assert name == wire_domain.encode("idna").decode(), "wrong TLS service identity"
    context.set_servername_callback(check_sni)
    with socket.socket() as listener, concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
        listener.bind(("127.0.0.1", 0))
        listener.listen(1)
        listener.settimeout(15)

        def serve():
            connection, _ = listener.accept()
            connection.settimeout(15)
            try:
                if not direct:
                    peer = Peer(connection, wire_domain)
                    peer.event()
                    if mode == "read-stall":
                        assert connection.recv(4096) == b"", "client failed to time out"
                        return
                    if mode == "no-tls":
                        send(connection, header("s", server_domain) + '<s:features/>')
                        assert connection.recv(4096) == b"", "credentials sent without TLS"
                        return
                    send(connection, header("s", server_domain) +
                         f'<s:features><starttls xmlns="{TLS}"><required/></starttls></s:features>', 7)
                    assert peer.event().tag == f"{{{TLS}}}starttls"
                    send(connection, f'<proceed xmlns="{TLS}"/>' + ("injected" if mode == "pipelined" else ""))
                    if mode == "pipelined":
                        data = connection.recv(4096)
                        assert not data or data.startswith(b"\x16"), "unexpected bytes after injected plaintext"
                        return
                if mode == "tls-stall":
                    data = connection.recv(4096)
                    assert data.startswith(b"\x16"), "client did not start TLS"
                    while data:
                        data = connection.recv(4096)
                    return
                try:
                    connection = context.wrap_socket(connection, server_side=True)
                except (ssl.SSLError, ConnectionResetError):
                    if mode in {"wrong-host", "untrusted", "tls12"}:
                        return
                    raise
                peer = Peer(connection, wire_domain)
                try:
                    peer.event()
                except (EOFError, ssl.SSLError):
                    if mode in {"wrong-host", "untrusted", "tls12"}:
                        return
                    raise
                assert mode not in {"wrong-host", "untrusted", "tls12"}, "invalid TLS peer was accepted"
                send(connection, header("t", server_domain) +
                     f'<t:features><mechanisms xmlns="{SASL}"><mechanism>PLAIN</mechanism></mechanisms></t:features>')
                auth = peer.event()
                assert auth.tag == f"{{{SASL}}}auth" and auth.get("mechanism") == "PLAIN"
                actual = base64.b64decode(auth.text, validate=True)
                expected = b"\0" + "օգտվող".encode() + b"\0" + "գաղտնի😀".encode()
                assert actual == expected, "SASL UTF-8 credentials differ"
                if mode == "auth-refused":
                    send(connection, f'<failure xmlns="{SASL}"><not-authorized/></failure>')
                    return
                send(connection, f'<success xmlns="{SASL}"/>')
                peer = Peer(connection, wire_domain)
                peer.event()
                if mode == "no-bind":
                    send(connection, header("q", server_domain) + '<q:features/>')
                    return
                send(connection, header("q", server_domain) + f'<q:features><bind xmlns="{BIND}"/></q:features>')
                request = peer.event()
                assert request.tag == f"{{{CLIENT}}}iq" and request.get("type") == "set"
                assert request.find(f"{{{BIND}}}bind/{{{BIND}}}resource").text == "մուտք😀"
                jid = f"օգտվող@{server_domain}/մուտք😀"
                if mode == "bind-wrong":
                    jid = "օգտվող@wrong.test/մուտք😀"
                identifier = "wrong-id" if mode == "bad-id" else request.get("id")
                send(connection, f'<iq id="{identifier}" type="result"><bind xmlns="{BIND}"><jid>{jid}</jid></bind></iq>')
                if mode in {"bind-wrong", "bad-id"}:
                    return
                if mode == "extensions":
                    request = peer.event()
                    assert request.find("{urn:xmpp:ping}ping") is not None
                    assert request.get("type") == "get"
                    for identifier, uri, child in (
                        ("peer-ping", "urn:xmpp:ping", "ping"),
                        ("peer-version", "jabber:iq:version", "query"),
                        ("peer-disco", "http://jabber.org/protocol/disco#info", "query"),
                    ):
                        send(connection, f'<iq type="get" id="{identifier}"><{child} xmlns="{uri}"/></iq>')
                        response = peer.event()
                        assert response.get("type") == "result" and response.get("id") == identifier
                        if identifier == "peer-version":
                            assert response.find("{jabber:iq:version}query/{jabber:iq:version}name").text == "VOC Հայերեն😀"
                        if identifier == "peer-disco":
                            assert response.find("{http://jabber.org/protocol/disco#info}query") is not None
                    send(connection, f'<iq type="result" id="{request.get("id")}"/>')
                if mode == "roster-pep":
                    roster = "jabber:iq:roster"
                    pubsub = "http://jabber.org/protocol/pubsub"
                    event = pubsub + "#event"
                    node, item_id = "urn:xmpp:microblog:0", "գրառում😀"
                    friend = "friend@ծոց.հայ"
                    request = peer.event()
                    assert request.get("type") == "get" and request.find(f"{{{roster}}}query") is not None
                    send(connection, f'<iq type="result" id="{request.get("id")}"><query xmlns="{roster}">'
                         f'<item jid="{friend}" subscription="both"/></query></iq>', 3)
                    for sender, identifier in (("attacker@example.net", "spoof"), (f"օգտվող@{server_domain}", "push")):
                        send(connection, f'<iq type="set" id="{identifier}" from="{sender}"><query xmlns="{roster}">'
                             f'<item jid="{friend}" name="Ընկեր😀" subscription="both"/></query></iq>', 5)
                    response = peer.event()
                    assert response.get("id") == "push" and response.get("type") == "result"
                    request = peer.event()
                    contact = request.find(f"{{{roster}}}query/{{{roster}}}item")
                    assert request.get("type") == "set" and contact.get("jid") == friend
                    assert contact.get("name") == "Ընկեր😀" and contact.find(f"{{{roster}}}group").text == "Ընկերներ"
                    send(connection, f'<iq type="result" id="{request.get("id")}"/>')
                    request = peer.event()
                    publish = request.find(f"{{{pubsub}}}pubsub/{{{pubsub}}}publish")
                    assert request.get("type") == "set" and publish.get("node") == node
                    assert publish.find(f"{{{pubsub}}}item").get("id") == item_id
                    send(connection, f'<iq type="result" id="{request.get("id")}"><pubsub xmlns="{pubsub}">'
                         f'<publish node="{node}"><item id="{item_id}"/></publish></pubsub></iq>')
                    request = peer.event()
                    items = request.find(f"{{{pubsub}}}pubsub/{{{pubsub}}}items")
                    assert request.get("type") == "get" and request.get("to") == friend
                    assert items.get("node") == node and items.get("max_items") == "1"
                    assert items.find(f"{{{pubsub}}}item").get("id") == item_id
                    send(connection, f'<iq type="result" from="{friend}" id="{request.get("id")}">'
                         f'<pubsub xmlns="{pubsub}"><items node="{node}"><item id="{item_id}">'
                         '<entry xmlns="http://www.w3.org/2005/Atom">Ընկեր😀</entry></item></items></pubsub></iq>', 7)
                    send(connection, f'<message type="headline" from="{friend}"><event xmlns="{event}">'
                         f'<items node="{node}"><item id="{item_id}"><entry xmlns="http://www.w3.org/2005/Atom"/>'
                         '</item><retract id="old"/></items></event></message>', 3)
                    request = peer.event()
                    retract = request.find(f"{{{pubsub}}}pubsub/{{{pubsub}}}retract")
                    assert request.get("type") == "set" and retract.get("node") == node and retract.get("notify") == "1"
                    assert retract.find(f"{{{pubsub}}}item").get("id") == item_id
                    send(connection, f'<iq type="result" id="{request.get("id")}"/>')
                message = peer.event()
                assert message.tag == f"{{{CLIENT}}}message"
                assert message.find(f"{{{CLIENT}}}body").text == "Բարեւ 😀"
                send(connection, '<message><body>Բարեւ 😀</body></message>', 3)
                assert peer.event().tag == f"{{{STREAMS}}}stream"
                send(connection, '</q:stream>')
                try:
                    connection.unwrap().close()
                except (ssl.SSLError, ConnectionResetError):
                    pass
            finally:
                connection.close()

        server = pool.submit(serve)
        result = subprocess.run([str(BUILD / "TestXmppNetwork"), str(listener.getsockname()[1]),
                                 mode, "yes" if direct else "no", domain], cwd=BUILD, env=ENV,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=45)
        if result.returncode:
            raise RuntimeError(mode + ":\n" + result.stdout)
        server.result(timeout=20)
        print(f"XMPP {mode} ({'direct TLS' if direct else 'STARTTLS'}): passed", flush=True)


if __name__ == "__main__":
    case("starttls")
    case("direct", direct=True)
    case("no-tls")
    case("pipelined")
    case("wrong-host", certificate="wrong")
    case("untrusted", certificate="untrusted")
    case("tls12", tls12=True)
    case("wrong-host", direct=True, certificate="wrong")
    case("untrusted", direct=True, certificate="untrusted")
    case("auth-refused")
    case("no-bind")
    case("bind-wrong")
    case("bad-id")
    case("read-stall")
    case("tls-stall")
    case("tls-stall", direct=True)
    case("unicode", certificate="idn", domain="ծոց.հայ")
    case("unicode", direct=True, certificate="idn", domain="ԾՈՑ.ՀԱՅ")
    case("alabel", certificate="idn", domain="xn--cbbu1a.xn--y9a3aq")
    case("wrong-host", certificate="server", domain="ծոց.հայ")
    case("extensions")
    case("extensions", direct=True, certificate="idn", domain="ծոց.հայ")
    case("roster-pep")
    case("roster-pep", direct=True, certificate="idn", domain="ծոց.հայ")
