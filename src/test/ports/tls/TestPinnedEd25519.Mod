MODULE TestPinnedEd25519;
IMPORT Args, Out, TLSBytes, TLSCABundle, TLSPEM, TLS13Auth, TLSNow, TLSX509Validity;
VAR path, hex, role, expected: ARRAY 4096 OF CHAR;
  text: POINTER TO TLSCABundle.Bundle; cert, pin, spki: TLSBytes.Buffer;
  now: TLSX509Validity.Time; i, pos: LONGINT; accepted: BOOLEAN;

PROCEDURE Digit(c: CHAR): LONGINT;
BEGIN IF c <= "9" THEN RETURN ORD(c)-ORD("0") END; RETURN ORD(c)-ORD("a")+10 END Digit;

BEGIN
  Args.Get(1, path); Args.Get(2, hex); Args.Get(3, role); Args.Get(4, expected);
  NEW(text);
  IF ~TLSCABundle.Load(path, text^) THEN HALT(1) END;
  pos := 0;
  IF ~TLSPEM.NextCertificateDER(text.text, pos, cert) THEN HALT(2) END;
  TLSBytes.Init(pin); i := 0;
  WHILE hex[i] # 0X DO TLSBytes.AppendByte(pin, Digit(hex[i])*16+Digit(hex[i+1])); INC(i, 2) END;
  TLSNow.Current(now); accepted := TLS13Auth.PinnedEd25519(cert, pin, now, role = "server", spki);
  IF (accepted # (expected = "accept")) OR (~accepted & (spki.len # 0)) THEN HALT(3) END;
  Out.String("PASS pinned Ed25519 "); Out.String(role); Out.String(" "); Out.String(expected); Out.Ln
END TestPinnedEd25519.
