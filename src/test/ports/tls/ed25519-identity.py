"""Ed25519 X.509/PKCS#8 interoperability; requires Python cryptography.

Usage: python3 ed25519-identity.py COMPILER BUILD MODEL FLAGS
"""
from datetime import datetime, timedelta, timezone
import os
from pathlib import Path
import shlex
import subprocess
import sys

from cryptography import x509
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.x509.oid import NameOID, SignatureAlgorithmOID


compiler, directory, model, flags = sys.argv[1:]
tests = Path(__file__).resolve().parent
source = tests.parent / "src"
if (source/"TLSIdentity.Mod").is_file():
    tests = source
else:
    source = tests.parents[2] / "ports/norayr/tls"
build = Path(directory).resolve()
build.mkdir(parents=True, exist_ok=True)
env = dict(os.environ, OBERON=str(build)+";"+os.environ.get("OBERON", ""))
seed = bytes.fromhex("9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60")
private = Ed25519PrivateKey.from_private_bytes(seed)
name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "peer")])
now = datetime.now(timezone.utc)
certificate = (x509.CertificateBuilder().subject_name(name).issuer_name(name)
               .public_key(private.public_key()).serial_number(1)
               .not_valid_before(now-timedelta(days=1)).not_valid_after(now+timedelta(days=365))
               .sign(private, None))
(build/"peer.pem").write_bytes(certificate.public_bytes(serialization.Encoding.PEM))
(build/"peer.key").write_bytes(private.private_bytes(serialization.Encoding.PEM,
    serialization.PrivateFormat.PKCS8, serialization.NoEncryption()))
(build/"other.key").write_bytes(Ed25519PrivateKey.generate().private_bytes(serialization.Encoding.PEM,
    serialization.PrivateFormat.PKCS8, serialization.NoEncryption()))


def compile_file(path, main=False):
    subprocess.run([str(Path(compiler).resolve()), "-O"+model,
                    *shlex.split(flags if main else "-sF"), str(path)],
                   cwd=build, env=env, check=True)


for module in ("TLSBytes", "TLSSHA512", "TLSEd25519", "TLSSig", "TLSIdentity", "TLSCertGen"):
    compile_file(source/(module+".Mod"))
compile_file(tests/"TLSTestEd25519Identity.Mod", main=True)
subprocess.run([str(build/"TLSTestEd25519Identity")], cwd=build, env=env, check=True, timeout=60)
program = build/"TestEd25519IdentityInterop.Mod"
program.write_text('''MODULE TestEd25519IdentityInterop;
IMPORT TLSBytes, TLSIdentity, TLSCertGen, TLSX509, TLSSig, Args, Out;
VAR id, rejected: TLSIdentity.Identity; certificate, content, signature: TLSBytes.Buffer;
  info: POINTER TO TLSX509.CertInfo;
  seed: ARRAY 32 OF CHAR; certFile, keyFile, wrongFile: ARRAY 4096 OF CHAR;
PROCEDURE Print(VAR bytes: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN FOR i := 0 TO bytes.len-1 DO Out.HexDigits(ORD(bytes.data[i]), 2) END; Out.Ln END Print;
BEGIN
  Args.Get(1, certFile); Args.Get(2, keyFile); Args.Get(3, wrongFile);
  IF TLSIdentity.Load(certFile, wrongFile, rejected) THEN HALT(1) END;
  IF ~TLSIdentity.Load(certFile, keyFile, id) THEN Out.String(TLSIdentity.lastError); Out.Ln; HALT(2) END;
  NEW(info);
  IF ~TLSX509.ParseCertificate(id.certs[0], info^) OR ~TLSSig.CertSignedBy(info^, info^) THEN HALT(7) END;
  TLSBytes.Init(content); TLSBytes.AppendString(content, "TLS Ed25519 identity interoperability");
  IF ~TLSIdentity.Sign(id, content, signature) THEN HALT(3) END; Print(signature);
  IF ~TLSIdentity.PublicKey(id^, content) THEN HALT(4) END; Print(content);
''' + "\n".join(f"  seed[{i}] := CHR({value});" for i, value in enumerate(seed)) + '''
  IF ~TLSCertGen.Ed25519SelfSigned("peer", seed, 1, certificate) THEN HALT(5) END;
  NEW(info);
  IF ~TLSX509.ParseCertificate(certificate, info^) OR ~TLSSig.CertSignedBy(info^, info^) THEN HALT(6) END;
  Print(certificate); TLSIdentity.Clear(id)
END TestEd25519IdentityInterop.
''')
compile_file(program, main=True)
result = subprocess.run([str(build/program.stem), str(build/"peer.pem"), str(build/"peer.key"),
                         str(build/"other.key")], cwd=build, env=env, check=True, text=True, capture_output=True, timeout=60)
signature, public, generated = map(bytes.fromhex, result.stdout.splitlines())
message = b"TLS Ed25519 identity interoperability"
private.public_key().verify(signature, message)
assert signature == private.sign(message)
assert public == private.public_key().public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw)
generated = x509.load_der_x509_certificate(generated)
assert generated.signature_algorithm_oid == SignatureAlgorithmOID.ED25519
assert generated.public_key().public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw) == public
private.public_key().verify(generated.signature, generated.tbs_certificate_bytes)
print("Ed25519 identity interoperability: key loading, mismatch rejection, signatures and self-signed certificates passed")
