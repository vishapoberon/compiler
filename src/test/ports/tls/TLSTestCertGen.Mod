MODULE TLSTestCertGen;  (* self-signed certificates: an identity and a server certificate are made, read
  back from their PEM, signed by their own key; the key signs CertificateVerify content that verifies
  with the certificate; the subject has the name and the mail address; the server certificate is for
  its host name *)

IMPORT TLSBytes, TLSCertGen, TLSPEM, TLSIdentity, TLSX509, TLSSig, TLSX509Names, Out;

VAR
  fails, checks: LONGINT;
  info: POINTER TO TLSX509.CertInfo;
  id: TLSIdentity.IdentityDesc;
  certPEM, keyPEM: ARRAY 4096 OF CHAR;

PROCEDURE Check(what: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN INC(fails); Out.String("FAIL "); Out.String(what); Out.String(" (case "); Out.Int(checks, 0); Out.String(")"); Out.Ln END
END Check;

(* does the DER b contain the text t? *)
PROCEDURE Has(VAR b: TLSBytes.Buffer; t: ARRAY OF CHAR): BOOLEAN;
VAR i, j: LONGINT;
BEGIN
  i := 0;
  WHILE i < b.len DO
    j := 0; WHILE (t[j] # 0X) & (i + j < b.len) & (b.data[i + j] = t[j]) DO INC(j) END;
    IF t[j] = 0X THEN RETURN TRUE END;
    INC(i)
  END;
  RETURN FALSE
END Has;

PROCEDURE Case(cn, mail, dns: ARRAY OF CHAR);
VAR cert, key, content, sig, pub, point: TLSBytes.Buffer; from, i, curve: LONGINT; one: TLSIdentity.Identity;
BEGIN
  Check("made", TLSCertGen.SelfSigned(cn, mail, dns, 100, certPEM, keyPEM));
  from := 0; Check("certificate PEM", TLSPEM.NextCertificateDER(certPEM, from, cert));
  from := 0; Check("key PEM", TLSPEM.NextBlockDER(keyPEM, "PRIVATE KEY", from, key));
  Check("key", TLSIdentity.ParseKey(key, id) & (id.kind = TLSIdentity.EC));
  Check("parsed", TLSX509.ParseCertificate(cert, info^));
  Check("signed by itself", TLSSig.CertSignedBy(info^, info^));
  Check("key of the certificate", TLSSig.ECPublicKey(info.spki, curve, point) & TLSIdentity.PublicKey(id, pub) &
    TLSBytes.EqualConstTime(pub, point));
  Check("subject name", Has(info.subject, cn));
  IF mail[0] # 0X THEN Check("subject mail", Has(info.subject, mail)) END;
  IF dns[0] # 0X THEN Check("host name", TLSX509Names.CertMatchesHostname(cert, dns)) END;
  (* the key signs, as an identity *)
  NEW(one); one^ := id; one.n := 1; TLSBytes.Copy(cert, one.certs[0]);
  TLSBytes.Init(content); i := 0; WHILE i < 100 DO TLSBytes.AppendByte(content, i); INC(i) END;
  Check("the key signs", TLSIdentity.Sign(one, content, sig));
  Check("its signature verifies", TLSSig.VerifyScheme(TLSIdentity.Scheme(one), info.spki, content, sig))
END Case;

PROCEDURE Run*;
BEGIN
  fails := 0; checks := 0; NEW(info);
  Case("zq identity", "zq@example.org", "");
  Case("zq server", "", "zq.example.org");
  Out.String("TLSTestCertGen: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END Run;

BEGIN
  Run
END TLSTestCertGen.
