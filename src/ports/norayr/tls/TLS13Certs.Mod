MODULE TLS13Certs;
IMPORT TLSBytes;

CONST
  Certificate* = 11;

PROCEDURE IsCertificateMessage*(VAR msg: TLSBytes.Buffer): BOOLEAN;
VAR bodyLen: LONGINT;
BEGIN
  IF msg.len < 5 THEN RETURN FALSE END;
  IF ORD(msg.data[0]) # Certificate THEN RETURN FALSE END;
  bodyLen := TLSBytes.GetBE24(msg, 1);
  IF bodyLen + 4 > msg.len THEN RETURN FALSE END;
  RETURN TRUE
END IsCertificateMessage;

(* For TLS 1.3 Certificate handshake message:
     msg_type(11), len(3), certificate_request_context_len(1),
     certificate_list_len(3), repeated certificate_entry. *)
PROCEDURE CertificateListStart*(VAR msg: TLSBytes.Buffer; VAR pos, limit: LONGINT): BOOLEAN;
VAR bodyLen, ctxLen, listLen, p: LONGINT;
BEGIN
  pos := 0; limit := 0;
  IF ~IsCertificateMessage(msg) THEN RETURN FALSE END;
  bodyLen := TLSBytes.GetBE24(msg, 1);
  ctxLen := ORD(msg.data[4]);
  p := 5 + ctxLen;
  IF p + 3 > 4 + bodyLen THEN RETURN FALSE END;
  listLen := TLSBytes.GetBE24(msg, p);
  p := p + 3;
  IF p + listLen > 4 + bodyLen THEN RETURN FALSE END;
  pos := p;
  limit := p + listLen;
  RETURN TRUE
END CertificateListStart;

PROCEDURE NextCertificate*(VAR msg: TLSBytes.Buffer; VAR pos: LONGINT; limit: LONGINT; VAR der: TLSBytes.Buffer): BOOLEAN;
VAR certLen, extLen: LONGINT;
BEGIN
  TLSBytes.Init(der);
  IF pos >= limit THEN RETURN FALSE END;
  IF pos + 3 > limit THEN RETURN FALSE END;
  certLen := TLSBytes.GetBE24(msg, pos);
  pos := pos + 3;
  IF pos + certLen + 2 > limit THEN RETURN FALSE END;
  TLSBytes.Slice(msg, pos, certLen, der);
  pos := pos + certLen;
  extLen := TLSBytes.GetBE16(msg, pos);
  pos := pos + 2;
  IF pos + extLen > limit THEN RETURN FALSE END;
  pos := pos + extLen;
  RETURN TRUE
END NextCertificate;

PROCEDURE FirstCertificate*(VAR msg, der: TLSBytes.Buffer): BOOLEAN;
VAR pos, limit: LONGINT;
BEGIN
  IF ~CertificateListStart(msg, pos, limit) THEN RETURN FALSE END;
  RETURN NextCertificate(msg, pos, limit, der)
END FirstCertificate;

END TLS13Certs.
