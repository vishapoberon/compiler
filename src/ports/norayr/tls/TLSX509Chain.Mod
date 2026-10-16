MODULE TLSX509Chain;
(* Certificate path validation for a TLS server (RFC 5280, 6, as browsers do it for the web PKI):
   from the leaf, each issuer is looked up by name among the trust anchors (the CA bundle) first,
   then among the certificates the server sent. At every step the names chain, the issuer is valid
   now, its signature over the child verifies (TLSSig), and an issuer that is not an anchor is a CA
   (basicConstraints cA; keyCertSign if keyUsage is present; pathLenConstraint respected). The leaf
   is valid now, may sign (digitalSignature if keyUsage is present) and may serve TLS (serverAuth
   if extendedKeyUsage is present). A certificate with a critical extension that is not understood
   is refused. The nameConstraints of every issuer, the trust anchor too (as browsers do), must
   permit the names of the leaf (TLSNameConstraints). The walk ends at a trust anchor. The host
   name is checked elsewhere (TLSX509Names). *)
IMPORT TLSBytes, TLSPEM, TLSX509, TLSX509Validity, TLSX509Ext, TLSSig, TLSNameConstraints;

CONST
  MaxDepth* = 8;

TYPE
  Result* = RECORD
    leafParsed*, allTimesOK*, allNamesOK*, allSignaturesOK*, constraintsOK*: BOOLEAN;
    rootFound*, rootTrusted*, trusted*: BOOLEAN;
    depth*: LONGINT;
    failedAt*: LONGINT;
    rootDer*: TLSBytes.Buffer
  END;

  (* the certificates of a walk: on the heap, a CertInfo is 256 KB *)
  Work = POINTER TO WorkDesc;
  WorkDesc = RECORD
    leaf, cur, issuer, cand: TLSX509.CertInfo;
    curDER, issuerDER, candDER: TLSBytes.Buffer
  END;

VAR
  w: Work;

PROCEDURE Reset(VAR r: Result);
BEGIN
  r.leafParsed := FALSE; r.allTimesOK := TRUE; r.allNamesOK := TRUE; r.allSignaturesOK := TRUE;
  r.constraintsOK := TRUE; r.rootFound := FALSE; r.rootTrusted := FALSE;
  r.trusted := FALSE; r.depth := 0; r.failedAt := -1; TLSBytes.Init(r.rootDer)
END Reset;

(* the leaf may be a TLS server certificate *)
PROCEDURE LeafOK(VAR c: TLSX509.CertInfo): BOOLEAN;
VAR x: TLSX509Ext.Ext;
BEGIN
  RETURN TLSX509Ext.Parse(c, x) & ~x.unknownCritical &
    (~x.hasKeyUsage OR (TLSX509Ext.DigitalSignature IN x.keyUsage)) &
    (~x.hasEKU OR x.serverAuth)
END LeafOK;

(* the issuer may issue certificates; below: the CA certificates between it and the leaf (for
   pathLenConstraint); an anchor without basicConstraints (a v1 root) is accepted *)
PROCEDURE IssuerOK(VAR c: TLSX509.CertInfo; below: LONGINT; anchor: BOOLEAN): BOOLEAN;
VAR x: TLSX509Ext.Ext;
BEGIN
  IF ~TLSX509Ext.Parse(c, x) OR x.unknownCritical THEN RETURN FALSE END;
  IF x.hasBasic THEN
    IF ~x.isCA THEN RETURN FALSE END;
    IF (x.pathLen >= 0) & (below > x.pathLen) THEN RETURN FALSE END
  ELSIF ~anchor THEN RETURN FALSE
  END;
  RETURN ~x.hasKeyUsage OR (TLSX509Ext.KeyCertSign IN x.keyUsage)
END IssuerOK;

(* the nameConstraints of the issuer c, if any, permit the names of the leaf *)
PROCEDURE NamesOK(VAR c: TLSX509.CertInfo): BOOLEAN;
VAR x: TLSX509Ext.Ext;
BEGIN
  RETURN TLSX509Ext.Parse(c, x) & (~x.hasNC OR TLSNameConstraints.Permit(x.nc, w.leaf))
END NamesOK;

(* an issuer of w.cur by name among the certificates the server sent, not w.cur itself *)
PROCEDURE FindInChain(VAR certs: ARRAY OF TLSBytes.Buffer; certCount: LONGINT): BOOLEAN;
VAR i: LONGINT;
BEGIN
  i := 1;
  WHILE (i < certCount) & (i < LEN(certs)) DO
    IF ~TLSBytes.EqualConstTime(certs[i], w.curDER) & TLSX509.ParseCertificate(certs[i], w.cand) &
       TLSBytes.EqualConstTime(w.cur.issuer, w.cand.subject) THEN
      TLSBytes.Copy(certs[i], w.issuerDER); w.issuer := w.cand; RETURN TRUE
    END;
    INC(i)
  END;
  RETURN FALSE
END FindInChain;

(* an anchor that has the name of the issuer of w.cur and whose signature over it verifies
   (several roots may share a name: old and new keys) *)
PROCEDURE FindInPEM(VAR bundle: ARRAY OF CHAR): BOOLEAN;
VAR from: LONGINT;
BEGIN
  from := 0;
  WHILE TLSPEM.NextCertificateDER(bundle, from, w.candDER) DO
    IF TLSX509.ParseCertificate(w.candDER, w.cand) & TLSBytes.EqualConstTime(w.cur.issuer, w.cand.subject) &
       TLSSig.CertSignedBy(w.cur, w.cand) THEN
      TLSBytes.Copy(w.candDER, w.issuerDER); w.issuer := w.cand; RETURN TRUE
    END
  END;
  RETURN FALSE
END FindInPEM;

PROCEDURE FindInList(VAR roots: ARRAY OF TLSBytes.Buffer; rootCount: LONGINT): BOOLEAN;
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < rootCount) & (i < LEN(roots)) DO
    IF TLSX509.ParseCertificate(roots[i], w.cand) & TLSBytes.EqualConstTime(w.cur.issuer, w.cand.subject) &
       TLSSig.CertSignedBy(w.cur, w.cand) THEN
      TLSBytes.Copy(roots[i], w.issuerDER); w.issuer := w.cand; RETURN TRUE
    END;
    INC(i)
  END;
  RETURN FALSE
END FindInList;

(* the walk from certs[0] to an anchor of bundle (pem) or of roots *)
PROCEDURE Walk(VAR certs: ARRAY OF TLSBytes.Buffer; certCount: LONGINT; pem: BOOLEAN; VAR bundle: ARRAY OF CHAR;
  VAR roots: ARRAY OF TLSBytes.Buffer; rootCount: LONGINT; VAR now: TLSX509Validity.Time; VAR r: Result): BOOLEAN;
VAR depth: LONGINT; anchor, found: BOOLEAN;
BEGIN
  Reset(r);
  IF (certCount <= 0) OR (LEN(certs) <= 0) THEN RETURN FALSE END;
  IF w = NIL THEN NEW(w) END;
  TLSBytes.Copy(certs[0], w.curDER);
  r.leafParsed := TLSX509.ParseCertificate(w.curDER, w.cur);
  IF ~r.leafParsed THEN r.failedAt := 0; RETURN FALSE END;
  IF ~TLSX509Validity.ValidAt(w.cur, now) THEN r.allTimesOK := FALSE; r.failedAt := 0; RETURN FALSE END;
  IF ~LeafOK(w.cur) THEN r.constraintsOK := FALSE; r.failedAt := 0; RETURN FALSE END;
  w.leaf := w.cur;
  depth := 0;
  LOOP
    INC(depth); r.depth := depth;
    IF depth > MaxDepth THEN r.failedAt := depth; RETURN FALSE END;
    IF pem THEN anchor := FindInPEM(bundle) ELSE anchor := FindInList(roots, rootCount) END;
    found := anchor OR FindInChain(certs, certCount);
    IF ~found THEN r.failedAt := depth; RETURN FALSE END;
    IF ~TLSX509Validity.ValidAt(w.issuer, now) THEN r.allTimesOK := FALSE; r.failedAt := depth; RETURN FALSE END;
    IF ~anchor & ~TLSSig.CertSignedBy(w.cur, w.issuer) THEN r.allSignaturesOK := FALSE; r.failedAt := depth; RETURN FALSE END;
    IF ~IssuerOK(w.issuer, depth - 1, anchor) OR ~NamesOK(w.issuer) THEN r.constraintsOK := FALSE; r.failedAt := depth; RETURN FALSE END;
    IF anchor THEN
      r.rootFound := TRUE; r.rootTrusted := TRUE; TLSBytes.Copy(w.issuerDER, r.rootDer);
      r.trusted := TRUE; RETURN TRUE
    END;
    TLSBytes.Copy(w.issuerDER, w.curDER); w.cur := w.issuer
  END
END Walk;

(** the chain certs[0..certCount) (the leaf first) up to one of the DER certificates roots *)
PROCEDURE CheckChainWithTrustAnchors*(VAR certs: ARRAY OF TLSBytes.Buffer; certCount: LONGINT;
  VAR roots: ARRAY OF TLSBytes.Buffer; rootCount: LONGINT; VAR now: TLSX509Validity.Time; VAR r: Result): BOOLEAN;
VAR none: ARRAY 1 OF CHAR;
BEGIN
  none[0] := 0X;
  RETURN Walk(certs, certCount, FALSE, none, roots, rootCount, now, r)
END CheckChainWithTrustAnchors;

(** the chain up to one of the certificates of the PEM bundle *)
PROCEDURE CheckChainWithPEMBundle*(VAR certs: ARRAY OF TLSBytes.Buffer; certCount: LONGINT;
  VAR bundle: ARRAY OF CHAR; VAR now: TLSX509Validity.Time; VAR r: Result): BOOLEAN;
VAR noRoots: ARRAY 1 OF TLSBytes.Buffer;
BEGIN
  RETURN Walk(certs, certCount, TRUE, bundle, noRoots, 0, now, r)
END CheckChainWithPEMBundle;

BEGIN
  w := NIL
END TLSX509Chain.
