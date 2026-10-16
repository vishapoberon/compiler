MODULE CobwebTest;  (* CobwebTest.Run: cobweb serves this directory in two child processes, over HTTP and
  over HTTPS (cert.pem and key.pem for localhost); this process asks for pages and prints the
  status lines and whether the bodies are right *)

IMPORT SYSTEM, Linux0, Kernel, Sockets, TLS13Live, cobweb, out;

VAR s: POINTER TO TLS13Live.State;

PROCEDURE Sleep(ms: LONGINT);  (* GetTimer counts milliseconds on every port (TimeUnit) *)
VAR t: LONGINT;
BEGIN t := Kernel.GetTimer(); WHILE Kernel.GetTimer() - t < ms DO END
END Sleep;

(* waits until port takes connections (the probe is one connection of the server) *)
PROCEDURE Ready(port: LONGINT): BOOLEAN;
VAR a: Sockets.Address; c: Sockets.Socket; i: LONGINT;
BEGIN
  IF ~Sockets.ParseAddress("127.0.0.1", a) THEN RETURN FALSE END;
  i := 0; c := NIL;
  WHILE (c = NIL) & (i < 100) DO c := Sockets.Connect(a, port); IF c = NIL THEN Sleep(100) END; INC(i) END;
  IF c = NIL THEN RETURN FALSE END;
  Sockets.Close(c); RETURN TRUE
END Ready;

PROCEDURE IntToStr(x: LONGINT; VAR a: ARRAY OF CHAR);
VAR d: ARRAY 12 OF CHAR; i, j: LONGINT;
BEGIN
  i := 0; REPEAT d[i] := CHR(x MOD 10 + ORD("0")); x := x DIV 10; INC(i) UNTIL x = 0;
  j := 0; WHILE i > 0 DO DEC(i); a[j] := d[i]; INC(j) END; a[j] := 0X
END IntToStr;

PROCEDURE Append(VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR);
VAR i, j: LONGINT;
BEGIN
  i := 0; WHILE a[i] # 0X DO INC(i) END;
  j := 0; WHILE (b[j] # 0X) & (i < LEN(a) - 1) DO a[i] := b[j]; INC(i); INC(j) END;
  a[i] := 0X
END Append;

(* prints the status line of the answer in buf, and whether it contains text *)
PROCEDURE Show(VAR buf: ARRAY OF CHAR; text: ARRAY OF CHAR);
VAR i, j: LONGINT; found: BOOLEAN;
BEGIN
  i := 0; WHILE (buf[i] # 0X) & (buf[i] # 0DX) DO INC(i) END;
  out.String("status: "); j := 0; WHILE j < i DO out.Char(buf[j]); INC(j) END; out.Ln;
  IF text[0] # 0X THEN
    found := FALSE; i := 0;
    WHILE ~found & (buf[i] # 0X) DO
      j := 0; WHILE (text[j] # 0X) & (buf[i + j] = text[j]) DO INC(j) END;
      found := text[j] = 0X; INC(i)
    END;
    IF found THEN out.String("has: ") ELSE out.String("missing: ") END;
    out.String(text); out.Ln
  END
END Show;

(* the request line "method path HTTP/1.1" with a Host field *)
PROCEDURE Request(method, path: ARRAY OF CHAR; VAR req: ARRAY OF CHAR);
VAR nl: ARRAY 3 OF CHAR;
BEGIN
  nl[0] := 0DX; nl[1] := 0AX; nl[2] := 0X;
  COPY(method, req); Append(req, " "); Append(req, path); Append(req, " HTTP/1.1"); Append(req, nl);
  Append(req, "Host: localhost"); Append(req, nl); Append(req, nl)
END Request;

(* over HTTP *)
PROCEDURE Get(port: LONGINT; method, path, text: ARRAY OF CHAR);
VAR a: Sockets.Address; c: Sockets.Socket; req: ARRAY 256 OF CHAR; buf: ARRAY 8192 OF CHAR; n, got: LONGINT;
BEGIN
  IF ~Sockets.ParseAddress("127.0.0.1", a) THEN RETURN END;
  c := Sockets.Connect(a, port);
  IF c = NIL THEN out.String("no connection"); out.Ln; RETURN END;
  Request(method, path, req); n := 0; WHILE req[n] # 0X DO INC(n) END;
  IF Sockets.Send(c, req, n) # n THEN out.String("not sent"); out.Ln END;
  n := 0; got := 1;
  WHILE (got > 0) & (n < LEN(buf) - 1) DO got := Sockets.Receive(c, buf[n], LEN(buf) - 1 - n); IF got > 0 THEN INC(n, got) END END;
  buf[n] := 0X; Sockets.Close(c);
  Show(buf, text)
END Get;

(* over HTTPS *)
PROCEDURE GetTLS(port: ARRAY OF CHAR; path, text: ARRAY OF CHAR);
VAR req: ARRAY 256 OF CHAR; buf: ARRAY 8192 OF CHAR; n, got, i: LONGINT;
BEGIN
  IF ~TLS13Live.ConnectPinned("localhost", port, s^, "") THEN out.String("no connection: "); out.String(TLS13Live.lastError); out.Ln; RETURN END;
  Request("GET", path, req);
  IF ~TLS13Live.WriteAppString(s^, req) THEN out.String("not sent"); out.Ln END;
  n := 0;
  WHILE (n < LEN(buf) - 1) & TLS13Live.ReadAppMax(s^, req, 255, got) DO
    i := 0; WHILE (i < got) & (n < LEN(buf) - 1) DO buf[n] := req[i]; INC(n); INC(i) END
  END;
  buf[n] := 0X; TLS13Live.Disconnect(s^);
  Show(buf, text)
END GetTLS;

PROCEDURE Wait(pid: LONGINT; what: ARRAY OF CHAR);
VAR r, st: LONGINT;
BEGIN
  st := 0; r := Linux0.Waitpid0(pid, SYSTEM.ADR(st), 0);
  out.String(what);
  IF (r = pid) & (st = 0) THEN out.String(" server ended") ELSE out.String(" server failed") END;
  out.Ln
END Wait;

PROCEDURE Run*;
VAR plain, secure, port: LONGINT; p: ARRAY 8 OF CHAR;
BEGIN
  IF s = NIL THEN NEW(s) END;
  port := 20000 + Kernel.GetTimer() MOD 20000;
  plain := Linux0.Fork0();
  IF plain = 0 THEN cobweb.Start(".", "", "", "", port, 6, 4, 5); Linux0.Exit0(0) END;
  IF ~Ready(port) THEN out.String("the HTTP server did not start"); out.Ln
  ELSE
    Get(port, "GET", "/", "zq test site");
    Get(port, "HEAD", "/index.html", "Content-Length: 30");
    Get(port, "GET", "/nothing.html", "");
    Get(port, "POST", "/", "Allow: GET, HEAD");
    Get(port, "GET", "/x/../index.html", "")
  END;
  Wait(plain, "the HTTP");
  INC(port); IntToStr(port, p);
  secure := Linux0.Fork0();
  IF secure = 0 THEN cobweb.Start(".", "cert.pem", "key.pem", "localhost", port, 2, 4, 5); Linux0.Exit0(0) END;
  IF ~Ready(port) THEN out.String("the HTTPS server did not start"); out.Ln
  ELSE GetTLS(p, "/", "zq test site")
  END;
  Wait(secure, "the HTTPS")
END Run;

END CobwebTest.
