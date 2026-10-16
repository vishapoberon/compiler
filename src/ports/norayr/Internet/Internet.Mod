MODULE Internet; (*noch 14.4.2017 / 14.4.2017*)
(** TCP connections by host name and port, on a file descriptor: the interface of the voc
   Internet module (github.com/norayr/Internet), over polpo's Sockets and DNS.
   The same file serves voc and polpo; only the import of Out differs (polpo: Out := out). *)

IMPORT Sockets, DNS, Linux0 := unixNet, Out, SYSTEM;

CONST
  MSGNOSIGNAL = 4000H;  (* no SIGPIPE when the other side has closed *)

TYPE
  Socket* = LONGINT; (* INT32, the file descriptor *)

(** write the bytes buf[0..n) *)
PROCEDURE WriteBytes*(VAR fd: Socket; VAR buf: ARRAY OF CHAR; n: LONGINT): BOOLEAN;
VAR done, r: LONGINT;
BEGIN
  IF n > LEN(buf) THEN n := LEN(buf) END;
  done := 0;
  WHILE done < n DO
    r := Linux0.SendTo0(fd, SYSTEM.ADR(buf[done]), n - done, MSGNOSIGNAL, 0, 0);
    IF r <= 0 THEN
      Out.String("Internet.Write: write failed, error "); Out.Int(-r, 0); Out.Ln;
      RETURN FALSE
    END;
    INC(done, r)
  END;
  RETURN TRUE
END WriteBytes;

(** write the string buf (up to 0X) *)
PROCEDURE Write*(VAR fd: Socket; buf: ARRAY OF CHAR): BOOLEAN;
VAR n: LONGINT;
BEGIN
  n := 0; WHILE (n < LEN(buf)) & (buf[n] # 0X) DO INC(n) END;
  RETURN WriteBytes(fd, buf, n)
END Write;

(** read what is there, at most n bytes if 0 < n < LEN(buf), else at most LEN(buf); n is the
  number of bytes read, 0 at the end. FALSE on errors (n is then the negative error). *)
PROCEDURE ReadBuf*(VAR fd: Socket; VAR buf: ARRAY OF CHAR; VAR n: LONGINT): BOOLEAN;
VAR max: LONGINT;
BEGIN
  max := LEN(buf);
  IF (n > 0) & (n < max) THEN max := n END;
  n := Linux0.Read0(fd, SYSTEM.ADR(buf[0]), max);
  RETURN n >= 0
END ReadBuf;

(** read what is there, at most LEN(buf)-1 bytes, and end it with 0X; FALSE at the end of the
  connection or on errors *)
PROCEDURE Read*(VAR fd: Socket; VAR buf: ARRAY OF CHAR): BOOLEAN;
VAR n: LONGINT;
BEGIN
  n := LEN(buf) - 1;
  IF n <= 0 THEN RETURN FALSE END;
  n := Linux0.Read0(fd, SYSTEM.ADR(buf[0]), n);
  IF n < 0 THEN buf[0] := 0X; RETURN FALSE END;
  buf[n] := 0X;
  RETURN n > 0
END Read;

(** read exactly count bytes (at most LEN(buf)-1), followed by 0X; FALSE if the connection
  ends or fails before *)
PROCEDURE ReadBytes*(VAR fd: Socket; VAR buf: ARRAY OF CHAR; count: LONGINT): BOOLEAN;
VAR done, r: LONGINT;
BEGIN
  IF count > LEN(buf) - 1 THEN
    Out.String("Internet.ReadBytes: more bytes requested than the buffer has"); Out.Ln;
    count := LEN(buf) - 1
  END;
  done := 0; r := 1;
  WHILE (done < count) & (r > 0) DO
    r := Linux0.Read0(fd, SYSTEM.ADR(buf[done]), count - done);
    IF r > 0 THEN INC(done, r) END
  END;
  IF done >= 0 THEN buf[done] := 0X END;
  RETURN done = count
END ReadBytes;

(* the port: a number, or http, https *)
PROCEDURE PortNumber(VAR port: ARRAY OF CHAR): LONGINT;
VAR i, n: LONGINT;
BEGIN
  IF port = "http" THEN RETURN 80 ELSIF port = "https" THEN RETURN 443 END;
  n := 0; i := 0;
  WHILE (port[i] >= "0") & (port[i] <= "9") DO n := n * 10 + ORD(port[i]) - ORD("0"); INC(i) END;
  IF (i = 0) OR (port[i] # 0X) THEN RETURN -1 END;
  RETURN n
END PortNumber;

(** connect to host (a name, an IPv4 or an IPv6 address) and port (a number, http or https);
  the addresses of the host are tried in turn *)
PROCEDURE Connect*(host, port: ARRAY OF CHAR; VAR conn: Socket): BOOLEAN;
VAR a: ARRAY 8 OF Sockets.Address; n, i, p: LONGINT; s: Sockets.Socket;
BEGIN
  conn := -1;
  p := PortNumber(port);
  IF p < 0 THEN Out.String("Internet.Connect: bad port "); Out.String(port); Out.Ln; RETURN FALSE END;
  DNS.Lookup(host, DNS.Any, a, n);
  IF n = 0 THEN
    Out.String("Internet.Connect: "); Out.String(host);
    IF DNS.res = DNS.NotFound THEN Out.String(" not found") ELSE Out.String(": no answer from the name servers") END;
    Out.Ln; RETURN FALSE
  END;
  i := 0; s := NIL;
  WHILE (s = NIL) & (i < n) DO s := Sockets.Connect(a[i], p); INC(i) END;
  IF s = NIL THEN
    Out.String("Internet.Connect: connect failed, error "); Out.Int(-Sockets.res, 0); Out.Ln; RETURN FALSE
  END;
  conn := s.fd;
  RETURN TRUE
END Connect;

(** shut the connection down and close the socket *)
PROCEDURE Disconnect*(fd: Socket);
VAR r: LONGINT;
BEGIN
  r := Linux0.Shutdown0(fd, 2); r := Linux0.Close0(fd)
END Disconnect;

END Internet.
