MODULE TLSTestFinished;
IMPORT Out, TLSBytes, TLS13Keys, TLS13Finished;

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

PROCEDURE TestFinished;
VAR
  shared, messages, th: TLSBytes.Buffer;
  ck, civ, sk, siv, cf, sf: TLSBytes.Buffer;
  cv, sv, cmsg, smsg, tampered, transcript: TLSBytes.Buffer;
BEGIN
  MakeSeq32(shared);
  TLSBytes.Init(messages); TLSBytes.AppendString(messages, "client hello and server hello");
  TLS13Keys.HashMessages(messages, th);
  TLS13Keys.HandshakeKeys(shared, th, ck, civ, sk, siv, cf, sf);

  TLS13Finished.ComputeVerifyData(cf, th, cv);
  Out.String("client verify = "); PrintBuffer(cv); Out.Ln;
  SayResult(BufferEqualsHex(cv, "6b7f4dc4913200e0a3daf72d8df705b95a6b1290ba3195d975741fffbc6da4a3"));

  TLS13Finished.ComputeVerifyData(sf, th, sv);
  Out.String("server verify = "); PrintBuffer(sv); Out.Ln;
  SayResult(BufferEqualsHex(sv, "75cb53d29b55506a5b394b0373f17f7a4836fc460b6b5aeac770c80562a0bf03"));

  TLS13Finished.BuildFinishedMessage(cf, th, cmsg);
  Out.String("client finish = "); PrintBuffer(cmsg); Out.Ln;
  SayResult(BufferEqualsHex(cmsg, "140000206b7f4dc4913200e0a3daf72d8df705b95a6b1290ba3195d975741fffbc6da4a3"));

  TLS13Finished.BuildFinishedMessage(sf, th, smsg);
  Out.String("server finish = "); PrintBuffer(smsg); Out.Ln;
  SayResult(BufferEqualsHex(smsg, "1400002075cb53d29b55506a5b394b0373f17f7a4836fc460b6b5aeac770c80562a0bf03"));

  Out.String("verify server = ");
  SayResult(TLS13Finished.VerifyFinishedMessage(smsg, sf, th));

  TLSBytes.Copy(smsg, tampered);
  tampered.data[tampered.len-1] := CHR(TLSBytes.XorByte(ORD(tampered.data[tampered.len-1]), 1));
  Out.String("tamper reject = ");
  SayResult(~TLS13Finished.VerifyFinishedMessage(tampered, sf, th));

  TLSBytes.Copy(messages, transcript);
  TLS13Finished.AppendToTranscript(transcript, smsg);
  Out.String("transcript len = "); Out.Int(transcript.len, 0); Out.Ln;
  SayResult(transcript.len = messages.len + smsg.len)
END TestFinished;

BEGIN
  TestFinished
END TLSTestFinished.
