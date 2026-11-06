"""Check explicit pre-login registration against local TLS-only fixtures."""

import concurrent.futures
import socket
import ssl
import subprocess
import sys

sys.dont_write_bytecode = True
import loopback as xmpp


REGISTER = "jabber:iq:register"
FEATURE = "http://jabber.org/features/iq-register"


def case(mode="register", direct=False, certificate="server", domain="localhost"):
    identity = "localhost" if domain == "localhost" else "ծոց.հայ"
    listener = socket.socket()
    listener.bind(("127.0.0.1", 0))
    listener.listen(1)
    listener.settimeout(10)
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(xmpp.FIXTURES / (certificate + ".pem"), xmpp.FIXTURES / (certificate + ".key"))

    def header(connection, features):
        xmpp.send(connection, f'<q:stream xmlns:q="{xmpp.STREAMS}" xmlns="{xmpp.CLIENT}" '
                  f'from="{identity}" version="1.0"><q:features>{features}</q:features>', 1)

    def serve():
        connection, _ = listener.accept()
        connection.settimeout(8)
        try:
            if not direct:
                peer = xmpp.Peer(connection, identity)
                assert peer.event().tag == f"{{{xmpp.STREAMS}}}stream"
                # The plaintext advertisement must not survive the TLS restart.
                header(connection, f'<starttls xmlns="{xmpp.TLS}"/><register xmlns="{FEATURE}"/>')
                assert peer.event().tag == f"{{{xmpp.TLS}}}starttls"
                xmpp.send(connection, f'<proceed xmlns="{xmpp.TLS}"/>')
            try:
                connection = context.wrap_socket(connection, server_side=True)
            except (ssl.SSLError, ConnectionResetError, BrokenPipeError):
                if mode in ("wrong-host", "untrusted"):
                    return
                raise
            if mode in ("wrong-host", "untrusted"):
                try:
                    assert connection.recv(1) == b""
                except (ssl.SSLError, ConnectionResetError):
                    pass
                return
            peer = xmpp.Peer(connection, identity)
            assert peer.event().tag == f"{{{xmpp.STREAMS}}}stream"
            header(connection, f'<register xmlns="{FEATURE}"/>' if mode != "no-register" else "")
            if mode == "no-register":
                assert connection.recv(1) == b""
                return
            query = peer.event()
            assert query.tag == f"{{{xmpp.CLIENT}}}iq" and query.get("type") == "get"
            assert query.get("to") is None and query.get("from") is None
            assert query.find(f"{{{REGISTER}}}query") is not None
            xmpp.send(connection, f'<iq type="result" id="{query.get("id")}"><query xmlns="{REGISTER}">'
                      '<instructions>Լրացրու 😀</instructions><username/><password/><email/>'
                      '<key>challenge</key></query></iq>', 1)
            submission = peer.event()
            assert submission.tag == f"{{{xmpp.CLIENT}}}iq" and submission.get("type") == "set"
            assert submission.get("to") is None and submission.get("from") is None
            fields = submission.find(f"{{{REGISTER}}}query")
            assert fields is not None and len(fields) == 4
            for name, text in (("username", "Անի😀"), ("password", "գաղտնի<&😀"),
                               ("email", "ani@example.net"), ("key", "challenge")):
                assert fields.find(f"{{{REGISTER}}}{name}").text == text
            for sender in ("attacker.example", identity + "/resource"):
                xmpp.send(connection, f'<iq type="result" from="{sender}" id="{submission.get("id")}"/>', 1)
            xmpp.send(connection, f'<iq type="result" from="{identity}" id="{submission.get("id")}"/>', 1)
            assert peer.event().tag == f"{{{xmpp.STREAMS}}}stream"
            xmpp.send(connection, '</q:stream>')
            try:
                connection.unwrap().close()
            except (ssl.SSLError, ConnectionResetError):
                pass
        finally:
            connection.close()

    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
            server = pool.submit(serve)
            result = subprocess.run([str(xmpp.BUILD / "TestXmppRegisterNetwork"), str(listener.getsockname()[1]),
                                     mode, "yes" if direct else "no", domain], cwd=xmpp.BUILD, env=xmpp.ENV,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=45)
            if result.returncode:
                raise RuntimeError(mode + ":\n" + result.stdout)
            server.result(timeout=20)
        print(f"XMPP registration {mode} ({'direct TLS' if direct else 'STARTTLS'}, {domain}): passed", flush=True)
    finally:
        listener.close()


if __name__ == "__main__":
    for direct in (False, True):
        case(direct=direct)
        case("no-register", direct=direct)
        case("wrong-host", direct=direct, certificate="wrong")
        case("untrusted", direct=direct, certificate="untrusted")
    case(certificate="idn", domain="xn--cbbu1a.xn--y9a3aq")
    case(direct=True, certificate="idn", domain="ԾՈՑ.ՀԱՅ")
