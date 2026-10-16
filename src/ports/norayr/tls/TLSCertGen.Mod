MODULE TLSCertGen;
(** Self-signed certificates with a new ECDSA P-256 key: for a Gemini identity (the common name
  and maybe a mail address in the subject) or for a server (also a subjectAltName with its host
  name). X.509 v3, a random serial number, valid from now for years, signed with
  ecdsa-with-SHA256; written as PEM, the key as PKCS #8 ("PRIVATE KEY"), as openssl writes them. *)
IMPORT TLSBytes, TLSECDSA, TLSSHA256, TLSPEM, TLSX509Validity, TLSNow, TLS13Random;

CONST
  Sequence = 30H; Set = 31H; Integer = 2; BitString = 3; OctetString = 4; OID = 6;
  UTF8String = 0CH; IA5String = 16H; UTCTime = 17H; GeneralizedTime = 18H;

VAR
  lastError*: ARRAY 64 OF CHAR;

(* appends to b the tag and the length (DER) of a value of len bytes *)
PROCEDURE Head(VAR b: TLSBytes.Buffer; tag, len: LONGINT);
BEGIN
  TLSBytes.AppendByte(b, tag);
  IF len < 128 THEN TLSBytes.AppendByte(b, len)
  ELSIF len < 256 THEN TLSBytes.AppendByte(b, 81H); TLSBytes.AppendByte(b, len)
  ELSE TLSBytes.AppendByte(b, 82H); TLSBytes.AppendByte(b, len DIV 256); TLSBytes.AppendByte(b, len MOD 256)
  END
END Head;

(* appends to b the TLV tag with the value v *)
PROCEDURE TLV(VAR b: TLSBytes.Buffer; tag: LONGINT; VAR v: TLSBytes.Buffer);
BEGIN Head(b, tag, v.len); TLSBytes.Append(b, v)
END TLV;

(* appends to b the TLV tag with the characters of s *)
PROCEDURE Text(VAR b: TLSBytes.Buffer; tag: LONGINT; s: ARRAY OF CHAR);
VAR v: TLSBytes.Buffer;
BEGIN TLSBytes.Init(v); TLSBytes.AppendString(v, s); TLV(b, tag, v)
END Text;

(* appends to b the OID of the hex digits h *)
PROCEDURE Oid(VAR b: TLSBytes.Buffer; h: ARRAY OF CHAR);
VAR v: TLSBytes.Buffer; i, x: LONGINT;
BEGIN
  TLSBytes.Init(v); i := 0;
  WHILE h[i] # 0X DO
    x := ORD(h[i]) - ORD("0"); IF x > 9 THEN x := ORD(h[i]) - ORD("A") + 10 END;
    IF ODD(i) THEN v.data[v.len - 1] := CHR(ORD(v.data[v.len - 1]) + x) ELSE TLSBytes.AppendByte(v, x * 16) END;
    INC(i)
  END;
  TLV(b, OID, v)
END Oid;

PROCEDURE Two(VAR v: TLSBytes.Buffer; x: LONGINT);
BEGIN TLSBytes.AppendByte(v, ORD("0") + x DIV 10 MOD 10); TLSBytes.AppendByte(v, ORD("0") + x MOD 10)
END Two;

(* appends to b the time t: UTCTime before 2050, else GeneralizedTime (RFC 5280 4.1.2.5) *)
PROCEDURE Time(VAR b: TLSBytes.Buffer; VAR t: TLSX509Validity.Time);
VAR v: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(v);
  IF t.year >= 2050 THEN Two(v, t.year DIV 100) END;
  Two(v, t.year); Two(v, t.month); Two(v, t.day); Two(v, t.hour); Two(v, t.minute); Two(v, t.second);
  TLSBytes.AppendByte(v, ORD("Z"));
  IF t.year >= 2050 THEN TLV(b, GeneralizedTime, v) ELSE TLV(b, UTCTime, v) END
END Time;

(* appends to b the Name with the common name cn and maybe the mail address *)
PROCEDURE Name(VAR b: TLSBytes.Buffer; cn, mail: ARRAY OF CHAR);
VAR n, rdn, atv: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(n);
  TLSBytes.Init(atv); Oid(atv, "550403"); Text(atv, UTF8String, cn);           (* 2.5.4.3 commonName *)
  TLSBytes.Init(rdn); TLV(rdn, Sequence, atv); TLV(n, Set, rdn);
  IF mail[0] # 0X THEN
    TLSBytes.Init(atv); Oid(atv, "2A864886F70D010901"); Text(atv, IA5String, mail);  (* emailAddress *)
    TLSBytes.Init(rdn); TLV(rdn, Sequence, atv); TLV(n, Set, rdn)
  END;
  TLV(b, Sequence, n)
END Name;

(* appends to b the AlgorithmIdentifier ecdsa-with-SHA256 *)
PROCEDURE SigAlg(VAR b: TLSBytes.Buffer);
VAR a: TLSBytes.Buffer;
BEGIN TLSBytes.Init(a); Oid(a, "2A8648CE3D040302"); TLV(b, Sequence, a)
END SigAlg;

(* appends to b the AlgorithmIdentifier of a P-256 key *)
PROCEDURE KeyAlg(VAR b: TLSBytes.Buffer);
VAR a: TLSBytes.Buffer;
BEGIN TLSBytes.Init(a); Oid(a, "2A8648CE3D0201"); Oid(a, "2A8648CE3D030107"); TLV(b, Sequence, a)
END KeyAlg;

(* appends to b a BIT STRING of v with no unused bits *)
PROCEDURE Bits(VAR b: TLSBytes.Buffer; VAR v: TLSBytes.Buffer);
VAR w: TLSBytes.Buffer;
BEGIN TLSBytes.Init(w); TLSBytes.AppendByte(w, 0); TLSBytes.Append(w, v); TLV(b, BitString, w)
END Bits;

(** certPEM, keyPEM := a self-signed certificate for cn (and mail, if not "") and its new key,
  valid for years; dns: a host name for a subjectAltName (a server), or "" (an identity) *)
PROCEDURE SelfSigned*(cn, mail, dns: ARRAY OF CHAR; years: LONGINT; VAR certPEM, keyPEM: ARRAY OF CHAR): BOOLEAN;
VAR
  priv, pub, tbs, b, v, w, ext, hash, r, s, sig, cert, key: TLSBytes.Buffer;
  from, till: TLSX509Validity.Time; d: TLSSHA256.Digest; tries, i: LONGINT;
BEGIN
  lastError := ""; certPEM[0] := 0X; keyPEM[0] := 0X;
  IF (cn[0] = 0X) OR (years < 1) THEN COPY("a certificate needs a name and a time", lastError); RETURN FALSE END;
  tries := 0;
  REPEAT
    INC(tries); TLSBytes.SetLen(priv, 32);
    IF ~TLS13Random.Fill(priv.data, 32) THEN COPY("no random bytes", lastError); RETURN FALSE END
  UNTIL TLSECDSA.ECDHPublic(TLSECDSA.P256, priv, pub) OR (tries = 8);
  IF pub.len # 65 THEN COPY("no key", lastError); RETURN FALSE END;
  (* TBSCertificate *)
  TLSBytes.Init(tbs);
  TLSBytes.AppendByte(tbs, 0A0H); TLSBytes.AppendByte(tbs, 3); TLSBytes.AppendByte(tbs, Integer);
  TLSBytes.AppendByte(tbs, 1); TLSBytes.AppendByte(tbs, 2);                                  (* v3 *)
  TLSBytes.SetLen(v, 16);
  IF ~TLS13Random.Fill(v.data, 16) THEN COPY("no random bytes", lastError); RETURN FALSE END;
  v.data[0] := CHR(ORD(v.data[0]) MOD 64 + 1);                                                 (* positive, not 0 *)
  TLV(tbs, Integer, v);                                                                        (* serialNumber *)
  SigAlg(tbs);
  Name(tbs, cn, mail);                                                                         (* issuer *)
  TLSNow.Current(from); till := from; INC(till.year, years);
  IF (till.month = 2) & (till.day = 29) THEN till.day := 28 END;
  TLSBytes.Init(v); Time(v, from); Time(v, till); TLV(tbs, Sequence, v);                       (* validity *)
  Name(tbs, cn, mail);                                                                         (* subject *)
  TLSBytes.Init(v); KeyAlg(v); Bits(v, pub); TLV(tbs, Sequence, v);                            (* subjectPublicKeyInfo *)
  IF dns[0] # 0X THEN                                                                          (* extensions: subjectAltName *)
    TLSBytes.Init(w); Text(w, 82H, dns);                                                       (* [2] dNSName *)
    TLSBytes.Init(b); TLV(b, Sequence, w);
    TLSBytes.Init(v); Oid(v, "551D11"); TLV(v, OctetString, b);
    TLSBytes.Init(ext); TLV(ext, Sequence, v);
    TLSBytes.Init(v); TLV(v, Sequence, ext); TLV(tbs, 0A3H, v)
  END;
  TLSBytes.Init(b); TLV(b, Sequence, tbs); TLSBytes.Copy(b, tbs);
  (* the signature *)
  TLSSHA256.DigestBuffer(tbs, d); TLSSHA256.DigestToBuffer(d, hash);
  IF ~TLSECDSA.Sign(TLSECDSA.P256, priv, hash, r, s) THEN COPY("signing failed", lastError); RETURN FALSE END;
  TLSECDSA.SignatureDER(r, s, sig);
  TLSBytes.Init(v); TLSBytes.Append(v, tbs); SigAlg(v); Bits(v, sig);
  TLSBytes.Init(cert); TLV(cert, Sequence, v);
  (* PKCS #8: 0, the algorithm, an OCTET STRING with the ECPrivateKey 1, the key, [1] the point *)
  TLSBytes.Init(w); TLSBytes.AppendByte(w, Integer); TLSBytes.AppendByte(w, 1); TLSBytes.AppendByte(w, 1);
  TLV(w, OctetString, priv);
  TLSBytes.Init(b); Bits(b, pub); TLV(w, 0A1H, b);
  TLSBytes.Init(b); TLV(b, Sequence, w);
  TLSBytes.Init(v); TLSBytes.AppendByte(v, Integer); TLSBytes.AppendByte(v, 1); TLSBytes.AppendByte(v, 0);
  KeyAlg(v); TLV(v, OctetString, b);
  TLSBytes.Init(key); TLV(key, Sequence, v);
  TLSPEM.Append("CERTIFICATE", cert, certPEM);
  TLSPEM.Append("PRIVATE KEY", key, keyPEM);
  i := 0; WHILE i < 32 DO priv.data[i] := 0X; INC(i) END;
  i := 0; WHILE i < key.len DO key.data[i] := 0X; INC(i) END;
  i := 0; WHILE i < w.len DO w.data[i] := 0X; INC(i) END;
  i := 0; WHILE i < b.len DO b.data[i] := 0X; INC(i) END;
  RETURN TRUE
END SelfSigned;

BEGIN
  lastError := ""
END TLSCertGen.
