MODULE TLSTestKeys;
IMPORT Out, TLSBytes, TLSSHA256, TLS13Keys;

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
  i := 0; WHILE i < b.len DO PrintByte(b.data[i]); INC(i) END
END PrintBuffer;

PROCEDURE FillBufferFromHex(VAR b: TLSBytes.Buffer; hex: ARRAY OF CHAR);
VAR i, n: LONGINT;
BEGIN
  TLSBytes.Init(b);
  n := 0; WHILE (n < LEN(hex)) & (hex[n] # 0X) DO INC(n) END;
  i := 0;
  WHILE i + 1 < n DO
    TLSBytes.AppendByte(b, HexVal(hex[i]) * 16 + HexVal(hex[i+1]));
    INC(i, 2)
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
  IF ok THEN Out.String("  OK") ELSE Out.String("  FAIL") END;
  Out.Ln
END SayResult;

PROCEDURE MakeSeq32(VAR b: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  TLSBytes.Init(b);
  i := 0; WHILE i < 32 DO TLSBytes.AppendByte(b, i); INC(i) END
END MakeSeq32;

PROCEDURE TestKeySchedule;
VAR
  shared, messages, th, early, hs, cSec, sSec, ck, civ, sk, siv, cf, sf, master: TLSBytes.Buffer;
BEGIN
  MakeSeq32(shared);
  TLSBytes.Init(messages); TLSBytes.AppendString(messages, "client hello and server hello");
  TLS13Keys.HashMessages(messages, th);
  Out.String("transcript   = "); PrintBuffer(th); Out.Ln;
  SayResult(BufferEqualsHex(th, "35cd5006814d6ca3c30d99f74c9d478b34b69899ce69db7b29501ccc1a3549da"));

  TLS13Keys.InitialEarlySecretNoPSK(early);
  Out.String("early secret = "); PrintBuffer(early); Out.Ln;
  SayResult(BufferEqualsHex(early, "33ad0a1c607ec03b09e6cd9893680ce210adf300aa1f2660e1b22e10f170f92a"));

  TLS13Keys.HandshakeSecret(shared, hs);
  Out.String("hs secret    = "); PrintBuffer(hs); Out.Ln;
  SayResult(BufferEqualsHex(hs, "ddbe37614d014a8c19db0a47955ee6930b3ee727c408386ba274344962b0e015"));

  TLS13Keys.HandshakeTrafficSecrets(shared, th, cSec, sSec);
  Out.String("c hs traffic = "); PrintBuffer(cSec); Out.Ln;
  SayResult(BufferEqualsHex(cSec, "2ba90b81efab4a8e22190c70cffd6711e51aca5e15595ff10526567cb22fbd38"));
  Out.String("s hs traffic = "); PrintBuffer(sSec); Out.Ln;
  SayResult(BufferEqualsHex(sSec, "2c86366f89fc96ed08ed0db85b3d24ea69d271a94cf4421797a1f749084ab038"));

  TLS13Keys.HandshakeKeys(shared, th, ck, civ, sk, siv, cf, sf);
  Out.String("client key   = "); PrintBuffer(ck); Out.Ln;
  SayResult(BufferEqualsHex(ck, "991bb52e9c7ad7abf3097ee98706ceb7"));
  Out.String("client iv    = "); PrintBuffer(civ); Out.Ln;
  SayResult(BufferEqualsHex(civ, "99443d8465f2d0397275bcd2"));
  Out.String("client fin   = "); PrintBuffer(cf); Out.Ln;
  SayResult(BufferEqualsHex(cf, "7f01d594736f168ab337733b69c901e9b3bfe4ef8f46c4482bdbae288dbe0fe4"));
  Out.String("server key   = "); PrintBuffer(sk); Out.Ln;
  SayResult(BufferEqualsHex(sk, "6fa0c22080193c2d46f56167dcc672a6"));
  Out.String("server iv    = "); PrintBuffer(siv); Out.Ln;
  SayResult(BufferEqualsHex(siv, "beb6af1af4776dbea8c44b81"));
  Out.String("server fin   = "); PrintBuffer(sf); Out.Ln;
  SayResult(BufferEqualsHex(sf, "fb79010332a2abccc213b65364071965a5977b86c3e4dd628229a2eaef328900"));

  TLS13Keys.MasterSecret(hs, master);
  Out.String("master       = "); PrintBuffer(master); Out.Ln;
  SayResult(BufferEqualsHex(master, "055796c9a2f048dd920b01351ba00d131ba528efa37749efb03e31b643c615b2"))
END TestKeySchedule;

BEGIN
  TestKeySchedule
END TLSTestKeys.
