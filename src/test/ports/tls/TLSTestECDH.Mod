MODULE TLSTestECDH;  (* ECDH on secp256r1 and secp384r1 against the Python cryptography package:
  the public key and the shared secret; points off the curve, beyond p or compressed, and the
  scalars 0 and n are refused; the scalars 1 and n - 1 give G and -G *)

IMPORT TLSBytes, TLSECDSA, Out;

VAR
  fails, checks: LONGINT;
  priv, pubA, pubB, want: TLSBytes.Buffer;

PROCEDURE Hex(c: CHAR): LONGINT;
BEGIN
  IF c <= "9" THEN RETURN ORD(c) - ORD("0") ELSE RETURN ORD(c) - ORD("a") + 10 END
END Hex;

PROCEDURE Clear(VAR b: TLSBytes.Buffer);
BEGIN TLSBytes.Init(b)
END Clear;

PROCEDURE Add(VAR b: TLSBytes.Buffer; x: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(x) - 1) & (x[i] # 0X) DO TLSBytes.AppendByte(b, Hex(x[i]) * 16 + Hex(x[i+1])); INC(i, 2) END
END Add;

PROCEDURE Check(what: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN INC(fails); Out.String("FAIL "); Out.String(what); Out.String(" (case "); Out.Int(checks, 0); Out.String(")"); Out.Ln END
END Check;

PROCEDURE VectorsP256;
BEGIN
  Clear(priv);
  Add(priv, "051b481e3bda7e947cd3f897bd47f468657a9b8e76d1de4c5b3f5ab6ae034763");
  Clear(pubA);
  Add(pubA, "049d9234864799815f5e867193dd000bd1963e9fe420e2d397b0f2f30075dc46");
  Add(pubA, "a7b7332355249dde2c4835ff0b3c8be2a49b8fc0d71c40631e56267e32d33ec1");
  Add(pubA, "e8");
  Clear(pubB);
  Add(pubB, "04ecc1202b1528de6d4f61634d2059aa635495710b200f938b8837bb5b2024f0");
  Add(pubB, "96c9ac2d6d8c1a3446e22bcde020762045541271b30a106c092505729e4f7ad5");
  Add(pubB, "40");
  Clear(want);
  Add(want, "3784ca3376c9058b840512f18f7c82eefbe0ad0a9f3e329adfff0273f51c6912");
END VectorsP256;

PROCEDURE VectorsP384;
BEGIN
  Clear(priv);
  Add(priv, "0ed8582ca30071f6538ba318b9c5376621b3f14a8d0f492d222fbb3fbaef9afb");
  Add(priv, "6ccea0ec6ec5b39fb78ad8219a0325b3");
  Clear(pubA);
  Add(pubA, "0469e5a2deb533045caca5ccbc8ae2506b8f128c9197591c370e7584f0685b3f");
  Add(pubA, "8b022c764f5d5b6fd31ca5a20767eba746ae4ba4e5fd2d0fb738ced767774b71");
  Add(pubA, "c02b31be73aab4fde880621156a650b3689faf387b7c76dce0e178984e4d954a");
  Add(pubA, "82");
  Clear(pubB);
  Add(pubB, "04bbe1d58a8057d8b2987d6392406f7a8b94c2aec0d88e1e094920d287cb929b");
  Add(pubB, "4f6ec288a9edbd7584c146060384aaf613eb82258a6726a280ea1e37e160057c");
  Add(pubB, "9b2dceba9964aa005949acbd13a709177950f9ca334b546debca5f96678eb9a2");
  Add(pubB, "71");
  Clear(want);
  Add(want, "5d6edd089e12d0c3814e227f6f4546a582b917a94121465db3e07a301bdc4c9e");
  Add(want, "3ad459090c1cc8a789d99bd625dbfe8b");
END VectorsP384;

PROCEDURE Case(curve, n: LONGINT);
VAR pub, shared, bad: TLSBytes.Buffer; i: LONGINT;
BEGIN
  Check("public key", TLSECDSA.ECDHPublic(curve, priv, pub) & TLSBytes.EqualConstTime(pub, pubA));
  Check("shared secret", TLSECDSA.ECDH(curve, priv, pubB, shared) & TLSBytes.EqualConstTime(shared, want));
  TLSBytes.Copy(pubB, bad); bad.data[bad.len - 1] := CHR((ORD(bad.data[bad.len - 1]) + 1) MOD 256);
  Check("point off the curve", ~TLSECDSA.ECDH(curve, priv, bad, shared));
  TLSBytes.Copy(pubB, bad); i := 1; WHILE i <= n DO bad.data[i] := 0FFX; INC(i) END;
  Check("x beyond p", ~TLSECDSA.ECDH(curve, priv, bad, shared));
  TLSBytes.Copy(pubB, bad); bad.data[0] := 2X;
  Check("not uncompressed", ~TLSECDSA.ECDH(curve, priv, bad, shared));
  TLSBytes.Slice(pubB, 0, 1 + n, bad);
  Check("too short", ~TLSECDSA.ECDH(curve, priv, bad, shared));
  TLSBytes.Init(bad); i := 0; WHILE i < n DO TLSBytes.AppendByte(bad, 0); INC(i) END;
  Check("scalar 0", ~TLSECDSA.ECDHPublic(curve, bad, pub) & ~TLSECDSA.ECDH(curve, bad, pubB, shared))
END Case;

PROCEDURE Run;
VAR k, pub, t: TLSBytes.Buffer;
BEGIN
  VectorsP256; Case(TLSECDSA.P256, 32);
  VectorsP384; Case(TLSECDSA.P384, 48);
  Clear(k); Add(k, "ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551");
  Check("scalar n", ~TLSECDSA.ECDHPublic(TLSECDSA.P256, k, pub));
  k.data[31] := CHR(ORD(k.data[31]) - 1);  (* n - 1: -G, the x of G *)
  Clear(t); Add(t, "6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296");
  Check("scalar n - 1", TLSECDSA.ECDHPublic(TLSECDSA.P256, k, pub) & (pub.len = 65));
  TLSBytes.Slice(pub, 1, 32, k);
  Check("scalar n - 1 is -G", TLSBytes.EqualConstTime(k, t));
  Clear(k); WHILE k.len < 31 DO TLSBytes.AppendByte(k, 0) END; TLSBytes.AppendByte(k, 1);
  Check("scalar 1", TLSECDSA.ECDHPublic(TLSECDSA.P256, k, pub));
  TLSBytes.Slice(pub, 1, 32, k);
  Check("scalar 1 is G", TLSBytes.EqualConstTime(k, t));
  Out.String("TLSTestECDH: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END Run;

BEGIN
  fails := 0; checks := 0; Run
END TLSTestECDH.
