MODULE TLSTestAESGCM;
IMPORT Out, TLSBytes, TLSAESGCM;

PROCEDURE HexDigit(n: LONGINT): CHAR;
BEGIN
  IF n < 10 THEN RETURN CHR(ORD('0') + n) ELSE RETURN CHR(ORD('a') + n - 10) END
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
  x := ORD(c); Out.Char(HexDigit(x DIV 16)); Out.Char(HexDigit(x MOD 16))
END PrintByte;

PROCEDURE PrintBuffer(VAR b: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  i := 0; WHILE i < b.len DO PrintByte(b.data[i]); INC(i) END
END PrintBuffer;

PROCEDURE FillBufferFromHex(VAR b: TLSBytes.Buffer; hex: ARRAY OF CHAR);
VAR i, n: LONGINT;
BEGIN
  TLSBytes.Init(b); n := 0;
  WHILE (n < LEN(hex)) & (hex[n] # 0X) DO INC(n) END;
  i := 0;
  WHILE i + 1 < n DO
    TLSBytes.AppendByte(b, HexVal(hex[i]) * 16 + HexVal(hex[i+1])); INC(i, 2)
  END
END FillBufferFromHex;

PROCEDURE BufferEqualsHex(VAR b: TLSBytes.Buffer; expected: ARRAY OF CHAR): BOOLEAN;
VAR i, n: LONGINT;
BEGIN
  n := 0; WHILE (n < LEN(expected)) & (expected[n] # 0X) DO INC(n) END;
  IF b.len * 2 # n THEN RETURN FALSE END;
  i := 0;
  WHILE i < b.len DO
    IF HexDigit(ORD(b.data[i]) DIV 16) # expected[2*i] THEN RETURN FALSE END;
    IF HexDigit(ORD(b.data[i]) MOD 16) # expected[2*i+1] THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END BufferEqualsHex;

PROCEDURE SayResult(ok: BOOLEAN);
BEGIN
  IF ok THEN Out.String("  OK") ELSE Out.String("  FAIL") END; Out.Ln
END SayResult;

PROCEDURE TestAESBlock;
VAR key, plain, cipher: TLSBytes.Buffer;
BEGIN
  FillBufferFromHex(key, "000102030405060708090a0b0c0d0e0f");
  FillBufferFromHex(plain, "00112233445566778899aabbccddeeff");
  TLSAESGCM.AES128EncryptBlockBuffer(key, plain, cipher);
  Out.String("AES-128 block = "); PrintBuffer(cipher); Out.Ln;
  SayResult(BufferEqualsHex(cipher, "69c4e0d86a7b0430d8cdb78070b4c55a"))
END TestAESBlock;

PROCEDURE TestGCMEmpty;
VAR key, nonce, aad, msg, packet, plain: TLSBytes.Buffer; ok: BOOLEAN;
BEGIN
  FillBufferFromHex(key, "00000000000000000000000000000000");
  FillBufferFromHex(nonce, "000000000000000000000000");
  TLSBytes.Init(aad); TLSBytes.Init(msg);
  TLSAESGCM.AES128GCMEncrypt(key, msg, nonce, aad, packet);
  Out.String("GCM empty     = "); PrintBuffer(packet); Out.Ln;
  SayResult(BufferEqualsHex(packet, "58e2fccefa7e3061367f1d57a4e7455a"));
  ok := TLSAESGCM.AES128GCMDecrypt(key, packet, nonce, aad, plain);
  Out.String("GCM empty dec = "); IF ok THEN Out.String("true") ELSE Out.String("false") END; Out.Ln;
  SayResult(ok & (plain.len = 0))
END TestGCMEmpty;

PROCEDURE TestGCMOneBlock;
VAR key, nonce, aad, msg, packet, plain: TLSBytes.Buffer; ok: BOOLEAN;
BEGIN
  FillBufferFromHex(key, "00000000000000000000000000000000");
  FillBufferFromHex(nonce, "000000000000000000000000");
  TLSBytes.Init(aad);
  FillBufferFromHex(msg, "00000000000000000000000000000000");
  TLSAESGCM.AES128GCMEncrypt(key, msg, nonce, aad, packet);
  Out.String("GCM oneblock  = "); PrintBuffer(packet); Out.Ln;
  SayResult(BufferEqualsHex(packet, "0388dace60b6a392f328c2b971b2fe78ab6e47d42cec13bdf53a67b21257bddf"));
  ok := TLSAESGCM.AES128GCMDecrypt(key, packet, nonce, aad, plain);
  Out.String("GCM one dec   = "); IF ok THEN Out.String("true") ELSE Out.String("false") END; Out.Ln;
  SayResult(ok & BufferEqualsHex(plain, "00000000000000000000000000000000"))
END TestGCMOneBlock;

PROCEDURE TestGCMAAD;
VAR key, nonce, aad, msg, packet, plain: TLSBytes.Buffer; ok: BOOLEAN;
BEGIN
  FillBufferFromHex(key, "feffe9928665731c6d6a8f9467308308");
  FillBufferFromHex(nonce, "cafebabefacedbaddecaf888");
  FillBufferFromHex(aad, "feedfacedeadbeeffeedfacedeadbeefabaddad2");
  FillBufferFromHex(msg, "d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a72");
  TLSAESGCM.AES128GCMEncrypt(key, msg, nonce, aad, packet);
  Out.String("GCM aad       = "); PrintBuffer(packet); Out.Ln;
  SayResult(BufferEqualsHex(packet, "42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12ee13e1434285a9426addfbfc270d27f16"));
  ok := TLSAESGCM.AES128GCMDecrypt(key, packet, nonce, aad, plain);
  Out.String("GCM aad dec   = "); IF ok THEN Out.String("true") ELSE Out.String("false") END; Out.Ln;
  SayResult(ok & BufferEqualsHex(plain, "d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a72"))
END TestGCMAAD;

BEGIN
  TestAESBlock;
  TestGCMEmpty;
  TestGCMOneBlock;
  TestGCMAAD
END TLSTestAESGCM.
