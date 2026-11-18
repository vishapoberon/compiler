"""Pinned Ed25519 certificate policy using independent X.509 fixtures; requires cryptography.

Usage: python3 pinned-ed25519.py COMPILER BUILD MODEL FLAGS
"""
from datetime import datetime, timedelta, timezone
import os
from pathlib import Path
import shlex
import subprocess
import sys

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
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
for module in ("TLSBytes", "TLSSHA512", "TLSEd25519", "TLSSig", "TLSIdentity", "TLSX509Ext", "TLS13Auth"):
    subprocess.run([str(Path(compiler).resolve()), "-O"+model, "-sF", str(source/(module+".Mod"))],
                   cwd=build, env=env, check=True)
subprocess.run([str(Path(compiler).resolve()), "-O"+model, *shlex.split(flags), str(tests/"TestPinnedEd25519.Mod")],
               cwd=build, env=env, check=True)

private = Ed25519PrivateKey.from_private_bytes(bytes(range(32)))
other = Ed25519PrivateKey.generate()
public = private.public_key().public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw)
name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "peer")])
now = datetime.now(timezone.utc)
base = (x509.CertificateBuilder().subject_name(name).issuer_name(name).public_key(private.public_key())
        .serial_number(1).not_valid_before(now-timedelta(days=1)).not_valid_after(now+timedelta(days=1)))
fixtures = [("plain", base.sign(private, None), True, True)]
for oid, server, client in ((ExtendedKeyUsageOID.SERVER_AUTH, True, False),
                            (ExtendedKeyUsageOID.CLIENT_AUTH, False, True),
                            (ExtendedKeyUsageOID.ANY_EXTENDED_KEY_USAGE, True, True)):
    fixtures.append((oid.dotted_string, base.add_extension(x509.ExtendedKeyUsage([oid]), critical=True)
                     .sign(private, None), server, client))
both = x509.ExtendedKeyUsage([ExtendedKeyUsageOID.SERVER_AUTH, ExtendedKeyUsageOID.CLIENT_AUTH])
fixtures.append(("both-roles", base.add_extension(both, critical=False).sign(private, None), True, True))
for digital_signature in (False, True):
    usage = x509.KeyUsage(digital_signature=digital_signature, content_commitment=False, key_encipherment=False,
                         data_encipherment=False, key_agreement=False, key_cert_sign=False, crl_sign=False,
                         encipher_only=None, decipher_only=None)
    fixtures.append(("signing-"+str(digital_signature), base.add_extension(usage, critical=True).sign(private, None),
                     digital_signature, digital_signature))
unknown = x509.UnrecognizedExtension(ObjectIdentifier("1.2.3.4"), b"\x05\x00")
for critical in (False, True):
    fixtures.append(("unknown-"+str(critical), base.add_extension(unknown, critical=critical).sign(private, None),
                     not critical, not critical))
fixtures.append(("wrong-signer", base.sign(other, None), False, False))
issuer = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "other")])
different_issuer = (x509.CertificateBuilder().subject_name(name).issuer_name(issuer).public_key(private.public_key())
                    .serial_number(1).not_valid_before(now-timedelta(days=1)).not_valid_after(now+timedelta(days=1)))
fixtures.append(("different-issuer", different_issuer.sign(private, None), False, False))
for label, start, end in (("expired", -2, -1), ("future", 1, 2)):
    builder = (x509.CertificateBuilder().subject_name(name).issuer_name(name).public_key(private.public_key())
               .serial_number(1).not_valid_before(now+timedelta(days=start)).not_valid_after(now+timedelta(days=end)))
    fixtures.append((label, builder.sign(private, None), False, False))
ec_key = ec.generate_private_key(ec.SECP256R1())
builder = (x509.CertificateBuilder().subject_name(name).issuer_name(name).public_key(ec_key.public_key())
           .serial_number(1).not_valid_before(now-timedelta(days=1)).not_valid_after(now+timedelta(days=1)))
fixtures.append(("wrong-key-algorithm", builder.sign(ec_key, hashes.SHA256()), False, False))

checks = 0
for label, certificate, server, client in fixtures:
    path = build/(label+".pem")
    path.write_bytes(certificate.public_bytes(serialization.Encoding.PEM))
    pins = [(public, server, client)]
    if label == "plain":
        pins.extend([(bytes(32), False, False), (public[:-1], False, False), (b"", False, False)])
    for pin, accept_server, accept_client in pins:
        for role, accepted in (("server", accept_server), ("client", accept_client)):
            result = subprocess.run([str(build/"TestPinnedEd25519"), str(path), pin.hex(), role,
                                     "accept" if accepted else "reject"], cwd=build, env=env,
                                    capture_output=True, text=True, timeout=30)
            assert result.returncode == 0, (label, role, pin.hex(), result.stdout, result.stderr)
            checks += 1
print(f"Pinned Ed25519 certificate policy: {checks} independent fixture checks passed")
