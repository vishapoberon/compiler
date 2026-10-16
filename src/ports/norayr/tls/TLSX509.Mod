MODULE TLSX509;
IMPORT TLSBytes, TLSASN1;

TYPE
  CertInfo* = RECORD
    tbs*: TLSBytes.Buffer;
    issuer*: TLSBytes.Buffer;
    subject*: TLSBytes.Buffer;
    validity*: TLSBytes.Buffer;
    spki*: TLSBytes.Buffer;
    sigAlgOID*: TLSBytes.Buffer;
    sigAlgParams*: TLSBytes.Buffer;  (** the encoded parameters of the signature algorithm, if any *)
    pubAlgOID*: TLSBytes.Buffer;
    signature*: TLSBytes.Buffer;
    signatureUnusedBits*: LONGINT
  END;

PROCEDURE CopyTLV(VAR der: TLSBytes.Buffer; VAR t: TLSASN1.TLV; VAR out: TLSBytes.Buffer): BOOLEAN;
VAR n: LONGINT;
BEGIN
  n := t.next - t.hdr;
  IF (n < 0) OR (t.hdr < 0) OR (t.hdr + n > der.len) THEN RETURN FALSE END;
  TLSBytes.Slice(der, t.hdr, n, out);
  RETURN TRUE
END CopyTLV;

PROCEDURE ParseAlgorithmIdentifier*(VAR der: TLSBytes.Buffer; VAR pos: LONGINT; limit: LONGINT; VAR oid: TLSBytes.Buffer): BOOLEAN;
VAR
  p, lim: LONGINT;
  t: TLSASN1.TLV;
BEGIN
  TLSBytes.Init(oid);
  IF ~TLSASN1.EnterSequence(der, pos, limit, p, lim) THEN RETURN FALSE END;
  IF ~TLSASN1.ExpectTag(der, p, lim, TLSASN1.ObjectIdentifier, t) THEN RETURN FALSE END;
  IF ~TLSASN1.CopyValue(der, t, oid) THEN RETURN FALSE END;
  (* Parameters may be NULL, absent, or algorithm-specific.  We only keep the OID here. *)
  RETURN TRUE
END ParseAlgorithmIdentifier;

(** the OID and the encoded parameters (what follows the OID, may be empty) of the
  AlgorithmIdentifier at pos *)
PROCEDURE ParseAlgorithm*(VAR der: TLSBytes.Buffer; VAR pos: LONGINT; limit: LONGINT; VAR oid, params: TLSBytes.Buffer): BOOLEAN;
VAR p, lim: LONGINT; t: TLSASN1.TLV;
BEGIN
  TLSBytes.Init(oid); TLSBytes.Init(params);
  IF ~TLSASN1.EnterSequence(der, pos, limit, p, lim) THEN RETURN FALSE END;
  IF ~TLSASN1.ExpectTag(der, p, lim, TLSASN1.ObjectIdentifier, t) OR ~TLSASN1.CopyValue(der, t, oid) THEN RETURN FALSE END;
  IF p < lim THEN TLSBytes.Slice(der, p, lim - p, params) END;
  RETURN TRUE
END ParseAlgorithm;

PROCEDURE ParseSubjectPublicKeyInfo(VAR spki: TLSBytes.Buffer; VAR pubAlgOID: TLSBytes.Buffer): BOOLEAN;
VAR p, lim: LONGINT;
BEGIN
  p := 0;
  IF ~TLSASN1.EnterSequence(spki, p, spki.len, p, lim) THEN RETURN FALSE END;
  IF ~ParseAlgorithmIdentifier(spki, p, lim, pubAlgOID) THEN RETURN FALSE END;
  RETURN TRUE
END ParseSubjectPublicKeyInfo;

PROCEDURE ParseCertificate*(VAR der: TLSBytes.Buffer; VAR info: CertInfo): BOOLEAN;
VAR
  pos, certPos, certLimit: LONGINT;
  tbsPos, tbsLimit: LONGINT;
  tmpPos: LONGINT;
  t: TLSASN1.TLV;
  ok: BOOLEAN;
  outerAlg, outerParams: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(info.tbs);
  TLSBytes.Init(info.issuer);
  TLSBytes.Init(info.subject);
  TLSBytes.Init(info.validity);
  TLSBytes.Init(info.spki);
  TLSBytes.Init(info.sigAlgOID); TLSBytes.Init(info.sigAlgParams);
  TLSBytes.Init(info.pubAlgOID);
  TLSBytes.Init(info.signature);
  info.signatureUnusedBits := 0;

  ok := TRUE;
  pos := 0;
  IF ~TLSASN1.EnterSequence(der, pos, der.len, certPos, certLimit) THEN ok := FALSE END;

  IF ok THEN
    tmpPos := certPos;
    IF ~TLSASN1.ExpectTag(der, tmpPos, certLimit, TLSASN1.Sequence, t) THEN
      ok := FALSE
    ELSE
      IF ~CopyTLV(der, t, info.tbs) THEN ok := FALSE END;
      tbsPos := t.val; tbsLimit := t.next;
      certPos := t.next
    END
  END;

  IF ok THEN
    (* Optional version: [0] EXPLICIT INTEGER. *)
    IF TLSASN1.PeekTLV(der, tbsPos, tbsLimit, t) THEN
      IF t.tag = TLSASN1.Ctx0 THEN
        IF ~TLSASN1.ExpectTag(der, tbsPos, tbsLimit, TLSASN1.Ctx0, t) THEN ok := FALSE END
      END
    ELSE
      ok := FALSE
    END
  END;

  IF ok THEN
    (* serialNumber *)
    IF ~TLSASN1.ExpectTag(der, tbsPos, tbsLimit, TLSASN1.Integer, t) THEN ok := FALSE END
  END;

  IF ok THEN
    (* signature inside TBSCertificate *)
    IF ~ParseAlgorithm(der, tbsPos, tbsLimit, info.sigAlgOID, info.sigAlgParams) THEN ok := FALSE END
  END;

  IF ok THEN
    (* issuer Name *)
    IF ~TLSASN1.ExpectTag(der, tbsPos, tbsLimit, TLSASN1.Sequence, t) THEN
      ok := FALSE
    ELSE
      IF ~CopyTLV(der, t, info.issuer) THEN ok := FALSE END
    END
  END;

  IF ok THEN
    (* validity *)
    IF ~TLSASN1.ExpectTag(der, tbsPos, tbsLimit, TLSASN1.Sequence, t) THEN
      ok := FALSE
    ELSE
      IF ~CopyTLV(der, t, info.validity) THEN ok := FALSE END
    END
  END;

  IF ok THEN
    (* subject Name *)
    IF ~TLSASN1.ExpectTag(der, tbsPos, tbsLimit, TLSASN1.Sequence, t) THEN
      ok := FALSE
    ELSE
      IF ~CopyTLV(der, t, info.subject) THEN ok := FALSE END
    END
  END;

  IF ok THEN
    (* subjectPublicKeyInfo *)
    IF ~TLSASN1.ExpectTag(der, tbsPos, tbsLimit, TLSASN1.Sequence, t) THEN
      ok := FALSE
    ELSE
      IF ~CopyTLV(der, t, info.spki) THEN ok := FALSE END;
      IF ok THEN
        IF ~ParseSubjectPublicKeyInfo(info.spki, info.pubAlgOID) THEN ok := FALSE END
      END
    END
  END;

  IF ok THEN
    (* certificate.signatureAlgorithm: it must be the one inside the signed TBSCertificate
       (RFC 5280, 4.1.1.2); the outer one is not signed *)
    IF ~ParseAlgorithm(der, certPos, certLimit, outerAlg, outerParams) THEN ok := FALSE
    ELSIF ~TLSBytes.EqualConstTime(outerAlg, info.sigAlgOID) OR ~TLSBytes.EqualConstTime(outerParams, info.sigAlgParams) THEN ok := FALSE
    END
  END;

  IF ok THEN
    (* certificate.signatureValue BIT STRING. First content byte is unused-bits count. *)
    IF ~TLSASN1.ExpectTag(der, certPos, certLimit, TLSASN1.BitString, t) THEN
      ok := FALSE
    ELSE
      IF t.len < 1 THEN
        ok := FALSE
      ELSE
        info.signatureUnusedBits := ORD(der.data[t.val]);
        TLSBytes.Slice(der, t.val + 1, t.len - 1, info.signature)
      END
    END
  END;
  IF ok & (certPos # certLimit) THEN ok := FALSE END;  (* nothing after the signature *)

  RETURN ok
END ParseCertificate;

PROCEDURE OIDText*(VAR oid: TLSBytes.Buffer; VAR out: ARRAY OF CHAR);
VAR t: TLSASN1.TLV; der: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(der);
  TLSBytes.AppendByte(der, TLSASN1.ObjectIdentifier);
  TLSBytes.PutBE16(der, 0); (* overwritten below for short OIDs *)
  IF oid.len < 128 THEN
    der.data[1] := TLSBytes.Byte(oid.len);
    TLSBytes.Slice(der, 0, 2, der);
    TLSBytes.Append(der, oid);
    t.tag := TLSASN1.ObjectIdentifier; t.hdr := 0; t.val := 2; t.len := oid.len; t.next := 2 + oid.len;
    TLSASN1.OIDToText(der, t, out)
  ELSE
    out[0] := 0X
  END
END OIDText;

END TLSX509.
