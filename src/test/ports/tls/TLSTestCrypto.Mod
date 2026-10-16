MODULE TLSTestCrypto;
IMPORT Out, TLSBytes, TLSSHA256, TLSHKDF, TLSX25519;

TYPE
  Byte32 = ARRAY 32 OF CHAR;

PROCEDURE HexDigit(n: LONGINT): CHAR;
BEGIN
  IF n < 10 THEN RETURN CHR(ORD('0') + n)
  ELSE RETURN CHR(ORD('a') + n - 10)
  END
END HexDigit;

PROCEDURE HexVal(c: CHAR): LONGINT;
BEGIN
  IF (c >= '0') & (c <= '9') THEN RETURN ORD(c) - ORD('0') END;
  IF (c >= 'a') & (c <= 'f') THEN RETURN ORD(c) - ORD('a') + 10 END;
  IF (c >= 'A') & (c <= 'F') THEN RETURN ORD(c) - ORD('A') + 10 END;
  RETURN 0
END HexVal;

PROCEDURE PrintByte(c: CHAR);
VAR x: LONGINT;
BEGIN
  x := ORD(c);
  Out.Char(HexDigit(x DIV 16));
  Out.Char(HexDigit(x MOD 16))
END PrintByte;

PROCEDURE PrintBuffer(VAR b: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE i < b.len DO PrintByte(b.data[i]); INC(i) END
END PrintBuffer;

PROCEDURE PrintDigest(VAR d: TLSSHA256.Digest);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE i < 32 DO PrintByte(d[i]); INC(i) END
END PrintDigest;

PROCEDURE DigestEqualsHex(VAR d: TLSSHA256.Digest; expected: ARRAY OF CHAR): BOOLEAN;
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE i < 32 DO
    IF HexDigit(ORD(d[i]) DIV 16) # expected[2*i] THEN RETURN FALSE END;
    IF HexDigit(ORD(d[i]) MOD 16) # expected[2*i+1] THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END DigestEqualsHex;

PROCEDURE BufferEqualsHex(VAR b: TLSBytes.Buffer; expected: ARRAY OF CHAR): BOOLEAN;
VAR i: LONGINT;
BEGIN
  IF b.len * 2 > LEN(expected) THEN RETURN FALSE END;
  i := 0;
  WHILE i < b.len DO
    IF HexDigit(ORD(b.data[i]) DIV 16) # expected[2*i] THEN RETURN FALSE END;
    IF HexDigit(ORD(b.data[i]) MOD 16) # expected[2*i+1] THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END BufferEqualsHex;

PROCEDURE FillBufferFromHex(VAR b: TLSBytes.Buffer; hex: ARRAY OF CHAR);
VAR i, n: LONGINT;
BEGIN
  TLSBytes.Init(b);
  n := 0;
  WHILE (n < LEN(hex)) & (hex[n] # 0X) DO INC(n) END;
  i := 0;
  WHILE i + 1 < n DO
    TLSBytes.AppendByte(b, HexVal(hex[i]) * 16 + HexVal(hex[i+1]));
    INC(i, 2)
  END
END FillBufferFromHex;

PROCEDURE FillArray32FromHex(VAR a: ARRAY OF CHAR; hex: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE i < 32 DO
    a[i] := CHR(HexVal(hex[2*i]) * 16 + HexVal(hex[2*i+1]));
    INC(i)
  END
END FillArray32FromHex;

PROCEDURE PrintArray32(VAR a: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE i < 32 DO PrintByte(a[i]); INC(i) END
END PrintArray32;

PROCEDURE Array32EqualsHex(VAR a: ARRAY OF CHAR; expected: ARRAY OF CHAR): BOOLEAN;
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE i < 32 DO
    IF HexDigit(ORD(a[i]) DIV 16) # expected[2*i] THEN RETURN FALSE END;
    IF HexDigit(ORD(a[i]) MOD 16) # expected[2*i+1] THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END Array32EqualsHex;

PROCEDURE SayResult(ok: BOOLEAN);
BEGIN
  IF ok THEN Out.String("  OK") ELSE Out.String("  FAIL") END;
  Out.Ln
END SayResult;

PROCEDURE TestSHA256;
VAR b: TLSBytes.Buffer; d: TLSSHA256.Digest;
BEGIN
  TLSBytes.Init(b);
  TLSSHA256.DigestBuffer(b, d);
  Out.String("SHA256(empty) = "); PrintDigest(d); Out.Ln;
  SayResult(DigestEqualsHex(d, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"));

  TLSBytes.Init(b); TLSBytes.AppendString(b, "abc");
  TLSSHA256.DigestBuffer(b, d);
  Out.String("SHA256(abc)   = "); PrintDigest(d); Out.Ln;
  SayResult(DigestEqualsHex(d, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"))
END TestSHA256;

PROCEDURE TestHMAC;
VAR key, msg: TLSBytes.Buffer; d: TLSSHA256.Digest;
BEGIN
  TLSBytes.Init(key); TLSBytes.AppendString(key, "key");
  TLSBytes.Init(msg); TLSBytes.AppendString(msg, "The quick brown fox jumps over the lazy dog");
  TLSSHA256.HMAC(key, msg, d);
  Out.String("HMAC-SHA256   = "); PrintDigest(d); Out.Ln;
  SayResult(DigestEqualsHex(d, "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8"))
END TestHMAC;

PROCEDURE TestHKDF;
VAR ikm, salt, info, prkBuf, okm: TLSBytes.Buffer; prk: TLSSHA256.Digest;
BEGIN
  FillBufferFromHex(ikm, "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b");
  FillBufferFromHex(salt, "000102030405060708090a0b0c");
  FillBufferFromHex(info, "f0f1f2f3f4f5f6f7f8f9");
  TLSHKDF.Extract(salt, ikm, prk);
  Out.String("HKDF PRK      = "); PrintDigest(prk); Out.Ln;
  SayResult(DigestEqualsHex(prk, "077709362c2e32df0ddc3f0dc47bba6390b6c73bb50f9c3122ec844ad7c2b3e5"));
  TLSSHA256.DigestToBuffer(prk, prkBuf);
  TLSHKDF.Expand(prkBuf, info, 42, okm);
  Out.String("HKDF OKM      = "); PrintBuffer(okm); Out.Ln;
  SayResult(BufferEqualsHex(okm, "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865"))
END TestHKDF;

PROCEDURE TestX25519;
VAR scalar, pub, expected: Byte32;
BEGIN
  FillArray32FromHex(scalar, "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a");
  FillArray32FromHex(expected, "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a");
  TLSX25519.ScalarMultBase(pub, scalar);
  Out.String("X25519 base   = "); PrintArray32(pub); Out.Ln;
  SayResult(Array32EqualsHex(pub, "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a"))
END TestX25519;

BEGIN
  TestSHA256;
  TestHMAC;
  TestHKDF;
  TestX25519
END TLSTestCrypto.
