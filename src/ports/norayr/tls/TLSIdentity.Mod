MODULE TLSIdentity;
(** A certificate chain and its private key: what a server presents, and what a client presents
  when a server asks for a certificate (a Gemini identity). The key is ECDSA P-256 or RSA (2048
  bits or more); Load reads them from PEM files (CERTIFICATE; EC PRIVATE KEY, RSA PRIVATE KEY or
  PRIVATE KEY) and checks that the key belongs to the first certificate. Sign makes the signature
  of a CertificateVerify: ecdsa_secp256r1_sha256 (RFC 6979 nonces) or rsa_pss_rsae_sha256. *)
IMPORT TLSBytes, TLSASN1, TLSPEM, TLSCABundle, TLSX509, TLSSig, TLSECDSA, TLSRSA, TLSSHA256, TLS13Random;

CONST
  MaxChain* = 8;
  EC* = 1; RSA* = 2;  (** kinds of keys *)
  EcdsaP256Sha256* = 0403H; RsaPssRsaeSha256* = 0804H;  (** the signature schemes of Sign *)

TYPE
  Identity* = POINTER TO IdentityDesc;
  IdentityDesc* = RECORD
    n*: LONGINT;                                 (** certificates *)
    certs*: ARRAY MaxChain OF TLSBytes.Buffer;   (** DER, the leaf first *)
    kind*: LONGINT;                              (** EC or RSA *)
    ec: TLSBytes.Buffer;                         (* the private scalar, 32 bytes *)
    rsa: TLSRSA.PrivateKey
  END;

  Bundle = POINTER TO TLSCABundle.Bundle;
  Cert = POINTER TO TLSX509.CertInfo;

VAR
  lastError*: ARRAY 128 OF CHAR;  (** why the last Load failed *)

PROCEDURE IsOID(VAR der: TLSBytes.Buffer; VAR t: TLSASN1.TLV; b0, b1, b2, b3, b4, b5, b6, b7, b8, len: LONGINT): BOOLEAN;
VAR b: ARRAY 9 OF LONGINT; i: LONGINT;
BEGIN
  IF (t.tag # TLSASN1.ObjectIdentifier) OR (t.len # len) THEN RETURN FALSE END;
  b[0] := b0; b[1] := b1; b[2] := b2; b[3] := b3; b[4] := b4; b[5] := b5; b[6] := b6; b[7] := b7; b[8] := b8;
  i := 0; WHILE (i < len) & (ORD(der.data[t.val + i]) = b[i]) DO INC(i) END;
  RETURN i = len
END IsOID;

PROCEDURE IsP256(VAR der: TLSBytes.Buffer; VAR t: TLSASN1.TLV): BOOLEAN;
BEGIN RETURN IsOID(der, t, 2AH, 86H, 48H, 0CEH, 3DH, 3, 1, 7, 0, 8)  (* prime256v1 *)
END IsP256;

(* key := the private scalar of the ECPrivateKey (SEC 1) in der *)
PROCEDURE ParseEC(VAR der, key: TLSBytes.Buffer): BOOLEAN;
VAR pos, lim, apos, alim, p, n: LONGINT; t: TLSASN1.TLV;
BEGIN
  TLSBytes.Init(key); pos := 0;
  IF ~TLSASN1.EnterSequence(der, pos, der.len, pos, lim) THEN RETURN FALSE END;
  IF ~TLSASN1.ExpectTag(der, pos, lim, TLSASN1.Integer, t) OR (t.len # 1) OR (der.data[t.val] # 1X) THEN RETURN FALSE END;
  IF ~TLSASN1.ExpectTag(der, pos, lim, TLSASN1.OctetString, t) OR (t.len > 32) OR (t.len < 1) THEN RETURN FALSE END;
  n := 32 - t.len; WHILE n > 0 DO TLSBytes.AppendByte(key, 0); DEC(n) END;
  p := 0; WHILE p < t.len DO TLSBytes.AppendByte(key, ORD(der.data[t.val + p])); INC(p) END;
  IF TLSASN1.EnterExplicit(der, pos, lim, TLSASN1.Ctx0, apos, alim) THEN
    IF ~TLSASN1.ReadTLV(der, apos, alim, t) OR ~IsP256(der, t) THEN
      TLSBytes.Init(key); COPY("the key is not on the curve P-256", lastError); RETURN FALSE
    END
  END;
  RETURN TRUE
END ParseEC;

(** the private key in der: an ECPrivateKey (SEC 1, P-256), an RSAPrivateKey (PKCS #1), or
  either inside a PrivateKeyInfo (PKCS #8); kind := EC (ec: the scalar) or RSA *)
PROCEDURE ParseKey*(VAR der: TLSBytes.Buffer; VAR id: IdentityDesc): BOOLEAN;
VAR pos, lim, apos, alim: LONGINT; t, v: TLSASN1.TLV; inner: TLSBytes.Buffer;
BEGIN
  id.kind := 0; pos := 0;
  IF ~TLSASN1.EnterSequence(der, pos, der.len, pos, lim) THEN RETURN FALSE END;
  IF ~TLSASN1.ExpectTag(der, pos, lim, TLSASN1.Integer, v) OR (v.len # 1) THEN RETURN FALSE END;
  IF der.data[v.val] = 1X THEN  (* ECPrivateKey: 1, the key, ... *)
    IF ParseEC(der, id.ec) THEN id.kind := EC; RETURN TRUE END
  ELSIF (der.data[v.val] = 0X) & TLSASN1.PeekTLV(der, pos, lim, t) & (t.tag = TLSASN1.Integer) THEN  (* RSAPrivateKey: 0, n, ... *)
    IF TLSRSA.ParsePrivateKey(der, id.rsa) THEN id.kind := RSA; RETURN TRUE END
  ELSIF der.data[v.val] = 0X THEN  (* PrivateKeyInfo: 0, the algorithm, the key in an OCTET STRING *)
    IF ~TLSASN1.EnterSequence(der, pos, lim, apos, alim) THEN RETURN FALSE END;
    pos := alim;
    IF ~TLSASN1.ReadTLV(der, apos, alim, t) THEN RETURN FALSE END;
    IF ~TLSASN1.ExpectTag(der, pos, lim, TLSASN1.OctetString, v) OR ~TLSASN1.CopyValue(der, v, inner) THEN RETURN FALSE END;
    IF IsOID(der, t, 2AH, 86H, 48H, 0CEH, 3DH, 2, 1, 0, 0, 7) THEN  (* id-ecPublicKey *)
      IF ~TLSASN1.ReadTLV(der, apos, alim, t) OR ~IsP256(der, t) THEN COPY("the key is not on the curve P-256", lastError); RETURN FALSE END;
      IF ParseEC(inner, id.ec) THEN id.kind := EC; RETURN TRUE END
    ELSIF IsOID(der, t, 2AH, 86H, 48H, 86H, 0F7H, 0DH, 1, 1, 1, 9) THEN  (* rsaEncryption *)
      IF TLSRSA.ParsePrivateKey(inner, id.rsa) THEN id.kind := RSA; RETURN TRUE END
    ELSE COPY("the key is neither ECDSA P-256 nor RSA", lastError)
    END
  END;
  RETURN FALSE
END ParseKey;

(** id := the certificates of the PEM file certFile (the leaf first) and the private key of the
  PEM file keyFile; FALSE (lastError says why) if they cannot be read or do not belong together *)
PROCEDURE Load*(certFile, keyFile: ARRAY OF CHAR; VAR id: Identity): BOOLEAN;
VAR b: Bundle; der, pub, point, n, e: TLSBytes.Buffer; from, curve: LONGINT; leaf: Cert; ok: BOOLEAN;
BEGIN
  lastError := ""; id := NIL;
  NEW(b); NEW(id); id.n := 0; id.kind := 0; id.rsa := NIL;
  IF ~TLSCABundle.Load(certFile, b^) THEN COPY("the certificate file cannot be read", lastError); id := NIL; RETURN FALSE END;
  from := 0;
  WHILE (id.n < MaxChain) & TLSPEM.NextCertificateDER(b.text, from, id.certs[id.n]) DO INC(id.n) END;
  IF id.n = 0 THEN COPY("no certificate in the certificate file", lastError); id := NIL; RETURN FALSE END;
  IF ~TLSCABundle.Load(keyFile, b^) THEN COPY("the key file cannot be read", lastError); id := NIL; RETURN FALSE END;
  from := 0;
  IF TLSPEM.NextBlockDER(b.text, "EC PRIVATE KEY", from, der) THEN ok := ParseKey(der, id^)
  ELSE
    from := 0;
    IF TLSPEM.NextBlockDER(b.text, "RSA PRIVATE KEY", from, der) THEN ok := ParseKey(der, id^)
    ELSE from := 0; ok := TLSPEM.NextBlockDER(b.text, "PRIVATE KEY", from, der) & ParseKey(der, id^)
    END
  END;
  TLSBytes.SetLen(der, der.len); from := 0; WHILE from < der.len DO der.data[from] := 0X; INC(from) END;
  TLSCABundle.Init(b^);
  IF ~ok THEN
    IF lastError = "" THEN COPY("no private key in the key file (ECDSA P-256 or RSA)", lastError) END;
    id := NIL; RETURN FALSE
  END;
  NEW(leaf);
  IF ~TLSX509.ParseCertificate(id.certs[0], leaf^) THEN COPY("the certificate cannot be read", lastError); id := NIL; RETURN FALSE END;
  IF id.kind = EC THEN
    IF ~TLSSig.ECPublicKey(leaf.spki, curve, point) OR (curve # TLSECDSA.P256) OR
       ~TLSECDSA.ECDHPublic(TLSECDSA.P256, id.ec, pub) OR (pub.len # point.len) OR ~TLSBytes.EqualConstTime(pub, point) THEN
      COPY("the key does not belong to the certificate", lastError); id := NIL; RETURN FALSE
    END
  ELSE
    IF ~TLSRSA.PublicKey(leaf.spki, n, e) OR (n.len # id.rsa.n.len) OR ~TLSBytes.EqualConstTime(n, id.rsa.n) THEN
      COPY("the key does not belong to the certificate", lastError); id := NIL; RETURN FALSE
    END
  END;
  RETURN TRUE
END Load;

(** pub := the public key of a parsed key: 04 x y for EC, the modulus n for RSA *)
PROCEDURE PublicKey*(VAR id: IdentityDesc; VAR pub: TLSBytes.Buffer): BOOLEAN;
BEGIN
  TLSBytes.Init(pub);
  IF id.kind = EC THEN RETURN TLSECDSA.ECDHPublic(TLSECDSA.P256, id.ec, pub)
  ELSIF id.kind = RSA THEN TLSBytes.Copy(id.rsa.n, pub); RETURN TRUE
  END;
  RETURN FALSE
END PublicKey;

(** the signature scheme of id: EcdsaP256Sha256 or RsaPssRsaeSha256 *)
PROCEDURE Scheme*(id: Identity): LONGINT;
BEGIN
  IF id.kind = RSA THEN RETURN RsaPssRsaeSha256 END;
  RETURN EcdsaP256Sha256
END Scheme;

(** sig := the signature of content (SHA-256) with the key of id, as TLS sends it (DER for ECDSA) *)
PROCEDURE Sign*(id: Identity; VAR content, sig: TLSBytes.Buffer): BOOLEAN;
VAR hash, r, s, salt: TLSBytes.Buffer; d: TLSSHA256.Digest;
BEGIN
  TLSBytes.Init(sig);
  TLSSHA256.DigestBuffer(content, d); TLSSHA256.DigestToBuffer(d, hash);
  IF id.kind = EC THEN
    IF ~TLSECDSA.Sign(TLSECDSA.P256, id.ec, hash, r, s) THEN RETURN FALSE END;
    TLSECDSA.SignatureDER(r, s, sig); RETURN TRUE
  ELSIF id.kind = RSA THEN
    TLSBytes.SetLen(salt, 32);
    IF ~TLS13Random.Fill(salt.data, 32) THEN RETURN FALSE END;
    RETURN TLSRSA.SignPSS(id.rsa, TLSRSA.SHA256, hash, salt, sig)
  END;
  RETURN FALSE
END Sign;

(** hex := the SHA-256 of the first certificate, 64 hex digits in lower case (the fingerprint
  Gemini clients name certificates by) *)
PROCEDURE Fingerprint*(id: Identity; VAR hex: ARRAY OF CHAR);
VAR d: TLSSHA256.Digest; i: LONGINT; digits: ARRAY 17 OF CHAR;
BEGIN
  digits := "0123456789abcdef";
  TLSSHA256.DigestBuffer(id.certs[0], d);
  i := 0; WHILE (i < 32) & (2 * i + 2 < LEN(hex)) DO hex[2 * i] := digits[ORD(d[i]) DIV 16]; hex[2 * i + 1] := digits[ORD(d[i]) MOD 16]; INC(i) END;
  hex[2 * i] := 0X
END Fingerprint;

BEGIN
  lastError := ""
END TLSIdentity.
