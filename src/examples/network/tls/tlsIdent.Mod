MODULE tlsIdent;  (* tlsIdent host port path [cert.pem key.pem]: a TLS 1.3 connection with a client
  certificate, for tests; sends "GET path HTTP/1.0" and prints the answer *)
IMPORT TLS13Live, TLSIdentity, Args, Out;
VAR host, port, path, cert, key, req: ARRAY 256 OF CHAR; s: TLS13Live.State; id: TLSIdentity.Identity;
  buf: ARRAY 4097 OF CHAR; n, i: LONGINT; ok: BOOLEAN;
BEGIN
  Args.Get(1, host); Args.Get(2, port); Args.Get(3, path); Args.Get(4, cert); Args.Get(5, key);
  IF cert # "" THEN
    IF ~TLSIdentity.Load(cert, key, id) THEN Out.String("identity: "); Out.String(TLSIdentity.lastError); Out.Ln; HALT(1) END;
    TLS13Live.SetIdentity(id)
  END;
  IF ~TLS13Live.ConnectPinned(host, port, s, "") THEN Out.String("refused: "); Out.String(TLS13Live.lastError); Out.Ln; HALT(1) END;
  Out.String("certificate "); Out.String(TLS13Live.certPin); Out.Ln;
  IF TLS13Live.identitySent THEN Out.String("identity sent"); Out.Ln END;
  req := "GET "; i := 4; n := 0; WHILE path[n] # 0X DO req[i] := path[n]; INC(i); INC(n) END;
  req[i] := " "; req[i+1] := "H"; req[i+2] := "T"; req[i+3] := "T"; req[i+4] := "P"; req[i+5] := "/"; req[i+6] := "1"; req[i+7] := ".";
  req[i+8] := "0"; req[i+9] := 0DX; req[i+10] := 0AX; req[i+11] := 0DX; req[i+12] := 0AX; req[i+13] := 0X;
  ok := TLS13Live.WriteAppString(s, req);
  WHILE TLS13Live.ReadAppMax(s, buf, 4096, n) DO buf[n] := 0X; Out.String(buf) END;
  TLS13Live.Disconnect(s)
END tlsIdent.
