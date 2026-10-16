MODULE testSockets;  (* polpo's Sockets and DNS under voc:
  testSockets lookup name ...      the addresses of the names
  testSockets get host port path   HTTP/1.0 GET, the answer *)

IMPORT Sockets, DNS, Args, Out;

VAR cmd: ARRAY 16 OF CHAR;

PROCEDURE Number(VAR s: ARRAY OF CHAR): LONGINT;
VAR i, n: LONGINT;
BEGIN
  n := 0; i := 0;
  WHILE (s[i] >= "0") & (s[i] <= "9") DO n := n * 10 + ORD(s[i]) - ORD("0"); INC(i) END;
  RETURN n
END Number;

PROCEDURE Lookup;
VAR i: INTEGER; j, n: LONGINT; name, t: ARRAY 256 OF CHAR; a: ARRAY 8 OF Sockets.Address;
BEGIN
  i := 2;
  WHILE i < Args.argc DO
    Args.Get(i, name); DNS.Lookup(name, DNS.Any, a, n);
    Out.String(name); Out.String(":");
    IF n = 0 THEN Out.String(" error "); Out.Int(DNS.res, 0) END;
    j := 0; WHILE j < n DO Sockets.AddressToString(a[j], t); Out.Char(" "); Out.String(t); INC(j) END;
    Out.Ln; INC(i)
  END
END Lookup;

PROCEDURE Get;
VAR host, port, path: ARRAY 256 OF CHAR; a: ARRAY 8 OF Sockets.Address; n, i, r: LONGINT;
  s: Sockets.Socket; buf: ARRAY 4096 OF CHAR; crlf: ARRAY 3 OF CHAR;
BEGIN
  Args.Get(2, host); Args.Get(3, port); Args.Get(4, path);
  DNS.Lookup(host, DNS.Any, a, n);
  IF n = 0 THEN Out.String("not found"); Out.Ln; RETURN END;
  i := 0; s := NIL;
  WHILE (s = NIL) & (i < n) DO s := Sockets.Connect(a[i], Number(port)); INC(i) END;
  IF s = NIL THEN Out.String("connect failed "); Out.Int(Sockets.res, 0); Out.Ln; RETURN END;
  crlf[0] := 0DX; crlf[1] := 0AX; crlf[2] := 0X;
  r := Sockets.SendString(s, "GET "); r := Sockets.SendString(s, path); r := Sockets.SendString(s, " HTTP/1.0");
  r := Sockets.SendString(s, crlf); r := Sockets.SendString(s, "Host: "); r := Sockets.SendString(s, host);
  r := Sockets.SendString(s, crlf); r := Sockets.SendString(s, crlf);
  n := Sockets.Receive(s, buf, LEN(buf));
  WHILE n > 0 DO
    i := 0; WHILE i < n DO IF buf[i] # 0DX THEN Out.Char(buf[i]) END; INC(i) END;
    n := Sockets.Receive(s, buf, LEN(buf))
  END;
  Sockets.Close(s)
END Get;

BEGIN
  Args.Get(1, cmd);
  IF cmd = "lookup" THEN Lookup ELSIF cmd = "get" THEN Get
  ELSE Out.String("usage: testSockets lookup name ... | get host port path"); Out.Ln
  END
END testSockets.
