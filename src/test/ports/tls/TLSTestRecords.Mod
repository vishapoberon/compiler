MODULE TLSTestRecords;
IMPORT Out, TLSBytes, TLS13Records;

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

PROCEDURE FillBufferFromString(VAR b: TLSBytes.Buffer; s: ARRAY OF CHAR);
BEGIN
  TLSBytes.Init(b); TLSBytes.AppendString(b, s)
END FillBufferFromString;

PROCEDURE BufferEqualsString(VAR b: TLSBytes.Buffer; s: ARRAY OF CHAR): BOOLEAN;
VAR i, n: LONGINT;
BEGIN
  n := 0; WHILE (n < LEN(s)) & (s[n] # 0X) DO INC(n) END;
  IF b.len # n THEN RETURN FALSE END;
  i := 0;
  WHILE i < n DO IF b.data[i] # s[i] THEN RETURN FALSE END; INC(i) END;
  RETURN TRUE
END BufferEqualsString;

PROCEDURE SayResult(ok: BOOLEAN);
BEGIN
  IF ok THEN Out.String("  OK") ELSE Out.String("  FAIL") END; Out.Ln
END SayResult;

PROCEDURE TestRecordRoundTrip;
VAR key, iv, msg, rec, plain: TLSBytes.Buffer; typ: LONGINT; ok: BOOLEAN;
BEGIN
  FillBufferFromHex(key, "00000000000000000000000000000000");
  FillBufferFromHex(iv,  "000000000000000000000000");
  FillBufferFromString(msg, "hello");
  TLS13Records.ProtectRecord(key, iv, 0, TLS13Records.ApplicationData, msg, rec);
  Out.String("record seq0   = "); PrintBuffer(rec); Out.Ln;
  SayResult((rec.len = 27) & (ORD(rec.data[0]) = TLS13Records.ApplicationData) & (TLSBytes.GetBE16(rec, 3) = 22));
  ok := TLS13Records.OpenRecord(key, iv, 0, rec, typ, plain);
  Out.String("open seq0     = "); IF ok THEN Out.String("true") ELSE Out.String("false") END; Out.Ln;
  SayResult(ok & (typ = TLS13Records.ApplicationData) & BufferEqualsString(plain, "hello"))
END TestRecordRoundTrip;

PROCEDURE TestTamperReject;
VAR key, iv, msg, rec, plain: TLSBytes.Buffer; typ: LONGINT; ok: BOOLEAN;
BEGIN
  FillBufferFromHex(key, "00000000000000000000000000000000");
  FillBufferFromHex(iv,  "000000000000000000000000");
  FillBufferFromString(msg, "hello");
  TLS13Records.ProtectRecord(key, iv, 0, TLS13Records.ApplicationData, msg, rec);
  rec.data[rec.len - 1] := CHR(TLSBytes.XorByte(ORD(rec.data[rec.len - 1]), 1));
  ok := TLS13Records.OpenRecord(key, iv, 0, rec, typ, plain);
  Out.String("tamper reject = "); IF ok THEN Out.String("false") ELSE Out.String("true") END; Out.Ln;
  SayResult(~ok)
END TestTamperReject;

PROCEDURE TestSeqChangesCiphertext;
VAR key, iv, msg, r0, r1: TLSBytes.Buffer; same: BOOLEAN; i: LONGINT;
BEGIN
  FillBufferFromHex(key, "00000000000000000000000000000000");
  FillBufferFromHex(iv,  "000000000000000000000000");
  FillBufferFromString(msg, "hello");
  TLS13Records.ProtectRecord(key, iv, 0, TLS13Records.ApplicationData, msg, r0);
  TLS13Records.ProtectRecord(key, iv, 1, TLS13Records.ApplicationData, msg, r1);
  same := r0.len = r1.len;
  i := 0;
  WHILE same & (i < r0.len) DO
    IF r0.data[i] # r1.data[i] THEN same := FALSE END;
    INC(i)
  END;
  Out.String("seq changes   = "); IF ~same THEN Out.String("true") ELSE Out.String("false") END; Out.Ln;
  SayResult(~same)
END TestSeqChangesCiphertext;

PROCEDURE TestPadding;
VAR key, iv, msg, rec, plain: TLSBytes.Buffer; typ: LONGINT; ok: BOOLEAN;
BEGIN
  FillBufferFromHex(key, "00000000000000000000000000000000");
  FillBufferFromHex(iv,  "000000000000000000000000");
  FillBufferFromString(msg, "abc");
  TLS13Records.ProtectRecordPadded(key, iv, 3, TLS13Records.Handshake, 5, msg, rec);
  ok := TLS13Records.OpenRecord(key, iv, 3, rec, typ, plain);
  Out.String("padding open  = "); IF ok THEN Out.String("true") ELSE Out.String("false") END; Out.Ln;
  SayResult(ok & (typ = TLS13Records.Handshake) & BufferEqualsString(plain, "abc"))
END TestPadding;

PROCEDURE TestSeqLarge;  (* the largest sequence number, 2^31 - 1 *)
VAR key, iv, msg, rec, plain: TLSBytes.Buffer; typ: LONGINT; ok: BOOLEAN; seq: LONGINT;
BEGIN
  FillBufferFromHex(key, "00000000000000000000000000000000");
  FillBufferFromHex(iv,  "000000000000000000000000");
  FillBufferFromString(msg, "hello64");
  seq := 2147483647;
  TLS13Records.ProtectRecord(key, iv, seq, TLS13Records.ApplicationData, msg, rec);
  ok := TLS13Records.OpenRecord(key, iv, seq, rec, typ, plain);
  Out.String("seq max open = "); IF ok THEN Out.String("true") ELSE Out.String("false") END; Out.Ln;
  SayResult(ok & (typ = TLS13Records.ApplicationData) & BufferEqualsString(plain, "hello64"))
END TestSeqLarge;

BEGIN
  TestRecordRoundTrip;
  TestTamperReject;
  TestSeqChangesCiphertext;
  TestSeqLarge;
  TestPadding
END TLSTestRecords.
