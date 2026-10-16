MODULE TLSTestIdentity;  (* identities: certificates with an RSA key (PKCS #8 and PKCS #1) and with a P-256
  key are loaded, their signatures of a CertificateVerify verify with the key of the certificate,
  a changed content does not, and a key with the certificate of another is refused. The files are
  in the directory of the environment variable TLS_TEST_CERTS (default test/certs). *)

IMPORT Kernel, TLSBytes, TLSIdentity, TLSX509, TLSSig, Out;

VAR
  fails, checks: LONGINT;
  dir: ARRAY 256 OF CHAR;
  leaf: POINTER TO TLSX509.CertInfo;

PROCEDURE Check(what: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN INC(fails); Out.String("FAIL "); Out.String(what); Out.String(" (case "); Out.Int(checks, 0); Out.String(")"); Out.Ln END
END Check;

PROCEDURE Path(name: ARRAY OF CHAR; VAR path: ARRAY OF CHAR);
VAR i, j: LONGINT;
BEGIN
  COPY(dir, path); i := 0; WHILE path[i] # 0X DO INC(i) END;
  path[i] := "/"; INC(i); j := 0;
  WHILE name[j] # 0X DO path[i] := name[j]; INC(i); INC(j) END;
  path[i] := 0X
END Path;

(* the identity of cert and key signs, and its signatures verify *)
PROCEDURE Case(what, cert, key: ARRAY OF CHAR; kind: LONGINT);
VAR c, k: ARRAY 300 OF CHAR; id: TLSIdentity.Identity; content, sig: TLSBytes.Buffer; i: LONGINT; fp: ARRAY 65 OF CHAR;
BEGIN
  Path(cert, c); Path(key, k);
  Check(what, TLSIdentity.Load(c, k, id));
  IF id # NIL THEN
    Check("kind", id.kind = kind);
    TLSBytes.Init(content);
    i := 0; WHILE i < 64 DO TLSBytes.AppendByte(content, 20H); INC(i) END;
    TLSBytes.AppendString(content, "TLS 1.3, client CertificateVerify"); TLSBytes.AppendByte(content, 0);
    i := 0; WHILE i < 32 DO TLSBytes.AppendByte(content, i * 7); INC(i) END;
    Check("sign", TLSIdentity.Sign(id, content, sig));
    Check("certificate", TLSX509.ParseCertificate(id.certs[0], leaf^));
    Check("verifies", TLSSig.VerifyScheme(TLSIdentity.Scheme(id), leaf.spki, content, sig));
    content.data[70] := "x";
    Check("changed content", ~TLSSig.VerifyScheme(TLSIdentity.Scheme(id), leaf.spki, content, sig));
    TLSIdentity.Fingerprint(id, fp);
    Check("fingerprint", (fp[63] # 0X) & (fp[64] = 0X))
  END
END Case;

PROCEDURE Run*;
VAR c, k: ARRAY 300 OF CHAR; id: TLSIdentity.Identity;
BEGIN
  fails := 0; checks := 0; NEW(leaf);
  Kernel.GetConfig("TLS_TEST_CERTS", dir);
  IF dir = "" THEN dir := "test/certs" END;
  Case("RSA, PKCS 8", "id_rsa.crt", "id_rsa.key", TLSIdentity.RSA);
  Case("RSA, PKCS 1", "id_rsa.crt", "id_rsa1.key", TLSIdentity.RSA);
  Case("P-256", "id_ec.crt", "id_ec.key", TLSIdentity.EC);
  Path("id_rsa.crt", c); Path("id_ec.key", k);
  Check("a key with another certificate", ~TLSIdentity.Load(c, k, id));
  Path("id_ec.crt", c); Path("id_rsa.key", k);
  Check("an RSA key with an EC certificate", ~TLSIdentity.Load(c, k, id));
  Out.String("TLSTestIdentity: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END Run;

BEGIN
  Run
END TLSTestIdentity.
