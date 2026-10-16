MODULE TLSTestTLS13Certs;
IMPORT Out, TLSBytes, TLS13Certs;

VAR
  msg, der: TLSBytes.Buffer;
  pos, limit: LONGINT;
  ok: BOOLEAN;

PROCEDURE PrintHex(VAR b: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE i < b.len DO Out.Hex(ORD(b.data[i]), -2); INC(i) END
END PrintHex;

PROCEDURE Check(name: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  Out.String(name);
  IF ok THEN Out.String(" OK") ELSE Out.String(" FAIL") END;
  Out.Ln
END Check;

PROCEDURE BuildTestCertMessage(VAR m: TLSBytes.Buffer);
BEGIN
  TLSBytes.Init(m);
  TLSBytes.AppendByte(m, TLS13Certs.Certificate);
  TLSBytes.PutBE24(m, 21);     (* body length *)
  TLSBytes.AppendByte(m, 0);   (* request context length *)
  TLSBytes.PutBE24(m, 17);     (* certificate_list length *)

  TLSBytes.PutBE24(m, 4);      (* cert 1 len *)
  TLSBytes.AppendByte(m, 30H); TLSBytes.AppendByte(m, 82H);
  TLSBytes.AppendByte(m, 05H); TLSBytes.AppendByte(m, 6BH);
  TLSBytes.PutBE16(m, 0);      (* extensions len *)

  TLSBytes.PutBE24(m, 3);      (* cert 2 len *)
  TLSBytes.AppendByte(m, 1); TLSBytes.AppendByte(m, 2); TLSBytes.AppendByte(m, 3);
  TLSBytes.PutBE16(m, 0)       (* extensions len *)
END BuildTestCertMessage;

BEGIN
  BuildTestCertMessage(msg);
  Out.String("cert hs msg = "); PrintHex(msg); Out.Ln;
  Check("  is cert", TLS13Certs.IsCertificateMessage(msg));

  ok := TLS13Certs.FirstCertificate(msg, der);
  Out.String("first cert = "); PrintHex(der); Out.Ln;
  Check("  first", ok & (der.len = 4) & (ORD(der.data[0]) = 30H) & (ORD(der.data[1]) = 82H));

  ok := TLS13Certs.CertificateListStart(msg, pos, limit);
  Check("  list start", ok & (limit - pos = 17));

  ok := TLS13Certs.NextCertificate(msg, pos, limit, der);
  Check("  next1", ok & (der.len = 4));
  ok := TLS13Certs.NextCertificate(msg, pos, limit, der);
  Out.String("second cert = "); PrintHex(der); Out.Ln;
  Check("  next2", ok & (der.len = 3) & (ORD(der.data[0]) = 1) & (ORD(der.data[2]) = 3));
  ok := TLS13Certs.NextCertificate(msg, pos, limit, der);
  Check("  no next", ~ok)
END TLSTestTLS13Certs.
