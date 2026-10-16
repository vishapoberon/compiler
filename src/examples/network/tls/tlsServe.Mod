MODULE tlsServe;  (* tlsServe cert.pem key.pem port [n]: a TLS 1.3 server for tests; it answers
  n connections (default 1), each with what the client sent first and the host name it asked for:
  "20 text/plain" for a Gemini request, an HTTP/1.0 response otherwise *)
IMPORT TLS13Server, TLS13Live, Sockets, Args, Out, Strings;
VAR
  cert, key, arg: ARRAY 256 OF CHAR; port, n, k, got, peerPort: LONGINT;
  id: TLS13Server.Identity; s: TLS13Live.State;
  l, c: Sockets.Socket; peer: Sockets.Address;
  req: ARRAY 1025 OF CHAR; ok: BOOLEAN;

PROCEDURE Int(s: ARRAY OF CHAR): LONGINT;
VAR i, v: LONGINT;
BEGIN
  i := 0; v := 0; WHILE (s[i] >= "0") & (s[i] <= "9") DO v := v * 10 + ORD(s[i]) - ORD("0"); INC(i) END;
  RETURN v
END Int;

PROCEDURE Reply(VAR s: TLS13Live.State; VAR req: ARRAY OF CHAR);
VAR ok: BOOLEAN; nl: ARRAY 3 OF CHAR; line: ARRAY 101 OF CHAR; i: LONGINT;
BEGIN
  nl[0] := 0DX; nl[1] := 0AX; nl[2] := 0X;
  i := 0; WHILE i < 99 DO line[i] := CHR(ORD("a") + i MOD 26); INC(i) END;
  line[99] := 0AX; line[100] := 0X;
  IF Strings.Pos("gemini://", req, 0) = 0 THEN ok := TLS13Live.WriteAppString(s, "20 text/plain") & TLS13Live.WriteAppString(s, nl)
  ELSE
    ok := TLS13Live.WriteAppString(s, "HTTP/1.0 200 OK") & TLS13Live.WriteAppString(s, nl) &
      TLS13Live.WriteAppString(s, "Content-Type: text/plain") & TLS13Live.WriteAppString(s, nl) & TLS13Live.WriteAppString(s, nl)
  END;
  ok := ok & TLS13Live.WriteAppString(s, "host: ") & TLS13Live.WriteAppString(s, TLS13Server.serverName) &
    TLS13Live.WriteAppString(s, nl) & TLS13Live.WriteAppString(s, "request: ") & TLS13Live.WriteAppString(s, req);
  IF Strings.Pos("big", req, 0) >= 0 THEN  (* 100 000 bytes more, in several records *)
    i := 0; WHILE ok & (i < 1000) DO ok := TLS13Live.WriteAppString(s, line); INC(i) END
  END
END Reply;

BEGIN
  Args.Get(1, cert); Args.Get(2, key); Args.Get(3, arg); port := Int(arg);
  Args.Get(4, arg); n := Int(arg); IF n = 0 THEN n := 1 END;
  IF (port = 0) OR ~TLS13Server.Load(cert, key, id) THEN
    Out.String("usage: tlsServe cert.pem key.pem port [n]  "); Out.String(TLS13Server.lastError); Out.Ln
  ELSE
    l := Sockets.Listen(Sockets.Inet6, port, 8);
    IF l = NIL THEN Out.String("cannot listen"); Out.Ln
    ELSE
      k := 0;
      WHILE k < n DO
        c := Sockets.Accept(l, peer, peerPort);
        IF c # NIL THEN
          Sockets.SetTimeout(c, 10000);
          IF TLS13Server.Accept(c.fd, id, s) THEN
            IF TLS13Live.ReadAppMax(s, req, 1024, got) THEN Reply(s, req) END;
            TLS13Live.Disconnect(s);
            Out.String("served "); Out.String(TLS13Server.serverName); Out.Ln
          ELSE Out.String("handshake failed: "); Out.String(TLS13Server.lastError); Out.Ln
          END
        END;
        INC(k)
      END;
      Sockets.Close(l)
    END
  END
END tlsServe.
