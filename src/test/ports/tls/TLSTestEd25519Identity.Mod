MODULE TLSTestEd25519Identity;

IMPORT TLSBytes, TLSIdentity, TLSCertGen, TLSX509, TLSSig, TLSEd25519, Out;

VAR checks, failures, i: LONGINT; seed, other, original: ARRAY 32 OF CHAR; short: ARRAY 31 OF CHAR;
  certificate, content, signature, spki, publicKey, encoded, saved: TLSBytes.Buffer;
  info: POINTER TO TLSX509.CertInfo; id, parsed: TLSIdentity.Identity;

PROCEDURE Check(okay: BOOLEAN);
BEGIN
  INC(checks);
  IF ~okay THEN INC(failures); Out.String("FAIL Ed25519 identity case "); Out.Int(checks, 0); Out.Ln END
END Check;

PROCEDURE Digit(ch: CHAR): LONGINT;
BEGIN IF ch <= "9" THEN RETURN ORD(ch)-ORD("0") END; RETURN ORD(ch)-ORD("a")+10 END Digit;

PROCEDURE Hex(text: ARRAY OF CHAR; VAR bytes: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  TLSBytes.Init(bytes); i := 0;
  WHILE text[i] # 0X DO TLSBytes.AppendByte(bytes, Digit(text[i])*16+Digit(text[i+1])); INC(i, 2) END
END Hex;

PROCEDURE SPKI(prefix: ARRAY OF CHAR);
BEGIN Hex(prefix, spki); TLSBytes.Append(spki, publicKey) END SPKI;

BEGIN
  Hex("9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60", encoded);
  FOR i := 0 TO 31 DO seed[i] := encoded.data[i] END;
  original := seed; other := seed; other[0] := CHR(ORD(other[0])+1);
  Check(TLSEd25519.PublicKey(seed, publicKey.data)); publicKey.len := 32;
  Check(TLSCertGen.Ed25519SelfSigned("peer", seed, 1, certificate));
  NEW(info); Check(TLSX509.ParseCertificate(certificate, info^));
  Check(TLSSig.CertSignedBy(info^, info^));
  Check(TLSSig.Ed25519PublicKey(info.spki, encoded) & TLSBytes.EqualConstTime(encoded, publicKey));
  Check(TLSIdentity.FromEd25519(seed, certificate, id));
  Check((id # NIL) & (TLSIdentity.Scheme(id) = TLSSig.Ed25519));
  Check(TLSIdentity.PublicKey(id^, encoded) & TLSBytes.EqualConstTime(encoded, publicKey));
  Check(~TLSIdentity.FromEd25519(other, certificate, parsed) & (parsed = NIL));
  TLSBytes.Init(content); TLSBytes.AppendString(content, "TLS Ed25519 identity test");
  Check(TLSIdentity.Sign(id, content, signature));
  Check(TLSSig.VerifyScheme(TLSSig.Ed25519, info.spki, content, signature));
  DEC(signature.len); Check(~TLSSig.VerifyScheme(TLSSig.Ed25519, info.spki, content, signature)); INC(signature.len);
  Check(~TLSSig.VerifyScheme(TLSSig.EcdsaP256Sha256, info.spki, content, signature));
  signature.data[63] := CHR(ORD(signature.data[63])+1);
  Check(~TLSSig.VerifyScheme(TLSSig.Ed25519, info.spki, content, signature));
  signature.data[63] := CHR(ORD(signature.data[63])-1);
  TLSBytes.AppendByte(content, 1); Check(~TLSSig.VerifyScheme(TLSSig.Ed25519, info.spki, content, signature));
  SPKI("302a300506032b6570032100"); Check(TLSSig.Ed25519PublicKey(spki, encoded));
  TLSBytes.AppendByte(spki, 0); Check(~TLSSig.Ed25519PublicKey(spki, encoded));
  SPKI("302c300706032b65700500032100"); Check(~TLSSig.Ed25519PublicKey(spki, encoded));
  SPKI("302a300506032b6570032101"); Check(~TLSSig.Ed25519PublicKey(spki, encoded));
  SPKI("302a300506032b6571032100"); Check(~TLSSig.Ed25519PublicKey(spki, encoded));
  SPKI("3029300506032b6570032000"); DEC(spki.len); Check(~TLSSig.Ed25519PublicKey(spki, encoded));
  Hex("302e020100300506032b657004220420", encoded); TLSBytes.AppendOpen(encoded, seed, 32);
  NEW(parsed); Check(TLSIdentity.ParseKey(encoded, parsed^));
  Check(TLSIdentity.PublicKey(parsed^, saved) & TLSBytes.EqualConstTime(saved, publicKey));
  TLSBytes.AppendByte(encoded, 0); Check(~TLSIdentity.ParseKey(encoded, parsed^));
  Hex("3030020100300706032b6570050004220420", encoded); TLSBytes.AppendOpen(encoded, seed, 32);
  Check(~TLSIdentity.ParseKey(encoded, parsed^));
  Hex("302c020100300506032b65700420", encoded); TLSBytes.AppendOpen(encoded, seed, 32);
  Check(~TLSIdentity.ParseKey(encoded, parsed^));
  saved := certificate;
  Check(~TLSCertGen.Ed25519SelfSigned("", seed, 1, certificate)); Check(TLSBytes.EqualConstTime(saved, certificate));
  Check(~TLSCertGen.Ed25519SelfSigned("peer", seed, 0, certificate)); Check(TLSBytes.EqualConstTime(saved, certificate));
  info.signature.data[0] := CHR(ORD(info.signature.data[0])+1); Check(~TLSSig.CertSignedBy(info^, info^));
  TLSBytes.AppendByte(info.sigAlgParams, 0); Check(~TLSSig.CertSignedBy(info^, info^));
  TLSBytes.Init(content); Check(TLSIdentity.Sign(id, content, signature));
  Check(TLSSig.VerifyScheme(TLSSig.Ed25519, info.spki, content, signature));
  Check(~TLSIdentity.FromEd25519(short, certificate, parsed) & (parsed = NIL));
  Check(~TLSCertGen.Ed25519SelfSigned("peer", short, 1, certificate));
  Check(TLSBytes.EqualConstTime(saved, certificate));
  FOR i := 0 TO 31 DO Check(seed[i] = original[i]) END;
  parsed := id; TLSIdentity.Clear(id);
  Check((id = NIL) & ~TLSIdentity.Sign(id, content, signature));
  Check((TLSIdentity.Scheme(parsed) = 0) & ~TLSIdentity.Sign(parsed, content, signature));
  Check(~TLSIdentity.PublicKey(parsed^, encoded));
  TLSIdentity.Clear(parsed); TLSIdentity.Clear(parsed); Check(parsed = NIL);
  Out.String("TLSTestEd25519Identity: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(failures, 0); Out.String(" failed"); Out.Ln;
  IF failures # 0 THEN HALT(100) END
END TLSTestEd25519Identity.
