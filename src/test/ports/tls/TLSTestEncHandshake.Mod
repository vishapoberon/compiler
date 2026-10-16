MODULE TLSTestEncHandshake;
IMPORT Out, TLSBytes, TLS13Keys, TLS13Records, TLS13Finished, TLS13EncHandshake, TLS13Certs, TLSX509, TLSASN1, TLSPEM, TLSBase64;

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

PROCEDURE TestEncryptedHandshake;
VAR
  shared, transcript0, transcriptForFinished, transcriptAfter, th: TLSBytes.Buffer;
  clientKey, clientIV, serverKey, serverIV, clientFinKey, serverFinKey: TLSBytes.Buffer;
  ee, fin, plain, record, tampered: TLSBytes.Buffer;
  saw, ok, opened: BOOLEAN;
  innerType, n: LONGINT;
BEGIN
  MakeSeq32(shared);
  TLSBytes.Init(transcript0);
  TLSBytes.AppendString(transcript0, "client hello and server hello");
  TLS13Keys.HashMessages(transcript0, th);
  TLS13Keys.HandshakeKeys(shared, th, clientKey, clientIV, serverKey, serverIV, clientFinKey, serverFinKey);

  TLS13EncHandshake.BuildEmptyEncryptedExtensions(ee);
  TLSBytes.Copy(transcript0, transcriptForFinished);
  TLSBytes.Append(transcriptForFinished, ee);
  TLS13Keys.HashMessages(transcriptForFinished, th);
  TLS13Finished.BuildFinishedMessage(serverFinKey, th, fin);

  TLSBytes.Init(plain);
  TLSBytes.Append(plain, ee);
  TLSBytes.Append(plain, fin);
  TLS13Records.ProtectRecord(serverKey, serverIV, 0, TLS13Records.Handshake, plain, record);

  Out.String("enc hs rec   = "); PrintBuffer(record); Out.Ln;
  SayResult((record.len > 5) & (ORD(record.data[0]) = TLS13Records.ApplicationData));

  (* EncryptedExtensions and then Finished, without Certificate and CertificateVerify: refused
     (RFC 8446 2: without a PSK the server must authenticate) *)
  TLSBytes.Copy(transcript0, transcriptAfter);
  TLS13EncHandshake.ResetState;
  opened := TLS13EncHandshake.OpenServerHandshakeRecord(serverKey, serverIV, 0, record, transcriptAfter, serverFinKey, saw, ok);
  Out.String("no certificate refused = "); SayResult(~opened & ~saw);

  opened := TLS13Records.OpenRecord(serverKey, serverIV, 0, record, innerType, plain);
  Out.String("inner type   = "); SayResult(opened & (innerType = TLS13Records.Handshake));
  Out.String("plain parse  = ");
  n := 0;
  IF TLS13EncHandshake.MessageTotalLen(plain, 0, n) THEN
    SayResult((TLS13EncHandshake.MessageType(plain, 0) = TLS13EncHandshake.EncryptedExtensions) & (n = ee.len))
  ELSE
    SayResult(FALSE)
  END;

  TLSBytes.Copy(record, tampered);
  tampered.data[tampered.len - 1] := CHR((ORD(tampered.data[tampered.len - 1]) + 1) MOD 256);
  TLSBytes.Copy(transcript0, transcriptAfter);
  TLS13EncHandshake.ResetState;
  opened := TLS13EncHandshake.OpenServerHandshakeRecord(serverKey, serverIV, 0, tampered, transcriptAfter, serverFinKey, saw, ok);
  Out.String("tamper rej   = "); SayResult(~opened);

  TLSBytes.Copy(transcript0, transcriptAfter);
  opened := TLS13EncHandshake.OpenServerHandshakeRecord(serverKey, serverIV, 1, record, transcriptAfter, serverFinKey, saw, ok);
  Out.String("wrong seq rej= "); SayResult(~opened)
END TestEncryptedHandshake;

BEGIN
  TestEncryptedHandshake
END TLSTestEncHandshake.
