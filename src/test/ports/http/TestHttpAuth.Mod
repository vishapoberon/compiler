MODULE TestHttpAuth;
IMPORT http, Strings := oocStrings, Out;
VAR checks, failed: LONGINT;

PROCEDURE Check(value: BOOLEAN);
BEGIN INC(checks); IF ~value THEN INC(failed) END END Check;

PROCEDURE Case(user, password, encoded: ARRAY OF CHAR);
VAR client: http.Client; expected: ARRAY 128 OF CHAR; n: LONGINT;
BEGIN
  client := http.Create("localhost", "80", "/");
  http.appendUserPasswdHdr(client, user, password);
  Check(LEN(client.reqHeader^) = 7);
  expected := "Authorization: Basic "; Strings.Append(encoded, expected);
  n := Strings.Length(expected); expected[n] := 0DX; expected[n+1] := 0AX; expected[n+2] := 0X;
  IF LEN(client.reqHeader^) > 1 THEN
    Check(client.reqHeader[LEN(client.reqHeader^)-2]^ = expected)
  ELSE Check(FALSE)
  END
END Case;

BEGIN
  Case("", "", "Og=="); Case("u", "", "dTo="); Case("", "p", "OnA=");
  Case("u", "p", "dTpw"); Case("user", "password", "dXNlcjpwYXNzd29yZA==");
  Case("Aladdin", "open sesame", "QWxhZGRpbjpvcGVuIHNlc2FtZQ==");
  Out.String("TestHttpAuth: "); Out.Int(checks, 0); Out.String(" checks, ");
  Out.Int(failed, 0); Out.String(" failed"); Out.Ln;
  IF failed # 0 THEN HALT(100) END
END TestHttpAuth.
