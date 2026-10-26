"""Exercise PEP publishing over a local verified TLS connection."""

import base64
import concurrent.futures
from datetime import datetime, timezone
import os
from pathlib import Path
import runpy
import socket
import ssl
import subprocess
import sys
import uuid
import xml.etree.ElementTree as ET

build = Path(sys.argv[1]).resolve()
shared = runpy.run_path(sys.argv[2], run_name="xmpp_test_peer")
Peer, send, header = (shared[name] for name in ("Peer", "send", "header"))
fixtures = shared["FIXTURES"]
env = {key: value for key, value in shared["ENV"].items() if not key.startswith("XMPP_")}
CLIENT, TLS, SASL, BIND = (shared[name] for name in ("CLIENT", "TLS", "SASL", "BIND"))
PUBSUB = "http://jabber.org/protocol/pubsub"
ATOM = "http://www.w3.org/2005/Atom"
NODE = "urn:xmpp:microblog:0"
text = "Բարեւ 😀 <tag> & text"


def case(mode, direct=False, domain="localhost", certificate="server"):
    canonical = domain.encode("idna").decode("idna")
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.minimum_version = context.maximum_version = ssl.TLSVersion.TLSv1_3
    context.load_cert_chain(fixtures / f"{certificate}.pem", fixtures / f"{certificate}.key")
    def sni(connection, name, context):
        assert name == canonical.encode("idna").decode()
    context.set_servername_callback(sni)
    with socket.socket() as listener, concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
        listener.bind(("127.0.0.1", 0))
        listener.listen(1)
        listener.settimeout(5)

        def serve():
            connection, _ = listener.accept()
            connection.settimeout(5)
            try:
                if not direct:
                    peer = Peer(connection, canonical)
                    peer.event()
                    if mode == "no-tls":
                        send(connection, header("s", canonical) + '<s:features/>')
                        return
                    send(connection, header("s", canonical) + f'<s:features><starttls xmlns="{TLS}"/></s:features>')
                    assert peer.event().tag == f"{{{TLS}}}starttls"
                    send(connection, f'<proceed xmlns="{TLS}"/>')
                try:
                    connection = context.wrap_socket(connection, server_side=True)
                except ssl.SSLError:
                    if mode in {"wrong-host", "untrusted"}:
                        return
                    raise
                assert mode not in {"wrong-host", "untrusted"}
                peer = Peer(connection, canonical)
                peer.event()
                send(connection, header("s", canonical) + f'<s:features><mechanisms xmlns="{SASL}"><mechanism>PLAIN</mechanism></mechanisms></s:features>')
                auth = peer.event()
                assert auth.tag == f"{{{SASL}}}auth"
                assert base64.b64decode(auth.text, validate=True) == b"\0" + "օբերոն".encode() + b"\0" + "dummy-գաղտնի😀".encode()
                if mode == "auth-refused":
                    send(connection, f'<failure xmlns="{SASL}"><not-authorized/></failure>')
                    return
                send(connection, f'<success xmlns="{SASL}"/>')
                peer = Peer(connection, canonical)
                peer.event()
                send(connection, header("s", canonical) + f'<s:features><bind xmlns="{BIND}"/></s:features>')
                bind = peer.event()
                assert bind.find(f"{{{BIND}}}bind/{{{BIND}}}resource").text == "մուտք😀"
                bare = f"օբերոն@{canonical}"
                full = bare + "/մուտք😀"
                send(connection, f'<iq id="{bind.get("id")}" type="result"><bind xmlns="{BIND}"><jid>{full}</jid></bind></iq>')
                iq = peer.event()
                assert iq.tag == f"{{{CLIENT}}}iq" and iq.get("type") == "set" and iq.get("to") == bare
                publish = iq.find(f"{{{PUBSUB}}}pubsub/{{{PUBSUB}}}publish")
                assert publish.get("node") == NODE
                item = publish.find(f"{{{PUBSUB}}}item")
                item_id = item.get("id")
                assert uuid.UUID(item_id).version == 4
                entry = item.find(f"{{{ATOM}}}entry")
                for name in ("title", "content"):
                    assert entry.find(f"{{{ATOM}}}{name}").text == text
                published = entry.find(f"{{{ATOM}}}published").text
                updated = entry.find(f"{{{ATOM}}}updated").text
                assert published == updated
                assert abs((datetime.fromisoformat(updated) - datetime.now(timezone.utc)).total_seconds()) < 60
                assert entry.find(f"{{{ATOM}}}id").text == f'tag:{canonical.encode("idna").decode()},{updated[:10]}:posts-{item_id}'
                identifier = iq.get("id")
                result = f'<iq type="result" id="{identifier}" from="{bare}" to="{full}">'
                if mode == "omitted-from":
                    result = f'<iq type="result" id="{identifier}" to="{full}">'
                if mode == "error":
                    send(connection, f'<iq type="error" id="{identifier}" from="{bare}"><error type="cancel"><forbidden xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/></error></iq>')
                    return
                if mode == "spoof":
                    send(connection, f'<iq type="result" id="{identifier}" from="attacker@localhost"/>')
                    send(connection, f'<iq type="result" id="wrong-id" from="{bare}"/>')
                if mode in {"spoof-only", "timeout", "flood"}:
                    if mode == "spoof-only":
                        send(connection, f'<iq type="result" id="{identifier}" from="attacker@localhost"/>')
                    if mode == "flood":
                        try:
                            while True:
                                send(connection, '<message><body>ignore</body></message>')
                        except (OSError, ssl.SSLError):
                            return
                    try:
                        while connection.recv(4096):
                            pass
                    except (OSError, ssl.SSLError):
                        pass
                    return
                if mode == "empty":
                    content = ""
                else:
                    returned = "wrong-item" if mode == "wrong-item" else item_id
                    node = "wrong-node" if mode == "wrong-node" else NODE
                    uri = "urn:wrong" if mode == "wrong-namespace" else PUBSUB
                    content = f'<pubsub xmlns="{uri}"><publish node="{node}"><item id="{returned}"/></publish></pubsub>'
                    if mode == "malformed":
                        content += '<extra/>'
                send(connection, result + content + '</iq>', 3)
                if mode in {"wrong-item", "wrong-node", "wrong-namespace", "malformed"}:
                    return
                if mode.startswith("verify"):
                    request = peer.event()
                    assert request.get("type") == "get" and request.get("to") == bare
                    items = request.find(f"{{{PUBSUB}}}pubsub/{{{PUBSUB}}}items")
                    assert items.get("node") == NODE and items.get("max_items") == "1"
                    assert items.find(f"{{{PUBSUB}}}item").get("id") == item_id
                    returned = "wrong" if mode == "verify-id" else item_id
                    if mode == "verify-text":
                        entry.find(f"{{{ATOM}}}content").text = "wrong"
                    if mode == "verify-error":
                        send(connection, f'<iq type="error" id="{request.get("id")}"><error type="cancel">'
                             '<item-not-found xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/></error></iq>')
                        return
                    send(connection, f'<iq type="result" id="{request.get("id")}"><pubsub xmlns="{PUBSUB}">'
                         f'<items node="{NODE}"><item id="{returned}">{ET.tostring(entry, encoding="unicode")}'
                         '</item></items></pubsub></iq>', 5)
                    if mode != "verify":
                        return
                assert peer.event().tag == "{http://etherx.jabber.org/streams}stream"
                send(connection, '</s:stream>')
                try:
                    connection.unwrap().close()
                except (OSError, ssl.SSLError):
                    pass
            finally:
                connection.close()

        server = pool.submit(serve)
        config = {
            "XMPP_CONFIG": str(fixtures / "publish.conf"), "XMPP_JID": f"օբերոն@{domain}/մուտք😀",
            "XMPP_PASSWORD": "dummy-գաղտնի😀", "XMPP_MESSAGE": text,
            "XMPP_HOST": "127.0.0.1", "XMPP_PORT": str(listener.getsockname()[1]),
            "XMPP_ALLOW_PLAIN": "yes", "XMPP_TLS": "direct" if direct else "starttls", "XMPP_TIMEOUT_MS": "2000",
        }
        Path(config["XMPP_CONFIG"]).write_text("# local synthetic test\n")
        command = [build / "XmppPublishProbe", str(uuid.uuid4())] if mode.startswith("verify") else [build / "XmppPublish"]
        result = subprocess.run(command, cwd=build, env=env | config, capture_output=True, timeout=10)
        success = mode in {"result", "empty", "spoof", "omitted-from", "verify"}
        assert (result.returncode == 0) == success, (mode, result.stdout, result.stderr)
        assert config["XMPP_PASSWORD"].encode() not in result.stdout + result.stderr
        server.result(timeout=10)
        print(f"XMPP publisher {mode} ({'direct TLS' if direct else 'STARTTLS'}): passed", flush=True)


for mode in ("result", "empty", "spoof", "omitted-from", "error", "wrong-item", "wrong-node", "wrong-namespace", "malformed",
             "spoof-only", "timeout", "flood", "no-tls", "auth-refused"):
    case(mode)
case("result", direct=True)
case("result", domain="ծոց.հայ", certificate="idn")
case("result", direct=True, domain="XN--CBBU1A.XN--Y9A3AQ", certificate="idn")
case("wrong-host", certificate="wrong")
case("untrusted", direct=True, certificate="untrusted")
for mode in ("verify", "verify-text", "verify-id", "verify-error"):
    case(mode)
case("verify", direct=True, domain="ծոց.հայ", certificate="idn")
