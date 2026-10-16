MODULE NetSystem;  (** the NetSystem of ETH Native Oberon, over Sockets and DNS *)

(* The portable network interface of ETH Oberon System 3 (NetSystem, mg 16.08.96) with the same
   names, types and results, for programs written for it. Native Oberon had its own TCP/IP stack
   under it (NetBase, NetIP, NetTCP, NetUDP, NetDNS); here it is the Linux socket calls, through
   Sockets, DNS and Linux0 (in voc Linux0 := unixNet).

   IPAdr is an IPv4 address in network byte order, as in Native Oberon: the four bytes in memory
   order. Ports are INTEGER: ports above 32767 are negative numbers, as they were.

   Differences from Native Oberon (also in README.md of github.com/norayr/Internet):
   - Names are looked up by DNS (/etc/hosts, then the name servers of /etc/resolv.conf); the
     NetSystem.Hosts section of Oberon.Text is not read.
   - GetName asks DNS.Reverse: /etc/hosts, then the PTR record; "" if there is none, as in
     Native Oberon.
   - The local port of an active connection is chosen by the system (locPort is not used).
   - CloseConnection closes the connection in both directions, at once: read what you want
     first. In Native Oberon the connection could still receive after it (state in).
   - Passwords are kept in memory as in Native Oberon, but SetUser, which read them from the
     command text and the keyboard, does nothing here. SetPassword sets one instead; it is not
     in Native Oberon, it is added here.
   - Start and Stop only set started; Show prints to the terminal (Out), not to the Log.
   - Only IPv4: IPAdr has 32 bits, as in Native Oberon. *)

IMPORT Sockets, DNS, Linux0 := unixNet, Out, SYSTEM;

CONST
  anyport* = 0;  (** any port value *)

  (** result values *)
  done* = 0;  (** everything went ok *)
  error* = 1;  (** failure occured *)

  (** return values of procedure State *)
  closed* = 0;  (** connection is closed (neither sending nor receiving) *)
  listening* = 1;  (** passive connection is listening for a request *)
  in* = 2;  (** receiving only *)
  out* = 3;  (** sending only *)
  inout* = 4;  (** sending and receiving is possible *)
  waitCon* = 5;  (** still waiting to be connected *)
  errorCon* = 6;  (** connecting failed *)

  CR = 0DX; LF = 0AX;
  BufLen = 4096;
  MSGNOSIGNAL = 4000H; MSGPEEK = 2; MSGTRUNC = 20H;
  SHUTWR = 1;
  Backlog = 8;

TYPE
  IPAdr* = LONGINT;  (** IP address in network byte order *)

  Connection* = POINTER TO ConnectionDesc;  (** handle for TCP connections *)
  ConnectionDesc* = RECORD
    res*: INTEGER;  (** result of last operation on a connection (error indication) *)
    state: INTEGER;
    s: Sockets.Socket;
    rip: IPAdr; rport: INTEGER;
    buf: ARRAY BufLen OF CHAR;  (* received, not yet read: buf[bpos..blen) *)
    bpos, blen: LONGINT
  END;

  Socket* = POINTER TO SocketDesc;  (** handle for UDP "connections" *)
  SocketDesc* = RECORD
    res*: INTEGER;  (** result of last operation on a connection (error indication) *)
    state: INTEGER;
    s: Sockets.Socket
  END;

  Password = POINTER TO PasswordDesc;
  PasswordDesc = RECORD
    service, user, host, passwd: ARRAY 64 OF CHAR;
    next: Password
  END;

VAR
  anyIP*: IPAdr;  (** "NIL" ip-number *)
  allIP*: IPAdr;  (** broadcast ip-number *)
  hostIP*: IPAdr;  (** main ip-number of local machine *)
  hostName*: ARRAY 64 OF CHAR;  (** main name of local machine *)
  started: BOOLEAN;
  passwords: Password;

(* ----- helpers ----- *)

(* a port as a number 0..65535, and back *)
PROCEDURE PortNum(p: INTEGER): LONGINT;
BEGIN RETURN LONG(p) MOD 10000H
END PortNum;

PROCEDURE PortInt(p: LONGINT): INTEGER;
BEGIN
  IF p >= 8000H THEN p := p - 10000H END;
  RETURN SHORT(p)
END PortInt;

PROCEDURE ToAddress(ip: IPAdr; VAR a: Sockets.Address);
VAR i: LONGINT;
BEGIN
  a.family := Sockets.Inet4; i := 0; WHILE i < 16 DO a.addr[i] := 0X; INC(i) END;
  SYSTEM.MOVE(SYSTEM.ADR(ip), SYSTEM.ADR(a.addr[0]), 4)
END ToAddress;

(* the IPv4 address of a (also of an IPv4 address mapped into IPv6), anyIP if there is none *)
PROCEDURE FromAddress(VAR a: Sockets.Address): IPAdr;
VAR ip: IPAdr;
BEGIN
  ip := anyIP;
  IF a.family = Sockets.Inet4 THEN SYSTEM.MOVE(SYSTEM.ADR(a.addr[0]), SYSTEM.ADR(ip), 4)
  ELSIF Sockets.Mapped(a) THEN SYSTEM.MOVE(SYSTEM.ADR(a.addr[12]), SYSTEM.ADR(ip), 4)
  END;
  RETURN ip
END FromAddress;

(* can fd be read without blocking (data, a request or the end), waiting at most ms milliseconds? *)
PROCEDURE Ready(fd: LONGINT; ms: LONGINT): BOOLEAN;
VAR set: ARRAY 128 OF CHAR; tv: ARRAY 2 OF LONGINT; i, r: LONGINT;
BEGIN
  IF (fd < 0) OR (fd >= 1024) THEN RETURN FALSE END;
  i := 0; WHILE i < LEN(set) DO set[i] := 0X; INC(i) END;
  set[fd DIV 8] := CHR(ASH(1, fd MOD 8));
  tv[0] := ms DIV 1000; tv[1] := ms MOD 1000 * 1000;
  r := Linux0.Select0(fd + 1, SYSTEM.ADR(set[0]), 0, 0, SYSTEM.ADR(tv[0]));
  RETURN r > 0
END Ready;

(* the peer has closed its side: receiving ends *)
PROCEDURE PeerClosed(C: Connection);
BEGIN
  IF C.state = inout THEN C.state := out ELSIF C.state = in THEN C.state := closed END
END PeerClosed;

(* sending failed: sending ends *)
PROCEDURE SendFailed(C: Connection);
BEGIN
  IF C.state = inout THEN C.state := in ELSIF C.state = out THEN C.state := closed END
END SendFailed;

(* receive what is there into C.buf (when it is empty); block: wait for it *)
PROCEDURE Fill(C: Connection; block: BOOLEAN);
VAR n: LONGINT;
BEGIN
  IF (C.bpos = C.blen) & ((C.state = inout) OR (C.state = in)) & (C.s # NIL) THEN
    IF block OR Ready(C.s.fd, 0) THEN
      n := Linux0.RecvFrom0(C.s.fd, SYSTEM.ADR(C.buf[0]), BufLen, 0, 0, 0);
      IF n > 0 THEN C.bpos := 0; C.blen := n ELSE PeerClosed(C) END
    END
  END
END Fill;

(* blocking: len bytes into buf[beg..beg+len) *)
PROCEDURE Receive(C: Connection; VAR buf: ARRAY OF SYSTEM.BYTE; beg, len: LONGINT);
VAR n: LONGINT;
BEGIN
  IF (beg < 0) OR (len < 0) OR (beg + len > LEN(buf)) THEN C.res := error; RETURN END;
  C.res := done;
  WHILE (len > 0) & (C.res = done) DO
    Fill(C, TRUE);
    n := C.blen - C.bpos;
    IF n = 0 THEN C.res := error
    ELSE
      IF n > len THEN n := len END;
      SYSTEM.MOVE(SYSTEM.ADR(C.buf[C.bpos]), SYSTEM.ADR(buf[beg]), n);
      INC(C.bpos, n); INC(beg, n); DEC(len, n)
    END
  END
END Receive;

(* blocking: buf[beg..beg+len) sent *)
PROCEDURE Send(C: Connection; VAR buf: ARRAY OF SYSTEM.BYTE; beg, len: LONGINT);
VAR n: LONGINT;
BEGIN
  IF (beg < 0) OR (len < 0) OR (beg + len > LEN(buf)) OR (C.s = NIL)
    OR ~((C.state = inout) OR (C.state = out)) THEN C.res := error; RETURN
  END;
  C.res := done;
  WHILE (len > 0) & (C.res = done) DO
    n := Linux0.SendTo0(C.s.fd, SYSTEM.ADR(buf[beg]), len, MSGNOSIGNAL, 0, 0);
    IF n > 0 THEN INC(beg, n); DEC(len, n) ELSE C.res := error; SendFailed(C) END
  END
END Send;

PROCEDURE NewConnection(s: Sockets.Socket; state: INTEGER): Connection;
VAR C: Connection;
BEGIN
  NEW(C); C.s := s; C.state := state; C.res := done; C.rip := anyIP; C.rport := 0; C.bpos := 0; C.blen := 0;
  RETURN C
END NewConnection;

PROCEDURE Lower(VAR s: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO
    IF (s[i] >= "A") & (s[i] <= "Z") THEN s[i] := CHR(ORD(s[i]) + 32) END;
    INC(i)
  END
END Lower;

(** -- Adressing/Naming section. *)

(** Convert a dotted IP address string (e.g. "1.2.3.4") to an IPAdr value. *)
PROCEDURE ToHost*(num: ARRAY OF CHAR; VAR adr: IPAdr; VAR done: BOOLEAN);
VAR a: Sockets.Address;
BEGIN
  done := Sockets.ParseAddress(num, a) & (a.family = Sockets.Inet4);
  IF done THEN adr := FromAddress(a) ELSE adr := anyIP END
END ToHost;

(** Convert an IPAdr value to a dotted IP address string *)
PROCEDURE ToNum*(adr: IPAdr; VAR num: ARRAY OF CHAR);
VAR a: Sockets.Address;
BEGIN
  ToAddress(adr, a); Sockets.AddressToString(a, num)
END ToNum;

(** Procedure delivers the ip-number of a named host. If a symbolic name is given, it will be resolved by use of domain name
  servers. *)
PROCEDURE GetIP*(name: ARRAY OF CHAR; VAR IP: IPAdr);
VAR a: Sockets.Address; ok: BOOLEAN;
BEGIN
  ToHost(name, IP, ok);
  IF ~ok THEN
    IF DNS.Resolve(name, Sockets.Inet4, a) THEN IP := FromAddress(a) ELSE IP := anyIP END
  END
END GetIP;

(** GetName is the reverse of GetIP. Given an ip-number, it delivers the name of a host ("" if it has none). *)
PROCEDURE GetName*(IP: IPAdr; VAR name: ARRAY OF CHAR);
VAR a: Sockets.Address;
BEGIN
  ToAddress(IP, a);
  IF ~DNS.Reverse(a, name) THEN COPY("", name) END
END GetName;

(** -- TCP section. *)

(** Procedure opens a connection. locPort, remPort, remIP are contained in the quadrupel <locIP, remIP, locPort, remPort>
  which determines a connection uniquely. As locIP is always the current machine, it is omitted. If remPort is equal to
  anyport or remIP is equal to anyIP, a passive connection will be opened. After execution, C is a brand new connection.
  res indicates any error. *)
PROCEDURE OpenConnection*(VAR C: Connection; locPort: INTEGER; remIP: IPAdr; remPort: INTEGER; VAR res: INTEGER);
VAR s: Sockets.Socket; a: Sockets.Address;
BEGIN
  C := NewConnection(NIL, errorCon); res := error;
  IF (remIP = anyIP) OR (remPort = anyport) THEN
    s := Sockets.Listen(Sockets.Inet4, PortNum(locPort), Backlog);
    IF s # NIL THEN C.s := s; C.state := listening; res := done END
  ELSIF remIP # allIP THEN
    ToAddress(remIP, a);
    s := Sockets.Connect(a, PortNum(remPort));
    IF s # NIL THEN C.s := s; C.state := inout; C.rip := remIP; C.rport := remPort; res := done END
  END;
  C.res := res
END OpenConnection;

(** Like OpenConnection, but this procedure may return immediately and delay the actual opening of the connection.
  In this case State() should be checked to wait for the connection status to change from waitCon. *)
PROCEDURE AsyncOpenConnection*(VAR C: Connection; locPort: INTEGER; remIP: IPAdr; remPort: INTEGER; VAR res: INTEGER);
BEGIN
  OpenConnection(C, locPort, remIP, remPort, res)  (* synchronously, as in Native Oberon *)
END AsyncOpenConnection;

(** Procedure closes the connection. Connection can not be used for send operations afterwards.
  Here not for receiving either: unlike Native Oberon, both directions are closed at once. *)
PROCEDURE CloseConnection*(C: Connection);
BEGIN
  IF C # NIL THEN
    IF C.s # NIL THEN
      IF C.state # listening THEN Sockets.Shutdown(C.s, SHUTWR) END;
      Sockets.Close(C.s); C.s := NIL
    END;
    C.state := closed; C.bpos := 0; C.blen := 0; C.res := done
  END
END CloseConnection;

(** Indicates whether there exists a remote machine which wants to connect to the local one. This Procedure is only useful
  on passive connections. For active connections (State(C) # listen), it always delivers FALSE. *)
PROCEDURE Requested*(C: Connection): BOOLEAN;
BEGIN RETURN (C.state = listening) & (C.s # NIL) & Ready(C.s.fd, 0)
END Requested;

(** Procedure accepts a new waiting, active connection (newC) on a passive one (State(C) = listen). If no connection is
  waiting, accept blocks until there is one or an error occurs. If C is not a passive connection, Accept does nothing
  but res is set to Done. *)
PROCEDURE Accept*(C: Connection; VAR newC: Connection; VAR res: INTEGER);
VAR s: Sockets.Socket; a: Sockets.Address; port: LONGINT;
BEGIN
  res := done;
  IF (C.state = listening) & (C.s # NIL) THEN
    s := Sockets.Accept(C.s, a, port);
    IF s # NIL THEN
      newC := NewConnection(s, inout); newC.rip := FromAddress(a); newC.rport := PortInt(port)
    ELSE res := error
    END
  END;
  C.res := res
END Accept;

(** Procedure returns the state of a connection (see constant section). *)
PROCEDURE State*(C: Connection): INTEGER;
BEGIN
  Fill(C, FALSE);  (* notices that the peer has closed *)
  RETURN C.state
END State;

(** Returns the number of bytes which may be read without blocking. *)
PROCEDURE Available*(C: Connection): LONGINT;
BEGIN
  IF C.state = listening THEN C.res := error; RETURN 0 END;
  Fill(C, FALSE); C.res := done;
  RETURN C.blen - C.bpos
END Available;

(** Blocking read a single byte. *)
PROCEDURE Read*(C: Connection; VAR ch: CHAR);
VAR b: ARRAY 1 OF CHAR;
BEGIN
  Receive(C, b, 0, 1);
  IF C.res = done THEN ch := b[0] ELSE ch := 0X END
END Read;

(** Blocking read len bytes of data (beginning at pos in buf) to buf. *)
PROCEDURE ReadBytes*(C: Connection; pos, len: LONGINT; VAR buf: ARRAY OF SYSTEM.BYTE);
BEGIN Receive(C, buf, pos, len)
END ReadBytes;

(** Blocking read two bytes in network byte ordering. *)
PROCEDURE ReadInt*(C: Connection; VAR x: INTEGER);
VAR b: ARRAY 2 OF CHAR; v: LONGINT;
BEGIN
  Receive(C, b, 0, 2);
  IF C.res = done THEN v := LONG(ORD(b[0])) * 256 + ORD(b[1]); x := PortInt(v) ELSE x := 0 END
END ReadInt;

(** Blocking read four bytes in network byte ordering. *)
PROCEDURE ReadLInt*(C: Connection; VAR x: LONGINT);
VAR b: ARRAY 4 OF CHAR; v: LONGINT;
BEGIN
  Receive(C, b, 0, 4);
  IF C.res = done THEN
    v := ORD(b[0]); IF v >= 128 THEN v := v - 256 END;
    x := ((v * 256 + ORD(b[1])) * 256 + ORD(b[2])) * 256 + ORD(b[3])
  ELSE x := 0
  END
END ReadLInt;

(** Blocking read a string terminated by ( [CR]LF | 0X ). *)
PROCEDURE ReadString*(C: Connection; VAR s: ARRAY OF CHAR);
VAR ch, ch0: CHAR; i: LONGINT;
BEGIN
  i := 0; ch := 0X;
  LOOP
    ch0 := ch; Read(C, ch);
    IF (C.res # done) OR (ch = 0X) OR (ch = LF) THEN EXIT END;
    IF i < LEN(s) - 1 THEN s[i] := ch; INC(i) END
  END;
  IF (ch = LF) & (ch0 = CR) & (i > 0) THEN DEC(i) END;
  s[i] := 0X
END ReadString;

(** Blocking write a single byte to C. *)
PROCEDURE Write*(C: Connection; ch: CHAR);
VAR b: ARRAY 1 OF CHAR;
BEGIN b[0] := ch; Send(C, b, 0, 1)
END Write;

(** Blocking write len bytes of data (beginning at pos in buf) to C. *)
PROCEDURE WriteBytes*(C: Connection; pos, len: LONGINT; VAR buf: ARRAY OF SYSTEM.BYTE);
BEGIN Send(C, buf, pos, len)
END WriteBytes;

(** Blocking write two bytes in network byte ordering to C. *)
PROCEDURE WriteInt*(C: Connection; x: INTEGER);
VAR b: ARRAY 2 OF CHAR; v: LONGINT;
BEGIN
  v := LONG(x) MOD 10000H; b[0] := CHR(v DIV 256); b[1] := CHR(v MOD 256); Send(C, b, 0, 2)
END WriteInt;

(** Blocking write four bytes in network byte ordering to C. *)
PROCEDURE WriteLInt*(C: Connection; x: LONGINT);
VAR b: ARRAY 4 OF CHAR;
BEGIN
  b[3] := CHR(x MOD 256); x := x DIV 256; b[2] := CHR(x MOD 256); x := x DIV 256;
  b[1] := CHR(x MOD 256); x := x DIV 256; b[0] := CHR(x MOD 256);
  Send(C, b, 0, 4)
END WriteLInt;

(** Blocking write a string without "0X" and terminated by "CRLF" to C. *)
PROCEDURE WriteString*(C: Connection; s: ARRAY OF CHAR);
VAR cs: ARRAY 2 OF CHAR; i: LONGINT;
BEGIN
  i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO INC(i) END;
  Send(C, s, 0, i);
  IF C.res = done THEN cs[0] := CR; cs[1] := LF; Send(C, cs, 0, 2) END
END WriteString;

(** Procedure delivers the ip-number and port number of a connection's remote partner. *)
PROCEDURE GetPartner*(C: Connection; VAR remIP: IPAdr; VAR remPort: INTEGER);
BEGIN remIP := C.rip; remPort := C.rport
END GetPartner;

(** -- UDP section. *)

(** Opens a socket which is dedicated to datagram services. locPort is registered to receive datagrams
  from any port and any host. *)
PROCEDURE OpenSocket*(VAR S: Socket; locPort: INTEGER; VAR res: INTEGER);
BEGIN
  NEW(S); S.s := Sockets.OpenUDP(Sockets.Inet4, PortNum(locPort));
  IF S.s # NIL THEN S.state := inout; S.res := done ELSE S.state := closed; S.res := error END;
  res := S.res
END OpenSocket;

(** Closes the socket. You can not receive datagrams anymore. *)
PROCEDURE CloseSocket*(S: Socket);
BEGIN
  IF S.s # NIL THEN Sockets.Close(S.s); S.s := NIL END;
  S.state := closed; S.res := done
END CloseSocket;

(** Sends len bytes of data (beginning at pos in buf) to the host specified by remIP and remPort. *)
PROCEDURE SendDG*(S: Socket; remIP: IPAdr; remPort: INTEGER; pos, len: LONGINT; VAR buf: ARRAY OF SYSTEM.BYTE);
VAR a: Sockets.Address; tmp: POINTER TO ARRAY OF CHAR; n: LONGINT;
BEGIN
  S.res := error;
  IF (S.s # NIL) & (pos >= 0) & (len >= 0) & (pos + len <= LEN(buf)) THEN
    ToAddress(remIP, a);
    NEW(tmp, len + 1); SYSTEM.MOVE(SYSTEM.ADR(buf[pos]), SYSTEM.ADR(tmp[0]), len);
    n := Sockets.SendTo(S.s, a, PortNum(remPort), tmp^, len);
    IF n = len THEN S.res := done END
  END
END SendDG;

(** Stores an entire datagram in buf beginning at pos. On success (S.res = done), remIP and remPort indicate the sender,
  len indicate the length of valid data. Without a datagram waiting, len = -1. *)
PROCEDURE ReceiveDG*(S: Socket; VAR remIP: IPAdr; VAR remPort: INTEGER; pos: LONGINT; VAR len: LONGINT;
  VAR buf: ARRAY OF SYSTEM.BYTE);
VAR a: Sockets.Address; tmp: POINTER TO ARRAY OF CHAR; port: LONGINT;
BEGIN
  len := -1; S.res := error;
  IF (S.s # NIL) & (pos >= 0) & (pos < LEN(buf)) & Ready(S.s.fd, 0) THEN
    NEW(tmp, LEN(buf) - pos);
    len := Sockets.ReceiveFrom(S.s, tmp^, LEN(buf) - pos, a, port);
    IF len >= 0 THEN
      SYSTEM.MOVE(SYSTEM.ADR(tmp[0]), SYSTEM.ADR(buf[pos]), len);
      remIP := FromAddress(a); remPort := PortInt(port); S.res := done
    ELSE len := -1
    END
  END
END ReceiveDG;

(** Returns the size of the first available datagram on the socket. *)
PROCEDURE AvailableDG*(S: Socket): LONGINT;
VAR b: ARRAY 1 OF CHAR; n: LONGINT;
BEGIN
  n := 0;
  IF (S.s # NIL) & Ready(S.s.fd, 0) THEN
    n := Linux0.RecvFrom0(S.s.fd, SYSTEM.ADR(b[0]), 1, MSGPEEK + MSGTRUNC, 0, 0);
    IF n < 0 THEN n := 0 END
  END;
  RETURN n
END AvailableDG;

(* Conversions *)

(** Write 2 bytes in network byte ordering to buf[pos]. *)
PROCEDURE PutInt*(VAR buf: ARRAY OF SYSTEM.BYTE; pos: INTEGER; x: INTEGER);
VAR v: LONGINT;
BEGIN
  v := LONG(x) MOD 10000H;
  buf[pos] := SYSTEM.VAL(SYSTEM.BYTE, CHR(v DIV 256)); buf[pos+1] := SYSTEM.VAL(SYSTEM.BYTE, CHR(v MOD 256))
END PutInt;

(** Write 4 bytes in network byte ordering to buf[pos]. *)
PROCEDURE PutLInt*(VAR buf: ARRAY OF SYSTEM.BYTE; pos: INTEGER; x: LONGINT);
VAR i: INTEGER;
BEGIN
  i := 3;
  WHILE i >= 0 DO buf[pos+i] := SYSTEM.VAL(SYSTEM.BYTE, CHR(x MOD 256)); x := x DIV 256; DEC(i) END
END PutLInt;

(** Read 2 bytes in network byte ordering from buf[pos]. *)
PROCEDURE GetInt*(VAR buf: ARRAY OF SYSTEM.BYTE; pos: INTEGER; VAR x: INTEGER);
BEGIN
  x := PortInt(LONG(ORD(SYSTEM.VAL(CHAR, buf[pos]))) * 256 + ORD(SYSTEM.VAL(CHAR, buf[pos+1])))
END GetInt;

(** Read 4 bytes in network byte ordering from buf[pos]. *)
PROCEDURE GetLInt*(VAR buf: ARRAY OF SYSTEM.BYTE; pos: INTEGER; VAR x: LONGINT);
VAR v: LONGINT; i: INTEGER;
BEGIN
  v := ORD(SYSTEM.VAL(CHAR, buf[pos])); IF v >= 128 THEN v := v - 256 END;
  i := 1; WHILE i < 4 DO v := v * 256 + ORD(SYSTEM.VAL(CHAR, buf[pos+i])); INC(i) END;
  x := v
END GetLInt;

(** -- Passwords section. *)

(** Retrieve the password for user using service on host.  Parameters service, host and user must be specified.
Parameter user is in/out.  If empty, it returns the first (user,password) pair found, otherwise it returns the
specified user's password. *)
PROCEDURE GetPassword*(service, host: ARRAY OF CHAR; VAR user, password: ARRAY OF CHAR);
VAR pass: Password;
BEGIN
  Lower(service); Lower(host);
  pass := passwords;
  WHILE (pass # NIL) & ~((pass.service = service) & (pass.host = host) & ((user = "") OR (pass.user = user))) DO
    pass := pass.next
  END;
  IF pass # NIL THEN COPY(pass.user, user); COPY(pass.passwd, password)
  ELSE COPY("", user); COPY("", password)
  END
END GetPassword;

(** Remove password for user using service on host. *)
PROCEDURE DelPassword*(service, user, host: ARRAY OF CHAR);
VAR ppass, pass: Password;
BEGIN
  Lower(service); Lower(host);
  ppass := NIL; pass := passwords;
  WHILE (pass # NIL) & ~((pass.service = service) & (pass.host = host) & (pass.user = user)) DO
    ppass := pass; pass := pass.next
  END;
  IF pass # NIL THEN
    IF ppass # NIL THEN ppass.next := pass.next ELSE passwords := pass.next END
  END
END DelPassword;

(** Set the password of user for service on host (replaces the one there was). Added here, not in Native
  Oberon, where the command SetUser read it from the command text and the keyboard. *)
PROCEDURE SetPassword*(service, user, host, password: ARRAY OF CHAR);
VAR p: Password;
BEGIN
  DelPassword(service, user, host);
  NEW(p); COPY(service, p.service); COPY(user, p.user); COPY(host, p.host); COPY(password, p.passwd);
  Lower(p.service); Lower(p.host);
  p.next := passwords; passwords := p
END SetPassword;

(** Command NetSystem.SetUser in Native Oberon (service:user[:password]@host ~, then the password); here
  it does nothing: use SetPassword. *)
PROCEDURE SetUser*;
END SetUser;

(** Command NetSystem.ClearUser ~  Clear all passwords from memory. *)
PROCEDURE ClearUser*;
BEGIN passwords := NIL
END ClearUser;

(** -- Initialisation section. *)

(* hostName from the kernel, hostIP: the address the system would send from (no packet is sent) *)
PROCEDURE FindHost;
VAR fd, n, r: LONGINT; path: ARRAY 32 OF CHAR; s: Sockets.Socket; sa: ARRAY 16 OF CHAR; a: Sockets.Address; port: LONGINT;
BEGIN
  path := "/proc/sys/kernel/hostname"; hostName := "";
  fd := Linux0.Openat0(Linux0.ATFDCWD, SYSTEM.ADR(path[0]), Linux0.ORDonly, 0);
  IF fd >= 0 THEN
    n := Linux0.Read0(fd, SYSTEM.ADR(hostName[0]), LEN(hostName) - 1); r := Linux0.Close0(fd);
    IF n < 0 THEN n := 0 END;
    WHILE (n > 0) & (hostName[n-1] <= " ") DO DEC(n) END;
    hostName[n] := 0X
  END;
  hostIP := anyIP;
  s := Sockets.OpenUDP(Sockets.Inet4, 0);
  IF s # NIL THEN
    n := 0; WHILE n < 16 DO sa[n] := 0X; INC(n) END;
    sa[0] := 2X; sa[2] := 0X; sa[3] := CHR(53); sa[4] := CHR(192); sa[5] := 0X; sa[6] := 2X; sa[7] := CHR(1);  (* 192.0.2.1:53 *)
    IF (Linux0.Connect0(s.fd, SYSTEM.ADR(sa[0]), 16) >= 0) & Sockets.LocalAddress(s, a, port) THEN hostIP := FromAddress(a) END;
    Sockets.Close(s)
  END
END FindHost;

(** Command NetSystem.Start ~  Start up NetSystem. *)
PROCEDURE Start*;
BEGIN
  IF ~started THEN FindHost; started := TRUE END
END Start;

(** Command NetSystem.Stop ~  Shut down NetSystem. *)
PROCEDURE Stop*;
BEGIN started := FALSE
END Stop;

(** Command NetSystem.Show ~  Display status. *)
PROCEDURE Show*;
VAR s: ARRAY 64 OF CHAR; p: Password;
BEGIN
  Out.String("NetSystem.Show"); Out.Ln;
  IF started THEN
    Out.String("  Host: "); ToNum(hostIP, s); Out.String(s); Out.String(" / "); Out.String(hostName); Out.Ln;
    p := passwords;
    WHILE p # NIL DO
      Out.String("  "); Out.String(p.service); Out.Char(":"); Out.String(p.user); Out.Char("@"); Out.String(p.host); Out.Ln;
      p := p.next
    END
  ELSE Out.String("  stopped"); Out.Ln
  END
END Show;

BEGIN
  anyIP := 0; allIP := -1;
  hostName := ""; hostIP := anyIP; passwords := NIL; started := FALSE;
  Start
END NetSystem.
