MODULE TLSTestEd25519;

(* RFC 8032 section 7.1 vectors and strict Ed25519 API checks. *)
IMPORT TLSEd25519, TLSEd25519Keys, Out;

TYPE Bytes32 = ARRAY 32 OF CHAR; Bytes64 = ARRAY 64 OF CHAR; Bytes256 = ARRAY 256 OF CHAR;

VAR checks, failures: LONGINT;
  seed, publicKey, wantedKey: Bytes32;
  signature, wantedSignature: Bytes64;
  message: Bytes256;

PROCEDURE Check(label: ARRAY OF CHAR; okay: BOOLEAN);
BEGIN
  INC(checks);
  IF ~okay THEN INC(failures); Out.String("FAIL "); Out.String(label); Out.Ln END
END Check;

PROCEDURE Hex(ch: CHAR): LONGINT;
BEGIN IF ch <= "9" THEN RETURN ORD(ch)-ORD("0") END; RETURN ORD(ch)-ORD("a")+10 END Hex;

PROCEDURE Decode(text: ARRAY OF CHAR; VAR bytes: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(bytes)) & (text[i*2] # 0X) DO bytes[i] := CHR(Hex(text[i*2])*16+Hex(text[i*2+1])); INC(i) END
END Decode;

(* a signature given as two halves of 64 hex digits *)
PROCEDURE DecodeSignature(first, second: ARRAY OF CHAR; VAR bytes: Bytes64);
VAR half: Bytes32; i: LONGINT;
BEGIN
  Decode(first, half); i := 0; WHILE i < 32 DO bytes[i] := half[i]; INC(i) END;
  Decode(second, half); i := 0; WHILE i < 32 DO bytes[32+i] := half[i]; INC(i) END
END DecodeSignature;

PROCEDURE Equal(VAR a, b: ARRAY OF CHAR; count: LONGINT): BOOLEAN;
VAR i: LONGINT;
BEGIN i := 0; WHILE (i < count) & (a[i] = b[i]) DO INC(i) END; RETURN i = count END Equal;

PROCEDURE Vector(seedHex, keyHex, messageHex, signatureFirst, signatureSecond: ARRAY OF CHAR; length: LONGINT);
VAR beforeSeed: Bytes32; beforeMessage: Bytes256;
BEGIN
  Decode(seedHex, seed); beforeSeed := seed; Decode(keyHex, wantedKey);
  Decode(messageHex, message); beforeMessage := message; DecodeSignature(signatureFirst, signatureSecond, wantedSignature);
  Check("derive key", TLSEd25519.PublicKey(seed, publicKey));
  Check("RFC public key", Equal(publicKey, wantedKey, 32));
  Check("sign", TLSEd25519.Sign(seed, message, 0, length, signature));
  Check("RFC signature", Equal(signature, wantedSignature, 64));
  Check("verify RFC signature", TLSEd25519.Verify(publicKey, message, 0, length, wantedSignature));
  Check("verify produced signature", TLSEd25519.Verify(publicKey, message, 0, length, signature));
  Check("read-only inputs", Equal(seed, beforeSeed, 32) & Equal(message, beforeMessage, 256));
  signature[63] := CHR((ORD(signature[63])+1) MOD 256);
  Check("reject changed signature", ~TLSEd25519.Verify(publicKey, message, 0, length, signature))
END Vector;

PROCEDURE Strict;
VAR key: Bytes32; sig: Bytes64; i: LONGINT;
BEGIN
  Decode("edd3f55c1a631258d69cf7a2def9de1400000000000000000000000000000010", key);
  sig := wantedSignature; i := 0; WHILE i < 32 DO sig[32+i] := key[i]; INC(i) END;
  Check("reject S equal to order", ~TLSEd25519.Verify(publicKey, message, 0, 2, sig));
  sig[32] := CHR(ORD(sig[32])+1);
  Check("reject S above order", ~TLSEd25519.Verify(publicKey, message, 0, 2, sig));
  sig := wantedSignature; sig[63] := 80X;
  Check("reject high scalar bit", ~TLSEd25519.Verify(publicKey, message, 0, 2, sig));
  Decode("edffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f", key);
  Check("reject y equal to prime", ~TLSEd25519.Verify(key, message, 0, 2, wantedSignature));
  i := 0; WHILE i < 32 DO sig[i] := key[i]; INC(i) END;
  Check("reject noncanonical R", ~TLSEd25519.Verify(publicKey, message, 0, 2, sig));
  i := 0; WHILE i < 32 DO key[i] := 0X; INC(i) END;
  Check("reject order-four key", ~TLSEd25519.Verify(key, message, 0, 2, wantedSignature));
  key[0] := 1X;
  Decode("5866666666666666666666666666666666666666666666666666666666666666", sig);
  i := 32; WHILE i < 64 DO sig[i] := 0X; INC(i) END; sig[32] := 1X;
  Check("reject identity-key forgery", ~TLSEd25519.Verify(key, message, 0, 0, sig));
  key[31] := 80X;
  Check("reject negative zero", ~TLSEd25519.Verify(key, message, 0, 0, sig));
  sig := wantedSignature; i := 0; WHILE i < 32 DO sig[i] := 0X; INC(i) END; sig[0] := 1X;
  Check("reject identity R", ~TLSEd25519.Verify(publicKey, message, 0, 2, sig))
END Strict;

PROCEDURE Bounds;
VAR short: ARRAY 31 OF CHAR; shortSig: ARRAY 63 OF CHAR; longKey: ARRAY 33 OF CHAR;
  longSig: ARRAY 65 OF CHAR; oldSignature: Bytes64; i: LONGINT;
BEGIN
  i := 0; WHILE i < 64 DO signature[i] := 0A5X; INC(i) END; oldSignature := signature;
  Check("short seed", ~TLSEd25519.Sign(short, message, 0, 1, signature));
  Check("long seed", ~TLSEd25519.Sign(longKey, message, 0, 1, signature));
  Check("negative offset", ~TLSEd25519.Sign(seed, message, -1, 1, signature));
  Check("negative length", ~TLSEd25519.Sign(seed, message, 0, -1, signature));
  Check("past-end offset", ~TLSEd25519.Sign(seed, message, 257, 0, signature));
  Check("overflow-safe range", ~TLSEd25519.Sign(seed, message, 1, MAX(LONGINT), signature));
  Check("short signature output", ~TLSEd25519.Sign(seed, message, 0, 1, shortSig));
  Check("failed sign preserves output", Equal(signature, oldSignature, 64));
  Check("short public-key output", ~TLSEd25519.PublicKey(seed, short));
  Check("short key", ~TLSEd25519.Verify(short, message, 0, 0, signature));
  Check("long key", ~TLSEd25519.Verify(longKey, message, 0, 0, signature));
  Check("short signature", ~TLSEd25519.Verify(publicKey, message, 0, 0, shortSig));
  Check("long signature", ~TLSEd25519.Verify(publicKey, message, 0, 0, longSig));
  Check("verify invalid range", ~TLSEd25519.Verify(publicKey, message, 256, 1, signature))
END Bounds;

PROCEDURE Generate;
VAR otherSeed, otherKey, restored: Bytes32; small: ARRAY 1 OF CHAR; i: LONGINT; cleared: BOOLEAN;
BEGIN
  Check("generate key pair", TLSEd25519Keys.Generate(seed, publicKey));
  Check("generated public key", TLSEd25519.PublicKey(seed, restored) & Equal(publicKey, restored, 32));
  Check("generate another pair", TLSEd25519Keys.Generate(otherSeed, otherKey));
  Check("independent seeds", ~Equal(seed, otherSeed, 32));
  Check("generated signing", TLSEd25519.Sign(seed, message, 0, 0, signature) &
    TLSEd25519.Verify(publicKey, message, 0, 0, signature));
  Check("generation rejects aliasing", ~TLSEd25519Keys.Generate(seed, seed));
  Check("generation rejects wrong size", ~TLSEd25519Keys.Generate(small, publicKey));
  cleared := small[0] = 0X; i := 0;
  WHILE i < 32 DO cleared := cleared & (publicKey[i] = 0X); INC(i) END;
  Check("generation failure clears outputs", cleared)
END Generate;

BEGIN
  Vector("9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60",
    "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a", "",
    "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e06522490155",
    "5fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b", 0);
  Vector("4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb",
    "3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c", "72",
    "92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da",
    "085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00", 1);
  Vector("c5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7",
    "fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025", "af82",
    "6291d657deec24024827e69c3abe01a30ce548a284743a445e3680d7db5ac3ac",
    "18ff9b538d16f290ae67f760984dc6594a7c15e9716ed28dc027beceea1ec40a", 2);
  Strict; Bounds; Generate;
  Out.String("TLSTestEd25519: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(failures, 0); Out.String(" failed"); Out.Ln;
  IF failures # 0 THEN HALT(100) END
END TLSTestEd25519.
