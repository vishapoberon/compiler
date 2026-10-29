MODULE Sockets;  (** TCP and UDP over IPv4 and IPv6, with the socket system calls of Linux0 *)

(* Addresses are IPv4 (4 bytes) or IPv6 (16 bytes), in network byte order; ports are numbers.
   Bytes are read with LONG(ORD(c)): ORD gives an INTEGER (16 bits), and b * 256 would overflow.
   Errors: the procedures return FALSE or a negative count, res of the socket (or the variable
   res of the module) holds the negative Linux error number. *)

IMPORT Linux0 := unixNet, SYSTEM;

CONST
  Inet4* = 4; Inet6* = 6;  (** address families *)
  AFINET = 2; AFINET6 = 10;
  IPPROTOIPV6 = 41; IPV6V6ONLY = 26;
  MSGNOSIGNAL = 4000H;  (* no SIGPIPE when the other side has closed *)
  SOCKCLOEXEC = 80000H;

TYPE
  Address* = RECORD
    family*: INTEGER;  (** Inet4 or Inet6 *)
    addr*: ARRAY 16 OF CHAR  (** the bytes; IPv4 in addr[0..3] *)
  END;

  Socket* = POINTER TO SocketDesc;
  SocketDesc* = RECORD
    fd*: LONGINT;  (** the file descriptor, -1 when closed *)
    res*: LONGINT  (** the last error, negative, 0 if none *)
  END;

  Endpoint* = RECORD
    address*: Address;
    port*: LONGINT;
    scope*: LONGINT  (** the 32 bits of the IPv6 scope (unsigned: below 0 from 2^31 on) *)
  END;

VAR
  res*: LONGINT;  (** the error of the last procedure that did not get a socket *)
  sockStream, sockDgram, solSocket, soReuseAddr, soRcvTimeo, soSndTimeo: LONGINT;  (* MIPS numbers them differently *)

(* ----- addresses ----- *)

PROCEDURE HexDigit(c: CHAR): LONGINT;
BEGIN
  IF (c >= "0") & (c <= "9") THEN RETURN ORD(c) - ORD("0")
  ELSIF (CAP(c) >= "A") & (CAP(c) <= "F") THEN RETURN ORD(CAP(c)) - ORD("A") + 10
  END;
  RETURN -1
END HexDigit;

(* an IPv4 address in s from i on, into b[at..at+3]; i moves past it *)
PROCEDURE Parse4(VAR s: ARRAY OF CHAR; VAR i: LONGINT; VAR b: ARRAY OF CHAR; at: LONGINT): BOOLEAN;
VAR part, n, digits: LONGINT;
BEGIN
  part := 0;
  WHILE part < 4 DO
    n := 0; digits := 0;
    WHILE (i < LEN(s)) & (s[i] >= "0") & (s[i] <= "9") DO n := n * 10 + ORD(s[i]) - ORD("0"); INC(i); INC(digits) END;
    IF (digits = 0) OR (digits > 3) OR (n > 255) THEN RETURN FALSE END;
    b[at + part] := CHR(n); INC(part);
    IF part < 4 THEN IF (i < LEN(s)) & (s[i] = ".") THEN INC(i) ELSE RETURN FALSE END END
  END;
  RETURN TRUE
END Parse4;

(** parse an IPv4 address (192.0.2.1) or an IPv6 address (2001:db8::1, ::1, [::1],
  ::ffff:192.0.2.1) *)
PROCEDURE ParseAddress*(s: ARRAY OF CHAR; VAR a: Address): BOOLEAN;
VAR i, j, n, d, groups, gap, k: LONGINT; g: ARRAY 8 OF LONGINT; b: ARRAY 16 OF CHAR; dot: BOOLEAN;
BEGIN
  i := 0; WHILE i < 16 DO a.addr[i] := 0X; INC(i) END;
  (* [..] around an IPv6 address *)
  IF s[0] = "[" THEN
    i := 1; WHILE (i < LEN(s)) & (s[i] # 0X) & (s[i] # "]") DO s[i-1] := s[i]; INC(i) END; s[i-1] := 0X
  END;
  (* IPv4 if there is no ":" *)
  i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) & (s[i] # ":") DO INC(i) END;
  IF (i >= LEN(s)) OR (s[i] = 0X) THEN
    i := 0;
    IF Parse4(s, i, a.addr, 0) & ((i >= LEN(s)) OR (s[i] = 0X)) THEN a.family := Inet4; RETURN TRUE END;
    RETURN FALSE
  END;
  (* IPv6: up to 8 groups, one "::" for a run of zero groups, maybe a dotted IPv4 at the end *)
  groups := 0; gap := -1; i := 0;
  IF (s[0] = ":") & (s[1] = ":") THEN gap := 0; i := 2 END;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO
    IF groups >= 8 THEN RETURN FALSE END;
    (* a dotted IPv4 address as the last 32 bits? *)
    j := i; dot := FALSE;
    WHILE (j < LEN(s)) & (s[j] # 0X) & (s[j] # ":") DO IF s[j] = "." THEN dot := TRUE END; INC(j) END;
    IF dot THEN
      IF groups > 6 THEN RETURN FALSE END;
      IF ~Parse4(s, i, b, 0) OR (i < LEN(s)) & (s[i] # 0X) THEN RETURN FALSE END;
      g[groups] := LONG(ORD(b[0])) * 256 + LONG(ORD(b[1])); g[groups+1] := LONG(ORD(b[2])) * 256 + LONG(ORD(b[3])); INC(groups, 2)
    ELSE
      n := 0; k := 0;
      WHILE (i < LEN(s)) & (HexDigit(s[i]) >= 0) DO n := n * 16 + HexDigit(s[i]); INC(i); INC(k) END;
      IF (k = 0) OR (k > 4) THEN RETURN FALSE END;
      g[groups] := n; INC(groups);
      IF (i < LEN(s)) & (s[i] = ":") THEN
        INC(i);
        IF (i < LEN(s)) & (s[i] = ":") THEN
          IF gap >= 0 THEN RETURN FALSE END;  (* only one "::" *)
          gap := groups; INC(i)
        ELSIF (i >= LEN(s)) OR (s[i] = 0X) THEN RETURN FALSE  (* a trailing single ":" *)
        END
      ELSIF (i < LEN(s)) & (s[i] # 0X) THEN RETURN FALSE
      END
    END
  END;
  IF gap < 0 THEN
    IF groups # 8 THEN RETURN FALSE END
  ELSIF groups > 7 THEN RETURN FALSE
  END;
  (* groups before the gap, zeros, groups after it *)
  d := 0; j := 0;
  WHILE j < groups DO
    IF j = gap THEN d := d + (8 - groups) END;
    a.addr[2*d] := CHR(g[j] DIV 256); a.addr[2*d+1] := CHR(g[j] MOD 256);
    INC(d); INC(j)
  END;
  a.family := Inet6;
  RETURN TRUE
END ParseAddress;

PROCEDURE AppendDec(VAR s: ARRAY OF CHAR; VAR i: LONGINT; n: LONGINT);
VAR d: ARRAY 12 OF CHAR; k: LONGINT;
BEGIN
  k := 0; REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL (n <= 0) OR (k = LEN(d));
  WHILE (k > 0) & (i < LEN(s) - 1) DO DEC(k); s[i] := d[k]; INC(i) END
END AppendDec;

PROCEDURE AppendHex(VAR s: ARRAY OF CHAR; VAR i: LONGINT; n: LONGINT);
CONST Hex = "0123456789abcdef";
VAR d: ARRAY 8 OF CHAR; hex: ARRAY 17 OF CHAR; k: LONGINT;
BEGIN
  hex := Hex; k := 0;
  REPEAT d[k] := hex[n MOD 16]; n := n DIV 16; INC(k) UNTIL (n <= 0) OR (k = LEN(d));
  WHILE (k > 0) & (i < LEN(s) - 1) DO DEC(k); s[i] := d[k]; INC(i) END
END AppendHex;

(** an IPv6 address holding an IPv4 address: ::ffff:a.b.c.d *)
PROCEDURE Mapped*(VAR a: Address): BOOLEAN;
VAR i: LONGINT;
BEGIN
  IF a.family # Inet6 THEN RETURN FALSE END;
  i := 0; WHILE (i < 10) & (a.addr[i] = 0X) DO INC(i) END;
  RETURN (i = 10) & (a.addr[10] = 0FFX) & (a.addr[11] = 0FFX)
END Mapped;

(** the address as text: 192.0.2.1, 2001:db8::1 (the longest run of zero groups as ::) *)
PROCEDURE AddressToString*(VAR a: Address; VAR s: ARRAY OF CHAR);
VAR i, j, best, bestLen, run, start: LONGINT; g: ARRAY 8 OF LONGINT;
BEGIN
  i := 0;
  IF a.family = Inet4 THEN
    j := 0;
    WHILE j < 4 DO AppendDec(s, i, LONG(ORD(a.addr[j]))); IF (j < 3) & (i < LEN(s) - 1) THEN s[i] := "."; INC(i) END; INC(j) END
  ELSIF Mapped(a) THEN  (* ::ffff:a.b.c.d, an IPv4 address seen through IPv6 *)
    s[0] := ":"; s[1] := ":"; s[2] := "f"; s[3] := "f"; s[4] := "f"; s[5] := "f"; s[6] := ":"; i := 7;
    j := 12;
    WHILE j < 16 DO AppendDec(s, i, LONG(ORD(a.addr[j]))); IF (j < 15) & (i < LEN(s) - 1) THEN s[i] := "."; INC(i) END; INC(j) END
  ELSE
    j := 0; WHILE j < 8 DO g[j] := LONG(ORD(a.addr[2*j])) * 256 + LONG(ORD(a.addr[2*j+1])); INC(j) END;
    best := -1; bestLen := 1; j := 0;  (* runs of at least 2 zero groups *)
    WHILE j < 8 DO
      IF g[j] = 0 THEN
        start := j; run := 0; WHILE (j < 8) & (g[j] = 0) DO INC(run); INC(j) END;
        IF run > bestLen THEN best := start; bestLen := run END
      ELSE INC(j)
      END
    END;
    j := 0;
    WHILE j < 8 DO
      IF j = best THEN
        IF i < LEN(s) - 2 THEN s[i] := ":"; s[i+1] := ":"; INC(i, 2) END; j := j + bestLen
      ELSE
        IF (j > 0) & (j # best + bestLen) & (i < LEN(s) - 1) THEN s[i] := ":"; INC(i) END;
        AppendHex(s, i, g[j]); INC(j)
      END
    END
  END;
  s[i] := 0X
END AddressToString;

(** the address for any local address (0.0.0.0 or ::) *)
PROCEDURE AnyAddress*(family: INTEGER; VAR a: Address);
VAR i: LONGINT;
BEGIN
  a.family := family; i := 0; WHILE i < 16 DO a.addr[i] := 0X; INC(i) END
END AnyAddress;

(* the sockaddr of address a and port: sockaddr_in (16 bytes) or sockaddr_in6 (28) *)
PROCEDURE SockAddr(VAR a: Address; port: LONGINT; VAR sa: ARRAY OF CHAR; VAR len: LONGINT);
VAR i: LONGINT; f: INTEGER;
BEGIN
  i := 0; WHILE i < 28 DO sa[i] := 0X; INC(i) END;
  IF a.family = Inet6 THEN f := AFINET6 ELSE f := AFINET END;
  SYSTEM.PUT(SYSTEM.ADR(sa[0]), f);  (* host byte order *)
  sa[2] := CHR(port DIV 256 MOD 256); sa[3] := CHR(port MOD 256);  (* network byte order *)
  IF a.family = Inet6 THEN
    i := 0; WHILE i < 16 DO sa[8 + i] := a.addr[i]; INC(i) END; len := 28
  ELSE
    i := 0; WHILE i < 4 DO sa[4 + i] := a.addr[i]; INC(i) END; len := 16
  END
END SockAddr;

(* address and port of a sockaddr *)
PROCEDURE FromSockAddr(VAR sa: ARRAY OF CHAR; VAR a: Address; VAR port: LONGINT);
VAR i: LONGINT; f: INTEGER;
BEGIN
  SYSTEM.GET(SYSTEM.ADR(sa[0]), f);
  port := LONG(ORD(sa[2])) * 256 + LONG(ORD(sa[3]));
  i := 0; WHILE i < 16 DO a.addr[i] := 0X; INC(i) END;
  IF f = AFINET6 THEN a.family := Inet6; i := 0; WHILE i < 16 DO a.addr[i] := sa[8 + i]; INC(i) END
  ELSE a.family := Inet4; i := 0; WHILE i < 4 DO a.addr[i] := sa[4 + i]; INC(i) END
  END
END FromSockAddr;

(* ----- sockets ----- *)

PROCEDURE New(family: INTEGER; type: LONGINT): Socket;
VAR s: Socket; fd, f: LONGINT;
BEGIN
  IF family = Inet6 THEN f := AFINET6 ELSE f := AFINET END;
  fd := Linux0.Socket0(f, type + SOCKCLOEXEC, 0);
  IF fd < 0 THEN res := fd; RETURN NIL END;
  NEW(s); s.fd := fd; s.res := 0; res := 0; RETURN s
END New;

(** a TCP connection to address a, port; NIL if it fails (res) *)
PROCEDURE Connect*(VAR a: Address; port: LONGINT): Socket;
VAR s: Socket; sa: ARRAY 28 OF CHAR; len, r: LONGINT;
BEGIN
  s := New(a.family, sockStream);
  IF s = NIL THEN RETURN NIL END;
  SockAddr(a, port, sa, len);
  r := Linux0.Connect0(s.fd, SYSTEM.ADR(sa[0]), len);
  IF r < 0 THEN res := r; r := Linux0.Close0(s.fd); RETURN NIL END;
  RETURN s
END Connect;

(** a TCP socket listening on port at the local address a (127.0.0.1, ::1, an address of an
  interface, or AnyAddress: all of them); an IPv6 socket at :: also accepts IPv4 connections
  (as ::ffff:a.b.c.d); NIL if it fails (res) *)
PROCEDURE ListenAt*(VAR a: Address; port, backlog: LONGINT): Socket;
VAR s: Socket; sa: ARRAY 28 OF CHAR; len, r, one, zero: LONGINT;
BEGIN
  s := New(a.family, sockStream);
  IF s = NIL THEN RETURN NIL END;
  one := 1; zero := 0;
  r := Linux0.SetSockOpt0(s.fd, solSocket, soReuseAddr, SYSTEM.ADR(one), 4);
  IF a.family = Inet6 THEN r := Linux0.SetSockOpt0(s.fd, IPPROTOIPV6, IPV6V6ONLY, SYSTEM.ADR(zero), 4) END;
  SockAddr(a, port, sa, len);
  r := Linux0.Bind0(s.fd, SYSTEM.ADR(sa[0]), len);
  IF r >= 0 THEN r := Linux0.Listen0(s.fd, backlog) END;
  IF r < 0 THEN res := r; r := Linux0.Close0(s.fd); RETURN NIL END;
  RETURN s
END ListenAt;

(** a TCP socket listening on port, on all local addresses of family; an IPv6 socket also
  accepts IPv4 connections (as ::ffff:a.b.c.d); NIL if it fails (res) *)
PROCEDURE Listen*(family: INTEGER; port, backlog: LONGINT): Socket;
VAR a: Address;
BEGIN
  AnyAddress(family, a);
  RETURN ListenAt(a, port, backlog)
END Listen;

(** wait for a connection to the listening socket s; peer and port of the other side; NIL
  if it fails (s.res) *)
PROCEDURE Accept*(s: Socket; VAR peer: Address; VAR port: LONGINT): Socket;
VAR c: Socket; sa: ARRAY 28 OF CHAR; len, fd: LONGINT;
BEGIN
  len := 28;
  fd := Linux0.Accept40(s.fd, SYSTEM.ADR(sa[0]), SYSTEM.ADR(len), SOCKCLOEXEC);
  IF fd < 0 THEN s.res := fd; RETURN NIL END;
  FromSockAddr(sa, peer, port);
  NEW(c); c.fd := fd; c.res := 0; RETURN c
END Accept;

(** send len bytes of buf, all of them; the number sent, negative on an error *)
PROCEDURE Send*(s: Socket; VAR buf: ARRAY OF SYSTEM.BYTE; len: LONGINT): LONGINT;
VAR done, r: LONGINT;
BEGIN
  done := 0;
  WHILE done < len DO
    r := Linux0.SendTo0(s.fd, SYSTEM.ADR(buf[done]), len - done, MSGNOSIGNAL, 0, 0);
    IF r < 0 THEN s.res := r; RETURN r END;
    done := done + r
  END;
  RETURN done
END Send;

(** send the characters of str up to 0X *)
PROCEDURE SendString*(s: Socket; str: ARRAY OF CHAR): LONGINT;
VAR n: LONGINT;
BEGIN
  n := 0; WHILE (n < LEN(str)) & (str[n] # 0X) DO INC(n) END;
  RETURN Send(s, str, n)
END SendString;

(** receive at most len bytes into buf; the number received, 0 when the other side closed,
  negative on an error *)
PROCEDURE Receive*(s: Socket; VAR buf: ARRAY OF SYSTEM.BYTE; len: LONGINT): LONGINT;
VAR r: LONGINT;
BEGIN
  IF len > LEN(buf) THEN len := LEN(buf) END;
  r := Linux0.RecvFrom0(s.fd, SYSTEM.ADR(buf[0]), len, 0, 0, 0);
  IF r < 0 THEN s.res := r END;
  RETURN r
END Receive;

(** no more sending (how = 1), receiving (0), or both (2) *)
PROCEDURE Shutdown*(s: Socket; how: LONGINT);
VAR r: LONGINT;
BEGIN r := Linux0.Shutdown0(s.fd, how)
END Shutdown;

PROCEDURE Close*(s: Socket);
VAR r: LONGINT;
BEGIN
  IF (s # NIL) & (s.fd >= 0) THEN r := Linux0.Close0(s.fd); s.fd := -1 END
END Close;

(** the address and port of the other side of s *)
PROCEDURE PeerAddress*(s: Socket; VAR a: Address; VAR port: LONGINT): BOOLEAN;
VAR sa: ARRAY 28 OF CHAR; len, r: LONGINT;
BEGIN
  len := 28; r := Linux0.GetPeerName0(s.fd, SYSTEM.ADR(sa[0]), SYSTEM.ADR(len));
  IF r < 0 THEN s.res := r; RETURN FALSE END;
  FromSockAddr(sa, a, port); RETURN TRUE
END PeerAddress;

(** the local address and port of s *)
PROCEDURE LocalAddress*(s: Socket; VAR a: Address; VAR port: LONGINT): BOOLEAN;
VAR sa: ARRAY 28 OF CHAR; len, r: LONGINT;
BEGIN
  len := 28; r := Linux0.GetSockName0(s.fd, SYSTEM.ADR(sa[0]), SYSTEM.ADR(len));
  IF r < 0 THEN s.res := r; RETURN FALSE END;
  FromSockAddr(sa, a, port); RETURN TRUE
END LocalAddress;

(** receiving and sending wait at most ms milliseconds (0: without end); then they fail
  with -11 (EAGAIN) *)
PROCEDURE SetTimeout*(s: Socket; ms: LONGINT);
VAR tv: ARRAY 2 OF LONGINT; r: LONGINT;
BEGIN
  tv[0] := ms DIV 1000; tv[1] := ms MOD 1000 * 1000;  (* struct timeval: seconds, microseconds *)
  r := Linux0.SetSockOpt0(s.fd, solSocket, soRcvTimeo, SYSTEM.ADR(tv[0]), 8);
  IF r >= 0 THEN r := Linux0.SetSockOpt0(s.fd, solSocket, soSndTimeo, SYSTEM.ADR(tv[0]), 8) END;
  IF r < 0 THEN s.res := r END
END SetTimeout;

(* ----- nonblocking TCP ----- *)

(** Negative results retain the native error number, including temporary errors.
    SendSome and ReceiveSome perform one operation and report exact progress. *)
PROCEDURE Pending*(result: LONGINT): BOOLEAN;
BEGIN RETURN Linux0.Pending0(result) END Pending;

PROCEDURE WouldBlock*(result: LONGINT): BOOLEAN;
BEGIN RETURN Linux0.WouldBlock0(result) END WouldBlock;

PROCEDURE Interrupted*(result: LONGINT): BOOLEAN;
BEGIN RETURN Linux0.Interrupted0(result) END Interrupted;

PROCEDURE NewNonblocking(family: INTEGER): Socket;
VAR s: Socket; f, fd: LONGINT;
BEGIN
  IF family = Inet6 THEN f := AFINET6
  ELSIF family = Inet4 THEN f := AFINET
  ELSE res := -22; RETURN NIL
  END;
  fd := Linux0.SocketNonblocking0(f, sockStream, 0);
  IF fd < 0 THEN res := fd; RETURN NIL END;
  NEW(s); s.fd := fd; s.res := 0; res := 0; RETURN s
END NewNonblocking;

PROCEDURE BindNonblocking(s: Socket; VAR local: Address; port: LONGINT; reuse: BOOLEAN): BOOLEAN;
VAR sa: ARRAY 28 OF CHAR; len, one, r: LONGINT;
BEGIN
  one := 1;
  IF local.family = Inet6 THEN
    r := Linux0.SetSockOpt0(s.fd, IPPROTOIPV6, IPV6V6ONLY, SYSTEM.ADR(one), 4);
    IF r < 0 THEN s.res := r; RETURN FALSE END
  END;
  IF reuse THEN
    r := Linux0.SetSockOpt0(s.fd, solSocket, soReuseAddr, SYSTEM.ADR(one), 4);
    IF r < 0 THEN s.res := r; RETURN FALSE END
  END;
  SockAddr(local, port, sa, len);
  r := Linux0.Bind0(s.fd, SYSTEM.ADR(sa[0]), len); s.res := r; RETURN r = 0
END BindNonblocking;

(** Connect from the chosen local address and port (zero: system-selected port).
    A pending connection has Pending(s.res); PollConnect checks its completion. *)
PROCEDURE ConnectFromPort*(VAR local, remote: Address; localPort, port: LONGINT): Socket;
VAR s: Socket; sa: ARRAY 28 OF CHAR; len, r: LONGINT;
BEGIN
  IF (localPort < 0) OR (localPort > 65535) OR (port < 1) OR (port > 65535) OR
     (local.family # remote.family) THEN res := -22; RETURN NIL END;
  s := NewNonblocking(local.family); IF s = NIL THEN RETURN NIL END;
  IF ~BindNonblocking(s, local, localPort, FALSE) THEN res := s.res; Close(s); RETURN NIL END;
  SockAddr(remote, port, sa, len);
  r := Linux0.Connect0(s.fd, SYSTEM.ADR(sa[0]), len); s.res := r;
  IF (r < 0) & ~Pending(r) THEN res := r; Close(s); RETURN NIL END;
  res := r; RETURN s
END ConnectFromPort;

PROCEDURE ConnectFrom*(VAR local, remote: Address; port: LONGINT): Socket;
BEGIN RETURN ConnectFromPort(local, remote, 0, port) END ConnectFrom;

(** Listen without blocking, IPv6-only for an IPv6 address. Port zero requests an
    ephemeral port; LocalEndpoint returns the port assigned by the system. *)
PROCEDURE ListenNonblocking*(VAR local: Address; port, backlog: LONGINT): Socket;
VAR s: Socket; r: LONGINT;
BEGIN
  IF (port < 0) OR (port > 65535) OR (backlog < 1) THEN res := -22; RETURN NIL END;
  s := NewNonblocking(local.family); IF s = NIL THEN RETURN NIL END;
  IF ~BindNonblocking(s, local, port, TRUE) THEN res := s.res; Close(s); RETURN NIL END;
  r := Linux0.Listen0(s.fd, backlog);
  IF r < 0 THEN res := r; Close(s); RETURN NIL END;
  RETURN s
END ListenNonblocking;

PROCEDURE DecodeEndpoint(VAR sa: ARRAY OF CHAR; len: LONGINT; VAR endpoint: Endpoint): BOOLEAN;
VAR family: INTEGER; scope: LONGINT;
BEGIN
  IF (len < 16) OR (len > LEN(sa)) THEN RETURN FALSE END;
  SYSTEM.GET(SYSTEM.ADR(sa[0]), family);
  IF (family = AFINET6) & (len = 28) THEN
    SYSTEM.GET(SYSTEM.ADR(sa[24]), scope); endpoint.scope := scope
  ELSIF (family = AFINET) & (len = 16) THEN endpoint.scope := 0
  ELSE RETURN FALSE
  END;
  FromSockAddr(sa, endpoint.address, endpoint.port); RETURN TRUE
END DecodeEndpoint;

PROCEDURE AcceptNonblocking*(listener: Socket; VAR peer: Endpoint): Socket;
VAR s: Socket; sa: ARRAY 28 OF CHAR; len, fd, r: LONGINT;
BEGIN
  IF (listener = NIL) OR (listener.fd < 0) THEN res := -9; RETURN NIL END;
  len := LEN(sa); fd := Linux0.AcceptNonblocking0(listener.fd, SYSTEM.ADR(sa[0]), SYSTEM.ADR(len));
  IF fd < 0 THEN listener.res := fd; res := fd; RETURN NIL END;
  IF ~DecodeEndpoint(sa, len, peer) THEN r := Linux0.Close0(fd); listener.res := -22; res := -22; RETURN NIL END;
  NEW(s); s.fd := fd; s.res := 0; listener.res := 0; res := 0; RETURN s
END AcceptNonblocking;

PROCEDURE ConnectError*(s: Socket): LONGINT;
BEGIN
  IF (s = NIL) OR (s.fd < 0) THEN RETURN -9 END;
  s.res := Linux0.SocketError0(s.fd); RETURN s.res
END ConnectError;

(** Check connection completion without waiting: 0 connected, 1 still pending,
    negative error. SO_ERROR is read only after writable/error readiness. *)
PROCEDURE PollConnect*(s: Socket): LONGINT;
VAR r: LONGINT;
BEGIN
  IF (s = NIL) OR (s.fd < 0) THEN RETURN -9 END;
  r := Linux0.Poll0(s.fd, TRUE, 0);
  IF (r = 0) OR Interrupted(r) THEN RETURN 1 END;
  IF r < 0 THEN s.res := r; RETURN r END;
  r := ConnectError(s);
  IF Pending(r) THEN RETURN 1 END;
  RETURN r
END PollConnect;

(** Change status flags while retaining descriptor ownership and close-on-exec. *)
PROCEDURE SetBlocking*(s: Socket; blocking: BOOLEAN): BOOLEAN;
BEGIN
  IF (s = NIL) OR (s.fd < 0) THEN RETURN FALSE END;
  s.res := Linux0.SetBlocking0(s.fd, blocking); RETURN s.res = 0
END SetBlocking;

PROCEDURE LocalEndpoint*(s: Socket; VAR endpoint: Endpoint): BOOLEAN;
VAR sa: ARRAY 28 OF CHAR; len, r: LONGINT;
BEGIN
  IF (s = NIL) OR (s.fd < 0) THEN RETURN FALSE END;
  len := LEN(sa); r := Linux0.GetSockName0(s.fd, SYSTEM.ADR(sa[0]), SYSTEM.ADR(len));
  IF r < 0 THEN s.res := r; RETURN FALSE END;
  IF ~DecodeEndpoint(sa, len, endpoint) THEN s.res := -22; RETURN FALSE END;
  s.res := 0; RETURN TRUE
END LocalEndpoint;

PROCEDURE PeerEndpoint*(s: Socket; VAR endpoint: Endpoint): BOOLEAN;
VAR sa: ARRAY 28 OF CHAR; len, r: LONGINT;
BEGIN
  IF (s = NIL) OR (s.fd < 0) THEN RETURN FALSE END;
  len := LEN(sa); r := Linux0.GetPeerName0(s.fd, SYSTEM.ADR(sa[0]), SYSTEM.ADR(len));
  IF r < 0 THEN s.res := r; RETURN FALSE END;
  IF ~DecodeEndpoint(sa, len, endpoint) THEN s.res := -22; RETURN FALSE END;
  s.res := 0; RETURN TRUE
END PeerEndpoint;

(** Checked byte spans on a borrowed descriptor; ownership stays with the caller. *)
PROCEDURE WriteDescriptor*(fd: LONGINT; VAR bytes: ARRAY OF CHAR; offset, length: LONGINT): LONGINT;
BEGIN
  IF fd < 0 THEN RETURN -9 END;
  IF (offset < 0) OR (length < 0) OR (offset > LEN(bytes)) OR (length > LEN(bytes)-offset) THEN RETURN -22 END;
  IF length = 0 THEN RETURN 0 END;
  RETURN Linux0.SendTo0(fd, SYSTEM.ADR(bytes[offset]), length, MSGNOSIGNAL, 0, 0)
END WriteDescriptor;

PROCEDURE ReadDescriptor*(fd: LONGINT; VAR bytes: ARRAY OF CHAR; offset, length: LONGINT): LONGINT;
BEGIN
  IF fd < 0 THEN RETURN -9 END;
  IF (offset < 0) OR (length < 0) OR (offset > LEN(bytes)) OR (length > LEN(bytes)-offset) THEN RETURN -22 END;
  IF length = 0 THEN RETURN 0 END;
  RETURN Linux0.RecvFrom0(fd, SYSTEM.ADR(bytes[offset]), length, 0, 0, 0)
END ReadDescriptor;

PROCEDURE SendSome*(s: Socket; VAR bytes: ARRAY OF CHAR; offset, length: LONGINT): LONGINT;
VAR n: LONGINT;
BEGIN
  IF s = NIL THEN RETURN -9 END;
  n := WriteDescriptor(s.fd, bytes, offset, length); s.res := 0; IF n < 0 THEN s.res := n END;
  RETURN n
END SendSome;

PROCEDURE ReceiveSome*(s: Socket; VAR bytes: ARRAY OF CHAR; offset, length: LONGINT): LONGINT;
VAR n: LONGINT;
BEGIN
  IF s = NIL THEN RETURN -9 END;
  n := ReadDescriptor(s.fd, bytes, offset, length); s.res := 0; IF n < 0 THEN s.res := n END;
  RETURN n
END ReceiveSome;

PROCEDURE AbortDescriptor*(fd: LONGINT): BOOLEAN;
BEGIN
  IF fd < 0 THEN res := -9; RETURN FALSE END;
  res := Linux0.Abortive0(fd); RETURN res = 0
END AbortDescriptor;

(** Transfer descriptor ownership without closing it. The socket becomes closed. *)
PROCEDURE Release*(s: Socket): LONGINT;
VAR fd: LONGINT;
BEGIN
  IF s = NIL THEN RETURN -1 END;
  fd := s.fd; s.fd := -1; RETURN fd
END Release;

(* ----- UDP ----- *)

(** a UDP socket of family; port 0: any local port; NIL if it fails (res) *)
PROCEDURE OpenUDP*(family: INTEGER; port: LONGINT): Socket;
VAR s: Socket; a: Address; sa: ARRAY 28 OF CHAR; len, r: LONGINT;
BEGIN
  s := New(family, sockDgram);
  IF s = NIL THEN RETURN NIL END;
  IF port # 0 THEN
    AnyAddress(family, a); SockAddr(a, port, sa, len);
    r := Linux0.Bind0(s.fd, SYSTEM.ADR(sa[0]), len);
    IF r < 0 THEN res := r; r := Linux0.Close0(s.fd); RETURN NIL END
  END;
  RETURN s
END OpenUDP;

(** send a datagram of len bytes to address a, port *)
PROCEDURE SendTo*(s: Socket; VAR a: Address; port: LONGINT; VAR buf: ARRAY OF SYSTEM.BYTE; len: LONGINT): LONGINT;
VAR sa: ARRAY 28 OF CHAR; salen, r: LONGINT;
BEGIN
  SockAddr(a, port, sa, salen);
  r := Linux0.SendTo0(s.fd, SYSTEM.ADR(buf[0]), len, MSGNOSIGNAL, SYSTEM.ADR(sa[0]), salen);
  IF r < 0 THEN s.res := r END;
  RETURN r
END SendTo;

(** receive a datagram into buf (at most len bytes), from address a, port *)
PROCEDURE ReceiveFrom*(s: Socket; VAR buf: ARRAY OF SYSTEM.BYTE; len: LONGINT; VAR a: Address; VAR port: LONGINT): LONGINT;
VAR sa: ARRAY 28 OF CHAR; salen, r: LONGINT;
BEGIN
  IF len > LEN(buf) THEN len := LEN(buf) END;
  salen := 28;
  r := Linux0.RecvFrom0(s.fd, SYSTEM.ADR(buf[0]), len, 0, SYSTEM.ADR(sa[0]), SYSTEM.ADR(salen));
  IF r < 0 THEN s.res := r ELSE FromSockAddr(sa, a, port) END;
  RETURN r
END ReceiveFrom;

BEGIN
  res := 0;
  IF (Linux0.ARCH = "MIPS") OR (Linux0.ARCH = "MIPSBE") THEN
    sockStream := 2; sockDgram := 1; solSocket := 0FFFFH; soReuseAddr := 4; soRcvTimeo := 1006H; soSndTimeo := 1005H
  ELSIF Linux0.ARCH = "PPC" THEN  (* polpo: PowerPC has SO_RCVTIMEO 18, SO_SNDTIMEO 19 *)
    sockStream := 1; sockDgram := 2; solSocket := 1; soReuseAddr := 2; soRcvTimeo := 18; soSndTimeo := 19
  ELSE sockStream := 1; sockDgram := 2; solSocket := 1; soReuseAddr := 2; soRcvTimeo := 20; soSndTimeo := 21
  END
END Sockets.
