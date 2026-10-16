MODULE TLSX509Ext;
(* The certificate extensions a chain check needs (RFC 5280, 4.2): basicConstraints, keyUsage,
   extendedKeyUsage, nameConstraints (kept for TLSNameConstraints), and whether a critical
   extension is not understood (such a certificate must be refused). *)
IMPORT TLSBytes, TLSASN1, TLSX509, TLSX509Names;

CONST
  (** key usage bits *)
  DigitalSignature* = 0; KeyCertSign* = 5;

TYPE
  Ext* = RECORD
    hasBasic*, isCA*: BOOLEAN;
    pathLen*: LONGINT;         (** -1: no limit *)
    hasKeyUsage*: BOOLEAN;
    keyUsage*: SET;            (** bit i: the named bit i of KeyUsage *)
    hasEKU*, serverAuth*: BOOLEAN;  (** serverAuth: listed, or anyExtendedKeyUsage *)
    hasNC*: BOOLEAN;
    nc*: TLSBytes.Buffer;      (** the value of nameConstraints *)
    unknownCritical*: BOOLEAN
  END;

(* the OID bytes 55 1D x (id-ce x) *)
PROCEDURE IsCE(VAR oid: TLSBytes.Buffer; x: LONGINT): BOOLEAN;
BEGIN
  RETURN (oid.len = 3) & (ORD(oid.data[0]) = 55H) & (ORD(oid.data[1]) = 1DH) & (ORD(oid.data[2]) = x)
END IsCE;

PROCEDURE ParseBasic(VAR v: TLSBytes.Buffer; VAR x: Ext): BOOLEAN;
VAR pos, lim, i: LONGINT; t: TLSASN1.TLV;
BEGIN
  pos := 0;
  IF ~TLSASN1.EnterSequence(v, pos, v.len, pos, lim) THEN RETURN FALSE END;
  x.hasBasic := TRUE; x.isCA := FALSE; x.pathLen := -1;
  IF (pos < lim) & TLSASN1.PeekTLV(v, pos, lim, t) & (t.tag = TLSASN1.Boolean) THEN
    IF ~TLSASN1.ExpectTag(v, pos, lim, TLSASN1.Boolean, t) OR (t.len # 1) THEN RETURN FALSE END;
    x.isCA := v.data[t.val] # 0X
  END;
  IF pos < lim THEN
    IF ~TLSASN1.ExpectTag(v, pos, lim, TLSASN1.Integer, t) OR (t.len < 1) OR (t.len > 2) OR (ORD(v.data[t.val]) >= 128) THEN
      RETURN FALSE
    END;
    x.pathLen := 0; i := 0;
    WHILE i < t.len DO x.pathLen := x.pathLen * 256 + ORD(v.data[t.val + i]); INC(i) END
  END;
  RETURN pos = lim
END ParseBasic;

PROCEDURE ParseKeyUsage(VAR v: TLSBytes.Buffer; VAR x: Ext): BOOLEAN;
VAR pos, i, b: LONGINT; t: TLSASN1.TLV;
BEGIN
  pos := 0;
  IF ~TLSASN1.ExpectTag(v, pos, v.len, TLSASN1.BitString, t) OR (t.len < 1) OR (pos # v.len) THEN RETURN FALSE END;
  x.hasKeyUsage := TRUE; x.keyUsage := {};
  i := 1;
  WHILE (i < t.len) & (i <= 2) DO  (* named bits 0..15, the first one the top bit of the first byte *)
    b := ORD(v.data[t.val + i]);
    IF ODD(b DIV 128) THEN INCL(x.keyUsage, (i - 1) * 8) END;
    IF ODD(b DIV 64) THEN INCL(x.keyUsage, (i - 1) * 8 + 1) END;
    IF ODD(b DIV 32) THEN INCL(x.keyUsage, (i - 1) * 8 + 2) END;
    IF ODD(b DIV 16) THEN INCL(x.keyUsage, (i - 1) * 8 + 3) END;
    IF ODD(b DIV 8) THEN INCL(x.keyUsage, (i - 1) * 8 + 4) END;
    IF ODD(b DIV 4) THEN INCL(x.keyUsage, (i - 1) * 8 + 5) END;
    IF ODD(b DIV 2) THEN INCL(x.keyUsage, (i - 1) * 8 + 6) END;
    IF ODD(b) THEN INCL(x.keyUsage, (i - 1) * 8 + 7) END;
    INC(i)
  END;
  RETURN TRUE
END ParseKeyUsage;

PROCEDURE ParseEKU(VAR v: TLSBytes.Buffer; VAR x: Ext): BOOLEAN;
VAR pos, lim: LONGINT; t: TLSASN1.TLV; oid: TLSBytes.Buffer;
BEGIN
  pos := 0;
  IF ~TLSASN1.EnterSequence(v, pos, v.len, pos, lim) THEN RETURN FALSE END;
  x.hasEKU := TRUE; x.serverAuth := FALSE;
  WHILE pos < lim DO
    IF ~TLSASN1.ExpectTag(v, pos, lim, TLSASN1.ObjectIdentifier, t) OR ~TLSASN1.CopyValue(v, t, oid) THEN RETURN FALSE END;
    IF (oid.len = 8) & (ORD(oid.data[0]) = 2BH) & (ORD(oid.data[1]) = 6) & (ORD(oid.data[2]) = 1) &
       (ORD(oid.data[3]) = 5) & (ORD(oid.data[4]) = 5) & (ORD(oid.data[5]) = 7) & (ORD(oid.data[6]) = 3) &
       (ORD(oid.data[7]) = 1) THEN x.serverAuth := TRUE                    (* id-kp-serverAuth *)
    ELSIF (oid.len = 4) & (ORD(oid.data[0]) = 55H) & (ORD(oid.data[1]) = 1DH) & (ORD(oid.data[2]) = 25H) &
       (ORD(oid.data[3]) = 0) THEN x.serverAuth := TRUE                    (* anyExtendedKeyUsage *)
    END
  END;
  RETURN TRUE
END ParseEKU;

(** the extensions of info in x; FALSE if they are malformed or one appears twice *)
PROCEDURE Parse*(VAR info: TLSX509.CertInfo; VAR x: Ext): BOOLEAN;
VAR
  exts, oid, v: TLSBytes.Buffer; pos, ep, elim: LONGINT; e, t: TLSASN1.TLV;
  critical, seenBasic, seenKU, seenEKU, seenSAN: BOOLEAN;
BEGIN
  x.hasBasic := FALSE; x.isCA := FALSE; x.pathLen := -1; x.hasKeyUsage := FALSE; x.keyUsage := {};
  x.hasEKU := FALSE; x.serverAuth := FALSE; x.unknownCritical := FALSE; x.hasNC := FALSE; TLSBytes.Init(x.nc);
  seenBasic := FALSE; seenKU := FALSE; seenEKU := FALSE; seenSAN := FALSE;
  IF ~TLSX509Names.ExtractExtensionsFromTBS(info.tbs, exts) THEN RETURN TRUE END;  (* none (v1, v2) *)
  pos := 0;
  WHILE pos < exts.len DO
    IF ~TLSASN1.ExpectTag(exts, pos, exts.len, TLSASN1.Sequence, e) THEN RETURN FALSE END;
    ep := e.val; elim := e.next;
    IF ~TLSASN1.ExpectTag(exts, ep, elim, TLSASN1.ObjectIdentifier, t) OR ~TLSASN1.CopyValue(exts, t, oid) THEN RETURN FALSE END;
    critical := FALSE;
    IF TLSASN1.PeekTLV(exts, ep, elim, t) & (t.tag = TLSASN1.Boolean) THEN
      IF ~TLSASN1.ExpectTag(exts, ep, elim, TLSASN1.Boolean, t) OR (t.len # 1) THEN RETURN FALSE END;
      critical := exts.data[t.val] # 0X
    END;
    IF ~TLSASN1.ExpectTag(exts, ep, elim, TLSASN1.OctetString, t) OR (ep # elim) OR ~TLSASN1.CopyValue(exts, t, v) THEN
      RETURN FALSE
    END;
    IF IsCE(oid, 13H) THEN
      IF seenBasic OR ~ParseBasic(v, x) THEN RETURN FALSE END; seenBasic := TRUE
    ELSIF IsCE(oid, 0FH) THEN
      IF seenKU OR ~ParseKeyUsage(v, x) THEN RETURN FALSE END; seenKU := TRUE
    ELSIF IsCE(oid, 25H) THEN
      IF seenEKU OR ~ParseEKU(v, x) THEN RETURN FALSE END; seenEKU := TRUE
    ELSIF IsCE(oid, 11H) THEN
      IF seenSAN THEN RETURN FALSE END; seenSAN := TRUE     (* checked with the host name *)
    ELSIF IsCE(oid, 1EH) THEN
      IF x.hasNC THEN RETURN FALSE END; x.hasNC := TRUE; TLSBytes.Copy(v, x.nc)
    ELSIF critical THEN
      x.unknownCritical := TRUE
    END;
    pos := e.next
  END;
  RETURN TRUE
END Parse;

END TLSX509Ext.
