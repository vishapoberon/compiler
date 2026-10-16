MODULE TLSTestApplication;
IMPORT Out, TLSBytes, TLS13Keys, TLS13Finished, TLS13EncHandshake, TLS13ClientFinished, TLS13Certs, TLSX509, TLSASN1, TLSPEM, TLSBase64,
       TLS13Application;

PROCEDURE HexDigit(n: LONGINT): CHAR;
BEGIN
  IF n < 10 THEN RETURN CHR(ORD('0') + n)
  ELSE RETURN CHR(ORD('a') + n - 10)
  END
END HexDigit;

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

PROCEDURE BuildFullHandshake(VAR shared, transcriptAfterClient, master: TLSBytes.Buffer);
VAR
  transcript0, th, hs, ee, serverFin, clientFin: TLSBytes.Buffer;
  clientKey, clientIV, serverKey, serverIV, clientFinKey, serverFinKey: TLSBytes.Buffer;
BEGIN
  MakeSeq32(shared);
  TLSBytes.Init(transcript0);
  TLSBytes.AppendString(transcript0, "client hello and server hello");

  TLS13Keys.HashMessages(transcript0, th);
  TLS13Keys.HandshakeKeys(shared, th, clientKey, clientIV, serverKey, serverIV, clientFinKey, serverFinKey);

  TLS13EncHandshake.BuildEmptyEncryptedExtensions(ee);
  TLSBytes.Copy(transcript0, transcriptAfterClient);
  TLSBytes.Append(transcriptAfterClient, ee);
  TLS13Keys.HashMessages(transcriptAfterClient, th);
  TLS13Finished.BuildFinishedMessage(serverFinKey, th, serverFin);
  TLSBytes.Append(transcriptAfterClient, serverFin);

  TLS13ClientFinished.BuildClientFinishedMessage(transcriptAfterClient, clientFinKey, clientFin);
  TLSBytes.Append(transcriptAfterClient, clientFin);

  TLS13Keys.HandshakeSecret(shared, hs);
  TLS13Keys.MasterSecret(hs, master)
END BuildFullHandshake;

PROCEDURE TestApplication;
VAR
  shared, transcript, master, th, cSec, sSec, ck, civ, sk, siv: TLSBytes.Buffer;
  req, rec, opened, rec2: TLSBytes.Buffer;
  ok: BOOLEAN;
BEGIN
  BuildFullHandshake(shared, transcript, master);
  Out.String("handshake n  = "); Out.Int(transcript.len, 0); Out.Ln;
  SayResult(transcript.len = 107);

  TLS13Keys.HashMessages(transcript, th);
  Out.String("final hash   = "); PrintBuffer(th); Out.Ln;
  SayResult(BufferEqualsHex(th, "cd7001a4fa36abf094ad128ae7cf5afe9a25f6fd46ad62eb379c0b23d6f8e246"));

  TLS13Application.ApplicationTrafficSecrets(master, transcript, cSec, sSec);
  Out.String("c app secret = "); PrintBuffer(cSec); Out.Ln;
  SayResult(BufferEqualsHex(cSec, "76e8c3b5472d0f4ec7ca2be1784cff6bfd0af0ea24a450388e0f954d96e9f05f"));
  Out.String("s app secret = "); PrintBuffer(sSec); Out.Ln;
  SayResult(BufferEqualsHex(sSec, "8e6e6110ba41786781d961ad19106dcf02ee4f5fd0e79c2997b22a755e813def"));

  TLS13Application.ApplicationKeys(master, transcript, ck, civ, sk, siv);
  Out.String("client key   = "); PrintBuffer(ck); Out.Ln;
  SayResult(BufferEqualsHex(ck, "11f9c341f17be5d881f526e108d2fea9"));
  Out.String("client iv    = "); PrintBuffer(civ); Out.Ln;
  SayResult(BufferEqualsHex(civ, "b95426009e5767f02cf3a09a"));
  Out.String("server key   = "); PrintBuffer(sk); Out.Ln;
  SayResult(BufferEqualsHex(sk, "ce051411fd5b6f3f3a273567e1be8e34"));
  Out.String("server iv    = "); PrintBuffer(siv); Out.Ln;
  SayResult(BufferEqualsHex(siv, "cf7e606e8a72e806fd429ca8"));

  TLSBytes.Init(req);
  TLSBytes.AppendString(req, "GET / HTTP/1.1"); TLSBytes.AppendByte(req, 13); TLSBytes.AppendByte(req, 10);
  TLSBytes.AppendString(req, "Host: example.com"); TLSBytes.AppendByte(req, 13); TLSBytes.AppendByte(req, 10);
  TLSBytes.AppendByte(req, 13); TLSBytes.AppendByte(req, 10);

  TLS13Application.ProtectApplicationData(ck, civ, 0, req, rec);
  Out.String("app record   = "); PrintBuffer(rec); Out.Ln;
  SayResult(BufferEqualsHex(rec, "17030300366babac42dc0f72bb0d0e3528a387a3f17ab07668a07832a3f7c8d69a7f143aecc34dfe347aa3ecaae894ecb4864032fccf934a85f264"));

  ok := TLS13Application.OpenApplicationData(ck, civ, 0, rec, opened);
  Out.String("open app     = "); SayResult(ok);
  Out.String("plain equal  = "); SayResult(ok & TLSBytes.EqualConstTime(opened, req));

  ok := TLS13Application.OpenApplicationData(ck, civ, 1, rec, opened);
  Out.String("wrong seq rej= "); SayResult(~ok);

  TLS13Application.ProtectApplicationDataPadded(ck, civ, 1, 8, req, rec2);
  ok := TLS13Application.OpenApplicationData(ck, civ, 1, rec2, opened);
  Out.String("padded open  = "); SayResult(ok & TLSBytes.EqualConstTime(opened, req))
END TestApplication;

BEGIN
  TestApplication
END TLSTestApplication.
