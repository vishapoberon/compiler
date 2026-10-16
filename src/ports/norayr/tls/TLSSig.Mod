MODULE TLSSig;
(* Signature checks of certificates and of the TLS 1.3 CertificateVerify, with the keys of
   SubjectPublicKeyInfo: RSA (TLSRSA: PKCS#1 v1.5, and RSASSA-PSS with SHA-2) and ECDSA on
   P-256, P-384 and P-521 (TLSECDSA). The parameters of the algorithm must be as RFC 5280 and
   4055 say (NULL or none for PKCS#1, none for ECDSA). Algorithms not listed here are refused. *)
IMPORT TLSBytes, TLSASN1, TLSX509, TLSRSA, TLSECDSA;

CONST
  (** TLS 1.3 SignatureScheme values accepted for CertificateVerify (RFC 8446, 4.2.3) *)
  EcdsaP256Sha256* = 0403H; EcdsaP384Sha384* = 0503H; EcdsaP521Sha512* = 0603H;
  RsaPssRsaeSha256* = 0804H; RsaPssRsaeSha384* = 0805H; RsaPssRsaeSha512* = 0806H;

  RSA = 1; ECDSA = 2; PSS = 3;

(* the OID bytes b equal oid *)
PROCEDURE Is(VAR oid: TLSBytes.Buffer; b0, b1, b2, b3, b4, b5, b6, b7, b8, len: LONGINT): BOOLEAN;
VAR b: ARRAY 9 OF LONGINT; i: LONGINT;
BEGIN
  IF oid.len # len THEN RETURN FALSE END;
  b[0] := b0; b[1] := b1; b[2] := b2; b[3] := b3; b[4] := b4; b[5] := b5; b[6] := b6; b[7] := b7; b[8] := b8;
  i := 0; WHILE i < len DO IF ORD(oid.data[i]) # b[i] THEN RETURN FALSE END; INC(i) END;
  RETURN TRUE
END Is;

(* the hash algorithm (TLSRSA.SHA256 ...) of the AlgorithmIdentifier contents at p..lim of b
   (OID 2.16.840.1.101.3.4.2.1, 2, 3, then NULL or nothing) *)
PROCEDURE HashAlg(VAR b: TLSBytes.Buffer; p, lim: LONGINT; VAR hash: LONGINT): BOOLEAN;
VAR t: TLSASN1.TLV; oid: TLSBytes.Buffer;
BEGIN
  IF ~TLSASN1.ExpectTag(b, p, lim, TLSASN1.ObjectIdentifier, t) OR ~TLSASN1.CopyValue(b, t, oid) THEN RETURN FALSE END;
  IF (p < lim) & (~TLSASN1.ExpectTag(b, p, lim, 5, t) OR (t.len # 0) OR (p # lim)) THEN RETURN FALSE END;
  IF Is(oid, 60H, 86H, 48H, 1, 65H, 3, 4, 2, 1, 9) THEN hash := TLSRSA.SHA256
  ELSIF Is(oid, 60H, 86H, 48H, 1, 65H, 3, 4, 2, 2, 9) THEN hash := TLSRSA.SHA384
  ELSIF Is(oid, 60H, 86H, 48H, 1, 65H, 3, 4, 2, 3, 9) THEN hash := TLSRSA.SHA512
  ELSE RETURN FALSE  (* SHA-1 and others *)
  END;
  RETURN TRUE
END HashAlg;

(* RSASSA-PSS-params (RFC 4055 3.1): hash [0] of SHA-2 (not the SHA-1 default), MGF1 [1] with the
   same hash, saltLength [2] (default 20), trailerField [3] 1 *)
PROCEDURE PSSParams(VAR params: TLSBytes.Buffer; VAR hash, salt: LONGINT): BOOLEAN;
VAR pos, lim, p, l, ap, al, mgfHash, i: LONGINT; t, a: TLSASN1.TLV; oid: TLSBytes.Buffer; sawHash, sawMGF: BOOLEAN;
BEGIN
  pos := 0; salt := 20; sawHash := FALSE; sawMGF := FALSE;
  IF ~TLSASN1.EnterSequence(params, pos, params.len, pos, lim) OR (lim # params.len) THEN RETURN FALSE END;  (* nothing after it *)
  WHILE pos < lim DO
    IF ~TLSASN1.ReadTLV(params, pos, lim, t) THEN RETURN FALSE END;
    p := t.val; l := t.next;
    IF t.tag = 0A0H THEN       (* hashAlgorithm *)
      IF sawHash OR ~TLSASN1.EnterSequence(params, p, l, ap, al) OR (p # l) OR ~HashAlg(params, ap, al, hash) THEN RETURN FALSE END;
      sawHash := TRUE
    ELSIF t.tag = 0A1H THEN    (* maskGenAlgorithm: id-mgf1 with a hash *)
      IF sawMGF OR ~TLSASN1.EnterSequence(params, p, l, ap, al) OR (p # l) THEN RETURN FALSE END;
      IF ~TLSASN1.ExpectTag(params, ap, al, TLSASN1.ObjectIdentifier, a) OR ~TLSASN1.CopyValue(params, a, oid) OR
         ~Is(oid, 2AH, 86H, 48H, 86H, 0F7H, 0DH, 1, 1, 8, 9) THEN RETURN FALSE END;
      IF ~TLSASN1.EnterSequence(params, ap, al, p, l) OR (ap # al) OR ~HashAlg(params, p, l, mgfHash) THEN RETURN FALSE END;
      sawMGF := TRUE
    ELSIF t.tag = 0A2H THEN    (* saltLength *)
      IF ~TLSASN1.ExpectTag(params, p, l, TLSASN1.Integer, a) OR (p # l) OR (a.len < 1) OR (a.len > 2) OR
         (ORD(params.data[a.val]) >= 128) THEN RETURN FALSE END;
      salt := 0; i := 0; WHILE i < a.len DO salt := salt * 256 + ORD(params.data[a.val + i]); INC(i) END
    ELSIF t.tag = 0A3H THEN    (* trailerField: 1 *)
      IF ~TLSASN1.ExpectTag(params, p, l, TLSASN1.Integer, a) OR (p # l) OR (a.len # 1) OR (params.data[a.val] # 1X) THEN RETURN FALSE END
    ELSE RETURN FALSE
    END
  END;
  RETURN sawHash & sawMGF & (mgfHash = hash)
END PSSParams;

(* the kind of key, the hash (and for PSS the salt length) of a certificate signature algorithm
   with its parameters *)
PROCEDURE CertAlgorithm(VAR oid, params: TLSBytes.Buffer; VAR kind, hash, salt: LONGINT): BOOLEAN;
VAR nullOrNone: BOOLEAN;
BEGIN
  nullOrNone := (params.len = 0) OR (params.len = 2) & (params.data[0] = 5X) & (params.data[1] = 0X);
  kind := RSA;  (* 1.2.840.113549.1.1.11, 12, 13 *)
  IF Is(oid, 2AH, 86H, 48H, 86H, 0F7H, 0DH, 1, 1, 0BH, 9) THEN hash := TLSRSA.SHA256; RETURN nullOrNone END;
  IF Is(oid, 2AH, 86H, 48H, 86H, 0F7H, 0DH, 1, 1, 0CH, 9) THEN hash := TLSRSA.SHA384; RETURN nullOrNone END;
  IF Is(oid, 2AH, 86H, 48H, 86H, 0F7H, 0DH, 1, 1, 0DH, 9) THEN hash := TLSRSA.SHA512; RETURN nullOrNone END;
  kind := PSS;  (* 1.2.840.113549.1.1.10 *)
  IF Is(oid, 2AH, 86H, 48H, 86H, 0F7H, 0DH, 1, 1, 0AH, 9) THEN RETURN PSSParams(params, hash, salt) END;
  kind := ECDSA;  (* 1.2.840.10045.4.3.2, 3, 4 *)
  IF Is(oid, 2AH, 86H, 48H, 0CEH, 3DH, 4, 3, 2, 0, 8) THEN hash := TLSRSA.SHA256; RETURN params.len = 0 END;
  IF Is(oid, 2AH, 86H, 48H, 0CEH, 3DH, 4, 3, 3, 0, 8) THEN hash := TLSRSA.SHA384; RETURN params.len = 0 END;
  IF Is(oid, 2AH, 86H, 48H, 0CEH, 3DH, 4, 3, 4, 0, 8) THEN hash := TLSRSA.SHA512; RETURN params.len = 0 END;
  RETURN FALSE
END CertAlgorithm;

(** the curve (TLSECDSA.P256, P384, P521) and the point (04 x y) of an EC SubjectPublicKeyInfo *)
PROCEDURE ECPublicKey*(VAR spki: TLSBytes.Buffer; VAR curve: LONGINT; VAR point: TLSBytes.Buffer): BOOLEAN;
VAR pos, lim, apos, alim: LONGINT; t: TLSASN1.TLV; oid, param: TLSBytes.Buffer;
BEGIN
  pos := 0;
  IF ~TLSASN1.EnterSequence(spki, pos, spki.len, pos, lim) THEN RETURN FALSE END;
  IF ~TLSASN1.EnterSequence(spki, pos, lim, apos, alim) THEN RETURN FALSE END;
  IF ~TLSASN1.ExpectTag(spki, apos, alim, TLSASN1.ObjectIdentifier, t) OR ~TLSASN1.CopyValue(spki, t, oid) THEN RETURN FALSE END;
  IF ~Is(oid, 2AH, 86H, 48H, 0CEH, 3DH, 2, 1, 0, 0, 7) THEN RETURN FALSE END;          (* id-ecPublicKey *)
  IF ~TLSASN1.ExpectTag(spki, apos, alim, TLSASN1.ObjectIdentifier, t) OR ~TLSASN1.CopyValue(spki, t, param) OR (apos # alim) THEN
    RETURN FALSE
  END;
  IF Is(param, 2AH, 86H, 48H, 0CEH, 3DH, 3, 1, 7, 0, 8) THEN curve := TLSECDSA.P256    (* prime256v1 *)
  ELSIF Is(param, 2BH, 81H, 4, 0, 22H, 0, 0, 0, 0, 5) THEN curve := TLSECDSA.P384      (* secp384r1 *)
  ELSIF Is(param, 2BH, 81H, 4, 0, 23H, 0, 0, 0, 0, 5) THEN curve := TLSECDSA.P521      (* secp521r1 *)
  ELSE RETURN FALSE
  END;
  pos := alim;
  IF ~TLSASN1.ExpectTag(spki, pos, lim, TLSASN1.BitString, t) OR (t.len < 2) OR (spki.data[t.val] # 0X) OR (pos # lim) THEN
    RETURN FALSE
  END;
  TLSBytes.Slice(spki, t.val + 1, t.len - 1, point);
  RETURN TRUE
END ECPublicKey;

(* the signature sig (DER for ECDSA) of hash by the key in spki *)
PROCEDURE VerifyHash(kind, hash: LONGINT; pss: BOOLEAN; VAR spki, digest, sig: TLSBytes.Buffer): BOOLEAN;
VAR n, e, point, r, s: TLSBytes.Buffer; curve: LONGINT;
BEGIN
  IF kind = RSA THEN
    IF ~TLSRSA.PublicKey(spki, n, e) THEN RETURN FALSE END;
    IF pss THEN RETURN TLSRSA.VerifyPSS(n, e, hash, digest, sig)
    ELSE RETURN TLSRSA.VerifyPKCS1(n, e, hash, digest, sig)
    END
  ELSE
    RETURN ECPublicKey(spki, curve, point) & TLSECDSA.ParseSignature(sig, r, s) & TLSECDSA.Verify(curve, point, digest, r, s)
  END
END VerifyHash;

(** the certificate child is signed by the key of issuer *)
PROCEDURE CertSignedBy*(VAR child, issuer: TLSX509.CertInfo): BOOLEAN;
VAR kind, hash, salt: LONGINT; digest, n, e, keyParams: TLSBytes.Buffer; pssKey: BOOLEAN;
BEGIN
  IF (child.signatureUnusedBits # 0) OR ~CertAlgorithm(child.sigAlgOID, child.sigAlgParams, kind, hash, salt) THEN RETURN FALSE END;
  IF ~TLSRSA.Hash(hash, child.tbs, digest) THEN RETURN FALSE END;
  IF kind = PSS THEN  (* an RSASSA-PSS key restricting its parameters must have these *)
    IF ~TLSRSA.PublicKeyAlg(issuer.spki, n, e, pssKey, keyParams) THEN RETURN FALSE END;
    IF pssKey & (keyParams.len > 0) & ~TLSBytes.EqualConstTime(keyParams, child.sigAlgParams) THEN RETURN FALSE END;
    RETURN TLSRSA.VerifyPSSSalt(n, e, hash, digest, child.signature, salt)
  END;
  RETURN VerifyHash(kind, hash, FALSE, issuer.spki, digest, child.signature)
END CertSignedBy;

(** the CertificateVerify signature sig with scheme over content, by the key in spki (the leaf):
  ECDSA schemes need a key on their curve, RSA-PSS an RSA key; nothing else is accepted *)
PROCEDURE VerifyScheme*(scheme: LONGINT; VAR spki, content, sig: TLSBytes.Buffer): BOOLEAN;
VAR digest, point: TLSBytes.Buffer; curve, hash: LONGINT;
BEGIN
  IF (scheme = EcdsaP256Sha256) OR (scheme = EcdsaP384Sha384) OR (scheme = EcdsaP521Sha512) THEN
    IF ~ECPublicKey(spki, curve, point) THEN RETURN FALSE END;
    IF (scheme = EcdsaP256Sha256) & (curve # TLSECDSA.P256) OR (scheme = EcdsaP384Sha384) & (curve # TLSECDSA.P384) OR
       (scheme = EcdsaP521Sha512) & (curve # TLSECDSA.P521) THEN
      RETURN FALSE
    END;
    IF scheme = EcdsaP256Sha256 THEN hash := TLSRSA.SHA256
    ELSIF scheme = EcdsaP384Sha384 THEN hash := TLSRSA.SHA384
    ELSE hash := TLSRSA.SHA512
    END;
    RETURN TLSRSA.Hash(hash, content, digest) & VerifyHash(ECDSA, hash, FALSE, spki, digest, sig)
  ELSIF (scheme = RsaPssRsaeSha256) OR (scheme = RsaPssRsaeSha384) OR (scheme = RsaPssRsaeSha512) THEN
    IF scheme = RsaPssRsaeSha256 THEN hash := TLSRSA.SHA256
    ELSIF scheme = RsaPssRsaeSha384 THEN hash := TLSRSA.SHA384
    ELSE hash := TLSRSA.SHA512
    END;
    RETURN TLSRSA.Hash(hash, content, digest) & VerifyHash(RSA, hash, TRUE, spki, digest, sig)
  END;
  RETURN FALSE
END VerifyScheme;

END TLSSig.
