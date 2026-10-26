"""Test bounded configuration and XML encoding with synthetic data only."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

build = Path(sys.argv[1]).resolve()
program = build / "TestXmppPublish"
env = {key: value for key, value in os.environ.items() if not key.startswith("XMPP_")}
checks = 0

with tempfile.TemporaryDirectory(dir=build, prefix="publisher-config-") as directory:
    path = Path(directory) / "config"
    env.update(HOME=directory, XMPP_CONFIG=str(path))

    def case(content, overrides=None, valid=True):
        global checks
        path.write_bytes(content)
        result = subprocess.run([program, "load"], env=env | (overrides or {}),
                                capture_output=True, timeout=10)
        assert (result.returncode == 0) == valid, (checks, result.stdout, result.stderr)
        checks += 1
        return result.stdout.decode().splitlines()

    values = case(b"[account]\r\njid = user@example.org\r\npassword = dummy\r\nmessage = file message")
    assert values[:5] == ["user@example.org", "file message", "5222", "10000", "5"]
    values = case(b"message=file\npassword=dummy\n", {
        "XMPP_JID": "օբերոն@ծոց.հայ/մուտք😀", "XMPP_MESSAGE": "Բարեւ 😀", "XMPP_ALLOW_PLAIN": "yes",
        "XMPP_TLS": "direct", "XMPP_PORT": "5223", "XMPP_TIMEOUT_MS": "2000"})
    assert values == ["օբերոն@ծոց.հայ/մուտք😀", "Բարեւ 😀", "5223", "2000", "5", "plain", "direct"]
    for content in (b"port=65536", b"port=-1", b"port=0", b"timeout_ms=999999999999999999999",
                    b"tls=off", b"allow_plain=maybe", b"typo=value", b"message=x\0y",
                    b"message=" + b"x" * 16385, b"#x\n" * 22000):
        case(content, valid=False)
    case(b"password=" + b"x" * 12289, valid=False)
    case(b"", {"XMPP_PASSWORD": "x" * 12289}, valid=False)
    case(b"", {"XMPP_MESSAGE": "x" * 16385}, valid=False)
    case(b"", {"XMPP_CONFIG": str(path) + "x" * 4096}, valid=False)
    path.unlink()
    result = subprocess.run([program, "load"], env=env, capture_output=True, timeout=10)
    assert result.returncode != 0
    fallback = env.copy()
    del fallback["XMPP_CONFIG"]
    result = subprocess.run([program, "load"], env=fallback, capture_output=True, timeout=10)
    assert result.returncode == 0
    checks += 2
    for overrides in ({}, {"XMPP_JID": "user@example.org", "XMPP_PASSWORD": "dummy"},
                      {"XMPP_JID": "bad..domain", "XMPP_PASSWORD": "dummy", "XMPP_ALLOW_PLAIN": "yes"}):
        result = subprocess.run([build / "XmppPublish"], env=fallback | overrides, capture_output=True, timeout=10)
        assert result.returncode != 0 and b"dummy" not in result.stdout + result.stderr
        checks += 1

result = subprocess.run([program, "dump"], check=True, capture_output=True, timeout=10)
root = ET.fromstring(result.stdout)
entry = root.find("{http://jabber.org/protocol/pubsub}publish/{http://jabber.org/protocol/pubsub}item/{http://www.w3.org/2005/Atom}entry")
assert entry.find("{http://www.w3.org/2005/Atom}content").text == "Բարեւ 😀 <tag> & text"
print(f"XMPP publisher configuration and XML cases passed: {checks + 1}")
