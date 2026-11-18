MODULE TLS13Auth;
(** TLS 1.3 authentication with manually pinned Ed25519 keys and self-signed certificates. *)
IMPORT TLSBytes, TLSASN1, TLSX509, TLSX509Ext, TLSX509Validity, TLSSig, TLSIdentity, TLS13Keys;

TYPE Cert = POINTER TO TLSX509.CertInfo; Extensions = POINTER TO TLSX509Ext.Ext;

(** Checks a self-signed leaf against an exact raw 32-byte pin, its validity and TLS key usages.
    server is the role of the peer presenting the certificate. spki is empty on failure. *)
PROCEDURE PinnedEd25519*(VAR certificate, pin: TLSBytes.Buffer; VAR now: TLSX509Validity.Time;
    server: BOOLEAN; VAR spki: TLSBytes.Buffer): BOOLEAN;
VAR info: Cert; ext: Extensions; publicKey: TLSBytes.Buffer; pos: LONGINT; outer: TLSASN1.TLV;
BEGIN
  TLSBytes.Init(spki);
  IF pin.len # 32 THEN RETURN FALSE END;
  pos := 0;
  IF ~TLSASN1.ExpectTag(certificate, pos, certificate.len, TLSASN1.Sequence, outer) OR
     (pos # certificate.len) THEN RETURN FALSE END;
  NEW(info); NEW(ext);
  IF ~TLSX509.ParseCertificate(certificate, info^) OR ~TLSSig.Ed25519PublicKey(info.spki, publicKey) OR
     ~TLSBytes.EqualConstTime(publicKey, pin) OR ~TLSBytes.EqualConstTime(info.issuer, info.subject) OR
     ~TLSSig.CertSignedBy(info^, info^) OR ~TLSX509Validity.ValidAt(info^, now) OR
     ~TLSX509Ext.Parse(info^, ext^) OR ext.unknownCritical THEN RETURN FALSE END;
  IF ext.hasKeyUsage & ~(TLSX509Ext.DigitalSignature IN ext.keyUsage) THEN RETURN FALSE END;
  IF ext.hasEKU & ((server & ~ext.serverAuth) OR (~server & ~ext.clientAuth)) THEN RETURN FALSE END;
  TLSBytes.Copy(info.spki, spki); RETURN TRUE
END PinnedEd25519;

(** Extracts the sole certificate of an initial-handshake Certificate message.
    This profile has no certificate-entry extensions or intermediate certificates. *)
PROCEDURE Certificate*(VAR message, certificate: TLSBytes.Buffer): BOOLEAN;
VAR size: LONGINT;
BEGIN
  TLSBytes.Init(certificate);
  IF (message.len < 13) OR (message.data[0] # 0BX) OR
     (TLSBytes.GetBE24(message, 1) # message.len-4) OR (message.data[4] # 0X) OR
     (TLSBytes.GetBE24(message, 5) # message.len-8) THEN RETURN FALSE END;
  size := TLSBytes.GetBE24(message, 8);
  IF (size < 1) OR (size # message.len-13) OR (TLSBytes.GetBE16(message, 11+size) # 0) THEN RETURN FALSE END;
  TLSBytes.Slice(message, 11, size, certificate); RETURN TRUE
END Certificate;

PROCEDURE Content(VAR transcript: TLSBytes.Buffer; server: BOOLEAN; VAR content: TLSBytes.Buffer);
VAR hash: TLSBytes.Buffer; i: LONGINT;
BEGIN
  TLS13Keys.HashMessages(transcript, hash); TLSBytes.Init(content);
  FOR i := 0 TO 63 DO TLSBytes.AppendByte(content, 20H) END;
  IF server THEN TLSBytes.AppendString(content, "TLS 1.3, server CertificateVerify")
  ELSE TLSBytes.AppendString(content, "TLS 1.3, client CertificateVerify")
  END;
  TLSBytes.AppendByte(content, 0); TLSBytes.Append(content, hash)
END Content;

(** Verifies CertificateVerify with the peer role and the transcript preceding that message. *)
PROCEDURE Verify*(VAR message, transcript, spki: TLSBytes.Buffer; server: BOOLEAN): BOOLEAN;
VAR signature, content: TLSBytes.Buffer;
BEGIN
  IF (message.len # 72) OR (message.data[0] # 0FX) OR (TLSBytes.GetBE24(message, 1) # 68) OR
     (TLSBytes.GetBE16(message, 4) # TLSSig.Ed25519) OR (TLSBytes.GetBE16(message, 6) # 64) THEN RETURN FALSE END;
  TLSBytes.Slice(message, 8, 64, signature); Content(transcript, server, content);
  RETURN TLSSig.VerifyScheme(TLSSig.Ed25519, spki, content, signature)
END Verify;

(** A CertificateRequest for initial-handshake Ed25519 client authentication. *)
PROCEDURE Request*(VAR message: TLSBytes.Buffer);
BEGIN
  TLSBytes.Init(message); TLSBytes.AppendByte(message, 13); TLSBytes.PutBE24(message, 11);
  TLSBytes.AppendByte(message, 0); TLSBytes.PutBE16(message, 8);
  TLSBytes.PutBE16(message, 13); TLSBytes.PutBE16(message, 4); TLSBytes.PutBE16(message, 2);
  TLSBytes.PutBE16(message, TLSSig.Ed25519)
END Request;

(** Builds an initial-handshake Certificate containing the identity's self-signed leaf. *)
PROCEDURE Present*(id: TLSIdentity.Identity; VAR message: TLSBytes.Buffer): BOOLEAN;
BEGIN
  TLSBytes.Init(message);
  IF (id = NIL) OR (id.kind # TLSIdentity.Ed25519) OR (id.n # 1) OR
     (id.certs[0].len = 0) OR (id.certs[0].len > TLSBytes.MaxLen-13) THEN RETURN FALSE END;
  TLSBytes.AppendByte(message, 11); TLSBytes.PutBE24(message, 9+id.certs[0].len);
  TLSBytes.AppendByte(message, 0); TLSBytes.PutBE24(message, 5+id.certs[0].len);
  TLSBytes.PutBE24(message, id.certs[0].len); TLSBytes.Append(message, id.certs[0]); TLSBytes.PutBE16(message, 0);
  RETURN TRUE
END Present;

(** Builds CertificateVerify without changing the transcript. *)
PROCEDURE Sign*(id: TLSIdentity.Identity; VAR transcript: TLSBytes.Buffer; server: BOOLEAN;
    VAR message: TLSBytes.Buffer): BOOLEAN;
VAR content, signature: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(message);
  IF (id = NIL) OR (id.kind # TLSIdentity.Ed25519) THEN RETURN FALSE END;
  Content(transcript, server, content);
  IF ~TLSIdentity.Sign(id, content, signature) OR (signature.len # 64) THEN RETURN FALSE END;
  TLSBytes.AppendByte(message, 15); TLSBytes.PutBE24(message, 68);
  TLSBytes.PutBE16(message, TLSSig.Ed25519); TLSBytes.PutBE16(message, 64); TLSBytes.Append(message, signature);
  RETURN TRUE
END Sign;

END TLS13Auth.
