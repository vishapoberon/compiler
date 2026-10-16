MODULE TLSTestX509;
IMPORT Out, TLSBytes, TLSASN1, TLSX509;

VAR der: TLSBytes.Buffer; info: TLSX509.CertInfo; oid: ARRAY 80 OF CHAR;

PROCEDURE Hex(VAR b: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE i < b.len DO
    Out.Hex(ORD(b.data[i]), 2);
    INC(i)
  END
END Hex;

PROCEDURE OK(name: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  Out.String(name);
  IF ok THEN Out.String(" OK") ELSE Out.String(" FAIL") END;
  Out.Ln
END OK;

PROCEDURE AddAlgSha256RSA(VAR b: TLSBytes.Buffer);
BEGIN
  (* SEQUENCE { OID 1.2.840.113549.1.1.11, NULL } *)
  TLSBytes.AppendByte(b, 30H); TLSBytes.AppendByte(b, 0DH);
  TLSBytes.AppendByte(b, 06H); TLSBytes.AppendByte(b, 09H);
  TLSBytes.AppendByte(b, 2AH); TLSBytes.AppendByte(b, 86H); TLSBytes.AppendByte(b, 48H);
  TLSBytes.AppendByte(b, 86H); TLSBytes.AppendByte(b, 0F7H); TLSBytes.AppendByte(b, 0DH);
  TLSBytes.AppendByte(b, 01H); TLSBytes.AppendByte(b, 01H); TLSBytes.AppendByte(b, 0BH);
  TLSBytes.AppendByte(b, 05H); TLSBytes.AppendByte(b, 00H)
END AddAlgSha256RSA;

PROCEDURE AddAlgRSA(VAR b: TLSBytes.Buffer);
BEGIN
  (* SEQUENCE { OID 1.2.840.113549.1.1.1, NULL } *)
  TLSBytes.AppendByte(b, 30H); TLSBytes.AppendByte(b, 0DH);
  TLSBytes.AppendByte(b, 06H); TLSBytes.AppendByte(b, 09H);
  TLSBytes.AppendByte(b, 2AH); TLSBytes.AppendByte(b, 86H); TLSBytes.AppendByte(b, 48H);
  TLSBytes.AppendByte(b, 86H); TLSBytes.AppendByte(b, 0F7H); TLSBytes.AppendByte(b, 0DH);
  TLSBytes.AppendByte(b, 01H); TLSBytes.AppendByte(b, 01H); TLSBytes.AppendByte(b, 01H);
  TLSBytes.AppendByte(b, 05H); TLSBytes.AppendByte(b, 00H)
END AddAlgRSA;

PROCEDURE AddTime(VAR b: TLSBytes.Buffer; s: ARRAY OF CHAR);
BEGIN
  TLSBytes.AppendByte(b, TLSASN1.UTCTime);
  TLSBytes.AppendByte(b, 13);
  TLSBytes.AppendString(b, s)
END AddTime;

PROCEDURE BuildFakeCert(VAR b: TLSBytes.Buffer);
VAR tbs, spki, validity: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(b); TLSBytes.Init(tbs); TLSBytes.Init(spki); TLSBytes.Init(validity);

  (* TBSCertificate content, total 81 bytes = 51H *)
  TLSBytes.AppendByte(tbs, 0A0H); TLSBytes.AppendByte(tbs, 03H); TLSBytes.AppendByte(tbs, 02H); TLSBytes.AppendByte(tbs, 01H); TLSBytes.AppendByte(tbs, 02H);
  TLSBytes.AppendByte(tbs, 02H); TLSBytes.AppendByte(tbs, 01H); TLSBytes.AppendByte(tbs, 01H);
  AddAlgSha256RSA(tbs);
  TLSBytes.AppendByte(tbs, 30H); TLSBytes.AppendByte(tbs, 00H); (* issuer empty Name *)
  TLSBytes.AppendByte(validity, 30H); TLSBytes.AppendByte(validity, 1EH);
  AddTime(validity, "240101000000Z"); AddTime(validity, "250101000000Z");
  TLSBytes.Append(tbs, validity);
  TLSBytes.AppendByte(tbs, 30H); TLSBytes.AppendByte(tbs, 00H); (* subject empty Name *)
  TLSBytes.AppendByte(spki, 30H); TLSBytes.AppendByte(spki, 14H);
  AddAlgRSA(spki);
  TLSBytes.AppendByte(spki, 03H); TLSBytes.AppendByte(spki, 03H); TLSBytes.AppendByte(spki, 00H); TLSBytes.AppendByte(spki, 30H); TLSBytes.AppendByte(spki, 00H);
  TLSBytes.Append(tbs, spki);

  TLSBytes.AppendByte(b, 30H); TLSBytes.AppendByte(b, 67H);
  TLSBytes.AppendByte(b, 30H); TLSBytes.AppendByte(b, 51H); TLSBytes.Append(b, tbs);
  AddAlgSha256RSA(b);
  TLSBytes.AppendByte(b, 03H); TLSBytes.AppendByte(b, 03H); TLSBytes.AppendByte(b, 00H); TLSBytes.AppendByte(b, 0AAH); TLSBytes.AppendByte(b, 0BBH)
END BuildFakeCert;

BEGIN
  BuildFakeCert(der);
  Out.String("cert der = "); Hex(der); Out.Ln;
  OK("parse", TLSX509.ParseCertificate(der, info));
  Out.String("tbs len = "); Out.Int(info.tbs.len, 0); Out.Ln;
  OK("tbs len", info.tbs.len = 83);
  Out.String("issuer len = "); Out.Int(info.issuer.len, 0); Out.Ln;
  OK("issuer", info.issuer.len = 2);
  Out.String("subject len = "); Out.Int(info.subject.len, 0); Out.Ln;
  OK("subject", info.subject.len = 2);
  Out.String("spki len = "); Out.Int(info.spki.len, 0); Out.Ln;
  OK("spki", info.spki.len = 22);
  TLSX509.OIDText(info.sigAlgOID, oid);
  Out.String("sig oid = "); Out.String(oid); Out.Ln;
  OK("sig oid", oid = "1.2.840.113549.1.1.11");
  TLSX509.OIDText(info.pubAlgOID, oid);
  Out.String("pub oid = "); Out.String(oid); Out.Ln;
  OK("pub oid", oid = "1.2.840.113549.1.1.1");
  Out.String("signature = "); Hex(info.signature); Out.Ln;
  OK("signature", (info.signature.len = 2) & (ORD(info.signature.data[0]) = 0AAH) & (ORD(info.signature.data[1]) = 0BBH))
END TLSTestX509.
