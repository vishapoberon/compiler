"""Ed25519 interoperability and strict-verification tests; requires cryptography.

Usage: python3 ed25519.py COMPILER BUILD MODEL FLAGS
Uses the selected compiler/runtime, compiling the local crypto modules in BUILD.
"""

import hashlib
import os
from pathlib import Path
import shlex
import subprocess
import sys

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey


P = 2**255 - 19
L = 2**252 + 27742317777372353535851937790883648493
D = -121665 * pow(121666, P - 2, P) % P
IDENTITY = (0, 1)


def add(a, b):
    x, y = a
    u, v = b
    t = D * x * u * y * v % P
    return ((x * v + y * u) * pow(1 + t, P - 2, P) % P,
            (y * v + x * u) * pow(1 - t, P - 2, P) % P)


def multiply(a, n):
    result = IDENTITY
    while n:
        if n & 1:
            result = add(result, a)
        a = add(a, a)
        n >>= 1
    return result


def point(y):
    square = (y * y - 1) * pow(D * y * y + 1, P - 2, P) % P
    x = pow(square, (P + 3) // 8, P)
    if x * x % P != square:
        x = x * pow(2, (P - 1) // 4, P) % P
    if x * x % P != square:
        return None
    return (P - x if x & 1 else x, y)


def encode(a):
    x, y = a
    return (y | ((x & 1) << 255)).to_bytes(32, "little")


def pattern(length, salt):
    return bytes((i * 137 + salt) % 256 for i in range(length))


def decode(name, data):
    return f'Decode("{data.hex()}", {name});'


def main():
    compiler, directory, model, flags = sys.argv[1:]
    compiler = str(Path(compiler).resolve())
    build = Path(directory).resolve()
    build.mkdir(parents=True, exist_ok=True)
    source = Path(__file__).resolve().parent
    modules = source.parent / "src"
    if (modules / "TLSEd25519.Mod").is_file():
        tests = modules
    else:
        modules = source.parents[2] / "ports/norayr/tls"
        tests = source
    env = dict(os.environ)
    env["OBERON"] = str(build) + ";" + env.get("OBERON", "")

    def compile_file(path, main=False, cwd=build, environment=env):
        subprocess.run([compiler, "-O" + model, *shlex.split(flags if main else "-sF"), str(path)],
                       cwd=cwd, env=environment, check=True)

    for name in ("TLSBytes", "TLSSHA512", "TLSEd25519", "TLS13Random", "TLSEd25519Keys"):
        compile_file(modules / (name + ".Mod"))
    for name in ("TLSTestEd25519", "TLSTestSHA512Stream"):
        compile_file(tests / (name + ".Mod"), main=True)
        subprocess.run([str(build / name)], cwd=build, env=env, check=True)

    body = []
    lengths = [0, 1, 2, 31, 32, 63, 64, 111, 112, 113, 127, 128, 129,
               255, 256, 257, 1023, 1024, 1025, 32767, 32768, 32769, 65537, 1000000]
    for index, length in enumerate(lengths):
        seed = hashlib.sha256(f"Ed25519 vector {index}".encode()).digest()
        private = Ed25519PrivateKey.from_private_bytes(seed)
        public = private.public_key().public_bytes(serialization.Encoding.Raw,
                                                  serialization.PublicFormat.Raw)
        message = pattern(length, index)
        signature = private.sign(message)
        private.public_key().verify(signature, message)
        body += [decode("seed", seed), decode("wantedKey", public),
                 decode("wantedSignature", signature), f"Vector({length}, {index}, {index % 17});"]
        for step in (1, 127, 128, 8191):
            body += [decode("wantedDigest", hashlib.sha512(message).digest()),
                     f"Hash({length}, {index}, {step});"]
        if length <= 32768:
            body += [decode("wantedDigest", hashlib.sha384(message).digest()),
                     f"Hash384({length}, {index});"]

    base = point(4 * pow(5, P - 2, P) % P)
    assert base is not None and multiply(base, L) == IDENTITY
    # An order-eight point generates every low-order encoding.
    for y in range(2, 100):
        candidate = point(y)
        if candidate is not None:
            torsion = multiply(candidate, L)
            if multiply(torsion, 4) != IDENTITY:
                break
    else:
        raise AssertionError("missing torsion generator")
    assert multiply(torsion, 8) == IDENTITY
    a, r = 12345, 67890
    public, encoded_r = encode(multiply(base, a)), encode(multiply(base, r))

    def reject(key, nonce, scalar):
        body.extend([decode("publicKey", key), decode("signature", nonce + scalar.to_bytes(32, "little")),
                     "Check(~TLSEd25519.Verify(publicKey, message, 0, 0, signature));"])

    def challenge(key, nonce):
        return int.from_bytes(hashlib.sha512(nonce + key).digest(), "little") % L

    # Valid equations with identity points must still be rejected by policy.
    reject(encode(IDENTITY), encoded_r, r)
    identity_r = encode(IDENTITY)
    reject(public, identity_r, challenge(public, identity_r) * a % L)
    for i in range(8):
        low = multiply(torsion, i)
        encoded_low = encode(low)
        reject(encoded_low, encoded_r, r)
        reject(public, encoded_low, 0)
        if i:
            mixed_a = add(multiply(base, a), low)
            mixed_r = add(multiply(base, r), low)
            key, nonce = encode(mixed_a), encode(mixed_r)
            h = challenge(key, nonce)
            # The cofactored equation holds despite the mixed-order points.
            s = (r + h * a) % L
            assert multiply(multiply(base, s), 8) == multiply(add(mixed_r, multiply(mixed_a, h)), 8)
            reject(key, nonce, s)
            reject(key, encoded_r, (r + challenge(key, encoded_r) * a) % L)
            reject(public, nonce, (r + challenge(public, nonce) * a) % L)

    for scalar in (L, L + 1, 2**253, 2**255, 2**256 - 1):
        reject(public, encoded_r, scalar)
    for y in (P, P + 1, 2**255 - 1):
        for sign in (0, 1):
            invalid = (y | (sign << 255)).to_bytes(32, "little")
            reject(invalid, encoded_r, r)
            reject(public, invalid, r)
    for y in (1, P - 1):
        negative_zero = (y | (1 << 255)).to_bytes(32, "little")
        reject(negative_zero, encoded_r, r)
        reject(public, negative_zero, r)
    for y in range(2, 20):
        if point(y) is None:
            invalid = y.to_bytes(32, "little")
            reject(invalid, encoded_r, r)
            reject(public, invalid, r)

    program = '''MODULE TestEd25519Interop;
IMPORT TLSEd25519, TLSSHA512, TLSBytes, Out;
VAR seed, publicKey, wantedKey: ARRAY 32 OF CHAR;
  signature, wantedSignature, wantedDigest, digest: ARRAY 64 OF CHAR;
  message: ARRAY 1000017 OF CHAR;
  context: TLSSHA512.Context;
  input, reference: TLSBytes.Buffer;
  checks: LONGINT;
PROCEDURE Check(okay: BOOLEAN);
BEGIN INC(checks); IF ~okay THEN Out.String("FAIL interoperability case "); Out.Int(checks, 0); Out.Ln; HALT(1) END END Check;
PROCEDURE Hex(c: CHAR): LONGINT;
BEGIN IF c <= "9" THEN RETURN ORD(c)-ORD("0") END; RETURN ORD(c)-ORD("a")+10 END Hex;
PROCEDURE Decode(text: ARRAY OF CHAR; VAR bytes: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN i := 0; WHILE i*2 < LEN(text)-1 DO bytes[i] := CHR(Hex(text[2*i])*16+Hex(text[2*i+1])); INC(i) END END Decode;
PROCEDURE Equal(VAR a, b: ARRAY OF CHAR; n: LONGINT): BOOLEAN;
VAR i: LONGINT;
BEGIN i := 0; WHILE (i < n) & (a[i] = b[i]) DO INC(i) END; RETURN i = n END Equal;
PROCEDURE Fill(n, salt, offset: LONGINT);
VAR i: LONGINT;
BEGIN i := 0; WHILE i < n DO message[offset+i] := CHR((i*137+salt) MOD 256); INC(i) END END Fill;
PROCEDURE Vector(n, salt, offset: LONGINT);
VAR i: LONGINT; old: CHAR; oversized: ARRAY 65 OF CHAR;
BEGIN
  Fill(n, salt, offset);
  Check(TLSEd25519.PublicKey(seed, publicKey)); Check(Equal(publicKey, wantedKey, 32));
  Check(TLSEd25519.Sign(seed, message, offset, n, signature)); Check(Equal(signature, wantedSignature, 64));
  Check(TLSEd25519.Verify(publicKey, message, offset, n, wantedSignature));
  oversized[64] := 0A5X; Check(TLSEd25519.Sign(seed, message, offset, n, oversized));
  Check(Equal(oversized, wantedSignature, 64) & (oversized[64] = 0A5X));
  IF n > 0 THEN
    old := message[offset]; message[offset] := CHR((ORD(old)+1) MOD 256);
    Check(~TLSEd25519.Verify(publicKey, message, offset, n, signature)); message[offset] := old
  END;
  i := 0;
  WHILE i < 64 DO
    old := signature[i]; signature[i] := CHR((ORD(old)+1) MOD 256);
    Check(~TLSEd25519.Verify(publicKey, message, offset, n, signature)); signature[i] := old;
    INC(i, 7)
  END
END Vector;
PROCEDURE Hash(n, salt, step: LONGINT);
VAR pos, take: LONGINT;
BEGIN
  Fill(n, salt, 0); TLSSHA512.Init512(context); pos := 0;
  WHILE pos < n DO
    take := step; IF take > n-pos THEN take := n-pos END;
    IF ~TLSSHA512.Update(context, message, pos, take) THEN HALT(2) END; INC(pos, take)
  END;
  Check(TLSSHA512.Final512(context, digest)); Check(Equal(digest, wantedDigest, 64))
END Hash;
PROCEDURE Hash384(n, salt: LONGINT);
BEGIN
  Fill(n, salt, 0); TLSBytes.Init(input); TLSBytes.AppendOpen(input, message, n);
  TLSSHA512.Digest384(input, reference); Check((reference.len = 48) & Equal(reference.data, wantedDigest, 48))
END Hash384;
BEGIN
''' + "\n".join(body) + '''
  Out.String("Ed25519/SHA interoperability: "); Out.Int(checks, 0); Out.String(" checks passed"); Out.Ln
END TestEd25519Interop.
'''
    path = build / "TestEd25519Interop.Mod"
    path.write_text(program)
    compile_file(path, main=True)
    subprocess.run([str(build / "TestEd25519Interop")], cwd=build, env=env, check=True)

    # A partial entropy read must clear both caller-visible outputs.
    failure = build / "entropy-failure"
    failure.mkdir(exist_ok=True)
    failure_env = dict(env, OBERON=str(failure) + ";" + env["OBERON"])
    for name in ("TLSBytes", "TLSSHA512", "TLSEd25519"):
        compile_file(modules / (name + ".Mod"), cwd=failure, environment=failure_env)
    stub = failure / "TLS13Random.Mod"
    stub.write_text('''MODULE TLS13Random;
PROCEDURE Fill*(VAR buf: ARRAY OF CHAR; n: LONGINT): BOOLEAN;
BEGIN buf[0] := 0A5X; RETURN FALSE END Fill;
END TLS13Random.
''')
    compile_file(stub, cwd=failure, environment=failure_env)
    compile_file(modules / "TLSEd25519Keys.Mod", cwd=failure, environment=failure_env)
    test = failure / "TestEd25519Entropy.Mod"
    test.write_text('''MODULE TestEd25519Entropy;
IMPORT TLSEd25519Keys, Out;
VAR seed, key: ARRAY 32 OF CHAR; i: LONGINT;
BEGIN
  i := 0; WHILE i < 32 DO seed[i] := 0FFX; key[i] := 0FFX; INC(i) END;
  IF TLSEd25519Keys.Generate(seed, key) THEN HALT(1) END;
  i := 0; WHILE i < 32 DO IF (seed[i] # 0X) OR (key[i] # 0X) THEN HALT(2) END; INC(i) END;
  Out.String("Ed25519 entropy failure: outputs cleared"); Out.Ln
END TestEd25519Entropy.
''')
    compile_file(test, main=True, cwd=failure, environment=failure_env)
    subprocess.run([str(failure / "TestEd25519Entropy")], cwd=failure, env=failure_env, check=True)


if __name__ == "__main__":
    main()
