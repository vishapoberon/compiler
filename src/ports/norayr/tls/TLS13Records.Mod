MODULE TLS13Records;
IMPORT TLSBytes, TLSAESGCM;

CONST
  ChangeCipherSpec* = 20;
  Alert* = 21;
  Handshake* = 22;
  ApplicationData* = 23;

  LegacyMajor = 3;
  LegacyMinor = 3;
  HeaderLen* = 5;
  TagLen* = 16;

PROCEDURE BuildAAD*(encryptedLen: LONGINT; VAR aad: TLSBytes.Buffer);
BEGIN
  TLSBytes.Init(aad);
  TLSBytes.AppendByte(aad, ApplicationData);
  TLSBytes.AppendByte(aad, LegacyMajor);
  TLSBytes.AppendByte(aad, LegacyMinor);
  TLSBytes.PutBE16(aad, encryptedLen)
END BuildAAD;

PROCEDURE MakeNonce*(VAR staticIV: TLSBytes.Buffer; seq: LONGINT; VAR nonce: TLSBytes.Buffer);
VAR seqBytes: TLSBytes.Buffer;
BEGIN
  IF staticIV.len # 12 THEN HALT(80) END;
  TLSBytes.SeqNum12(seq, seqBytes);  (* 2^31 records per direction are plenty *)
  TLSBytes.Xor12(staticIV, seqBytes, nonce)
END MakeNonce;

PROCEDURE AppendHeader*(contentType, length: LONGINT; VAR dst: TLSBytes.Buffer);
BEGIN
  TLSBytes.AppendByte(dst, contentType);
  TLSBytes.AppendByte(dst, LegacyMajor);
  TLSBytes.AppendByte(dst, LegacyMinor);
  TLSBytes.PutBE16(dst, length)
END AppendHeader;

PROCEDURE ProtectRecord*(VAR key, staticIV: TLSBytes.Buffer; seq: LONGINT; innerType: LONGINT; VAR plain: TLSBytes.Buffer; VAR record: TLSBytes.Buffer);
VAR nonce, aad, inner, encrypted: TLSBytes.Buffer;
BEGIN
  TLSBytes.Copy(plain, inner);
  TLSBytes.AppendByte(inner, innerType);
  MakeNonce(staticIV, seq, nonce);
  BuildAAD(inner.len + TagLen, aad);
  TLSAESGCM.AES128GCMEncrypt(key, inner, nonce, aad, encrypted);
  TLSBytes.Init(record);
  AppendHeader(ApplicationData, encrypted.len, record);
  TLSBytes.Append(record, encrypted)
END ProtectRecord;

PROCEDURE ProtectRecordPadded*(VAR key, staticIV: TLSBytes.Buffer; seq: LONGINT; innerType, paddingLen: LONGINT; VAR plain: TLSBytes.Buffer; VAR record: TLSBytes.Buffer);
VAR nonce, aad, inner, encrypted: TLSBytes.Buffer; i: LONGINT;
BEGIN
  TLSBytes.Copy(plain, inner);
  TLSBytes.AppendByte(inner, innerType);
  i := 0;
  WHILE i < paddingLen DO TLSBytes.AppendByte(inner, 0); INC(i) END;
  MakeNonce(staticIV, seq, nonce);
  BuildAAD(inner.len + TagLen, aad);
  TLSAESGCM.AES128GCMEncrypt(key, inner, nonce, aad, encrypted);
  TLSBytes.Init(record);
  AppendHeader(ApplicationData, encrypted.len, record);
  TLSBytes.Append(record, encrypted)
END ProtectRecordPadded;

PROCEDURE OpenRecord*(VAR key, staticIV: TLSBytes.Buffer; seq: LONGINT; VAR record: TLSBytes.Buffer; VAR innerType: LONGINT; VAR plain: TLSBytes.Buffer): BOOLEAN;
VAR length, i: LONGINT; nonce, aad, encrypted, inner: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(plain); innerType := -1;
  IF record.len < HeaderLen + TagLen THEN RETURN FALSE END;
  IF ORD(record.data[0]) # ApplicationData THEN RETURN FALSE END;
  IF ORD(record.data[1]) # LegacyMajor THEN RETURN FALSE END;
  IF ORD(record.data[2]) # LegacyMinor THEN RETURN FALSE END;
  length := TLSBytes.GetBE16(record, 3);
  IF length # record.len - HeaderLen THEN RETURN FALSE END;

  TLSBytes.Slice(record, HeaderLen, length, encrypted);
  MakeNonce(staticIV, seq, nonce);
  BuildAAD(length, aad);
  IF ~TLSAESGCM.AES128GCMDecrypt(key, encrypted, nonce, aad, inner) THEN RETURN FALSE END;

  IF inner.len < 1 THEN RETURN FALSE END;
  i := inner.len - 1;
  WHILE (i >= 0) & (ORD(inner.data[i]) = 0) DO DEC(i) END;
  IF i < 0 THEN RETURN FALSE END;
  innerType := ORD(inner.data[i]);
  TLSBytes.Slice(inner, 0, i, plain);
  RETURN TRUE
END OpenRecord;

PROCEDURE IsHandshakeRecord*(VAR record: TLSBytes.Buffer): BOOLEAN;
BEGIN
  RETURN (record.len >= HeaderLen) & (ORD(record.data[0]) = Handshake) & (ORD(record.data[1]) = LegacyMajor) & (ORD(record.data[2]) = LegacyMinor)
END IsHandshakeRecord;

PROCEDURE IsEncryptedRecord*(VAR record: TLSBytes.Buffer): BOOLEAN;
BEGIN
  RETURN (record.len >= HeaderLen) & (ORD(record.data[0]) = ApplicationData) & (ORD(record.data[1]) = LegacyMajor) & (ORD(record.data[2]) = LegacyMinor)
END IsEncryptedRecord;

END TLS13Records.
