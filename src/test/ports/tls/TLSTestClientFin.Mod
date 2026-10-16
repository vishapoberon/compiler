MODULE TLSTestClientFin;
IMPORT Out, TLSBytes, TLS13Keys, TLS13Records, TLS13Finished, TLS13EncHandshake, TLS13Certs, TLSX509, TLSASN1, TLSPEM, TLSBase64, TLS13ClientFinished;

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

PROCEDURE BuildServerSide(VAR shared, transcript0: TLSBytes.Buffer;
                          VAR clientKey, clientIV, serverKey, serverIV, clientFinKey, serverFinKey: TLSBytes.Buffer;
                          VAR transcriptAfterServer: TLSBytes.Buffer): BOOLEAN;
VAR th, ee, fin, plain, record, t: TLSBytes.Buffer; saw, ok, refused: BOOLEAN;
BEGIN
  TLS13Keys.HashMessages(transcript0, th);
  TLS13Keys.HandshakeKeys(shared, th, clientKey, clientIV, serverKey, serverIV, clientFinKey, serverFinKey);

  TLS13EncHandshake.BuildEmptyEncryptedExtensions(ee);
  TLSBytes.Copy(transcript0, transcriptAfterServer);
  TLSBytes.Append(transcriptAfterServer, ee);
  TLS13Keys.HashMessages(transcriptAfterServer, th);
  TLS13Finished.BuildFinishedMessage(serverFinKey, th, fin);

  TLSBytes.Init(plain);
  TLSBytes.Append(plain, ee);
  TLSBytes.Append(plain, fin);
  TLS13Records.ProtectRecord(serverKey, serverIV, 0, TLS13Records.Handshake, plain, record);

  (* without Certificate and CertificateVerify the client refuses this flight *)
  TLSBytes.Copy(transcript0, t);
  TLS13EncHandshake.ResetState;
  refused := ~(TLS13EncHandshake.OpenServerHandshakeRecord(serverKey, serverIV, 0, record, t, serverFinKey, saw, ok) & saw & ok);
  TLSBytes.Copy(transcript0, transcriptAfterServer);
  TLSBytes.Append(transcriptAfterServer, ee);
  TLSBytes.Append(transcriptAfterServer, fin);
  RETURN refused
END BuildServerSide;

PROCEDURE TestClientFinished;
VAR
  shared, transcript0, transcriptAfterServer, transcriptAfterClient: TLSBytes.Buffer;
  clientKey, clientIV, serverKey, serverIV, clientFinKey, serverFinKey: TLSBytes.Buffer;
  rec, fin, openedPlain, th: TLSBytes.Buffer;
  ok, opened, verified: BOOLEAN;
  innerType: LONGINT;
BEGIN
  MakeSeq32(shared);
  TLSBytes.Init(transcript0);
  TLSBytes.AppendString(transcript0, "client hello and server hello");

  ok := BuildServerSide(shared, transcript0, clientKey, clientIV, serverKey, serverIV, clientFinKey, serverFinKey, transcriptAfterServer);
  Out.String("no cert rej  = "); SayResult(ok);
  Out.String("server tr n  = "); Out.Int(transcriptAfterServer.len, 0); Out.Ln;
  SayResult(transcriptAfterServer.len = 71);

  TLS13ClientFinished.BuildClientFinishedRecord(clientKey, clientIV, 0, transcriptAfterServer, clientFinKey, rec, fin);
  Out.String("client fin   = "); PrintBuffer(fin); Out.Ln;
  SayResult((fin.len = 36) & (ORD(fin.data[0]) = TLS13Finished.FinishedType) & (TLSBytes.GetBE24(fin, 1) = 32));

  Out.String("client rec   = "); PrintBuffer(rec); Out.Ln;
  SayResult((rec.len > 5) & (ORD(rec.data[0]) = TLS13Records.ApplicationData));

  opened := TLS13Records.OpenRecord(clientKey, clientIV, 0, rec, innerType, openedPlain);
  Out.String("open client  = "); SayResult(opened);
  Out.String("inner type   = "); SayResult(opened & (innerType = TLS13Records.Handshake));
  Out.String("plain equal  = "); SayResult(opened & TLSBytes.EqualConstTime(openedPlain, fin));

  TLS13Keys.HashMessages(transcriptAfterServer, th);
  verified := TLS13Finished.VerifyFinishedMessage(openedPlain, clientFinKey, th);
  Out.String("verify cli   = "); SayResult(verified);

  TLSBytes.Copy(transcriptAfterServer, transcriptAfterClient);
  TLS13ClientFinished.AppendClientFinished(transcriptAfterClient, fin);
  Out.String("client tr n  = "); Out.Int(transcriptAfterClient.len, 0); Out.Ln;
  SayResult(transcriptAfterClient.len = 107);

  opened := TLS13Records.OpenRecord(clientKey, clientIV, 1, rec, innerType, openedPlain);
  Out.String("wrong seq rej= "); SayResult(~opened)
END TestClientFinished;

BEGIN
  TestClientFinished
END TLSTestClientFin.
