MODULE testHttps;  (* testHttps dir: https against the servers of tls/tools/testservers.py
  (started with dir; SSL_CERT_FILE=dir/ca.pem) and http against a plain server on 127.0.0.1:18480
  that serves dir. testHttps net: https://example.com/ and http://example.com/ (the system's
  CA bundle) *)

IMPORT https, http, Args, Files, Out, Platform;

VAR dir: ARRAY 256 OF CHAR; checks, fails: LONGINT;

PROCEDURE Check(name: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN INC(fails); Out.String("FAIL ") ELSE Out.String("ok   ") END;
  Out.String(name); Out.Ln
END Check;

PROCEDURE Same(h: http.Client; body: ARRAY OF CHAR): BOOLEAN;
VAR i: LONGINT;
BEGIN
  i := 0; WHILE (i < h.rspnContentLength) & (body[i] # 0X) & (h.rspnBody[i] = body[i]) DO INC(i) END;
  RETURN (i = h.rspnContentLength) & (body[i] = 0X)
END Same;

(* the body is the file dir/name *)
PROCEDURE SameFile(h: http.Client; name: ARRAY OF CHAR): BOOLEAN;
VAR f: Files.File; r: Files.Rider; path: ARRAY 512 OF CHAR; i, j: LONGINT; c: CHAR; ok: BOOLEAN;
BEGIN
  COPY(dir, path); i := 0; WHILE path[i] # 0X DO INC(i) END;
  path[i] := "/"; INC(i); j := 0;
  WHILE name[j] # 0X DO path[i] := name[j]; INC(i); INC(j) END;
  path[i] := 0X;
  ok := FALSE;
  f := Files.Old(path);
  IF (f # NIL) & (Files.Length(f) = h.rspnContentLength) THEN
    Files.Set(r, f, 0); i := 0; ok := TRUE;
    WHILE ok & (i < h.rspnContentLength) DO Files.Read(r, c); ok := c = h.rspnBody[i]; INC(i) END
  END;
  RETURN ok
END SameFile;

PROCEDURE Good(url, body: ARRAY OF CHAR);
VAR h: http.Client; ok: BOOLEAN;
BEGIN
  ok := https.Get(url, h) & h.rspnComplete & Same(h, body);
  IF ~ok THEN https.Report(h); Out.Ln END;
  Check(url, ok)
END Good;

PROCEDURE Refused(url, why: ARRAY OF CHAR);
VAR h: http.Client;
BEGIN
  Check(why, ~https.Get(url, h))
END Refused;

PROCEDURE Incomplete(url, why: ARRAY OF CHAR);
VAR h: http.Client;
BEGIN
  Check(why, https.Get(url, h) & ~h.rspnComplete & ~https.Save(h, "zq_not_saved"))
END Incomplete;

PROCEDURE Big(url: ARRAY OF CHAR);
VAR h: http.Client;
BEGIN
  Check(url, https.Get(url, h) & h.rspnComplete & (h.rspnContentLength = 1048576) & SameFile(h, "big.ref"))
END Big;

PROCEDURE Net(url: ARRAY OF CHAR);
VAR h: http.Client; ok: BOOLEAN;
BEGIN
  ok := https.Get(url, h) & h.rspnComplete & (h.rspnContentLength > 0);
  https.Report(h); Out.Ln;
  Check(url, ok)
END Net;

BEGIN
  checks := 0; fails := 0;
  Args.Get(1, dir);
  IF dir = "" THEN Out.String("usage: testHttps dir | net"); Out.Ln; Platform.Exit(1) END;
  IF dir = "net" THEN Net("https://example.com/"); Net("http://example.com/")
  ELSE
    Good("https://localhost:18443/", "ok");  (* RSA *)
    Good("https://localhost:18444/", "ok");  (* ECDSA *)
    Refused("https://localhost:18445/", "refused: wrong host name");
    Refused("https://localhost:18446/", "refused: untrusted CA");
    Refused("https://localhost:18447/", "refused: expired");
    Refused("https://localhost:18448/", "refused: self-signed");
    Refused("https://localhost:18449/", "refused: TLS 1.2 only");
    Incomplete("https://localhost:18450/", "incomplete: no close_notify");
    Good("https://localhost:18451/", "proper end");
    Incomplete("https://localhost:18452/", "incomplete: shorter than Content-Length");
    Big("https://localhost:18453/");
    Good("https://127.0.0.1:18454/", "ok");
    Good("https://[::1]:18455/", "ok");
    Good("https://localhost:18456/", "ok");  (* P-521 *)
    Good("https://localhost:18457/", "ok");  (* RSASSA-PSS certificate *)
    Good("https://localhost:18458/", "ok");  (* asks for an optional client certificate *)
    Big("http://127.0.0.1:18480/big.ref");
    Refused("ftp://localhost/", "refused: not http or https");
  END;
  Out.String("testHttps: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln;
  IF fails # 0 THEN Platform.Exit(1) END
END testHttps.
