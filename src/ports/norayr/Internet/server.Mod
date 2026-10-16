MODULE server;  (** a forking TCP server: each connection is handled in a child process *)

(* Create, set the port, the address to listen on (setListenOn: IPv4 or IPv6, default 127.0.0.1),
   the handler, then start and serve. serve accepts connections without end; for each one it forks,
   and the child calls the handler with newsockfd (the connection: Internet.Read, ReadBuf, Write),
   clientIP and pid set, and returns from serve. Over Sockets (it used netSockets before). *)

IMPORT Sockets, netForker, Out, Platform, SYSTEM;

CONST
  defaultPort = 2055;
  defaultMaxQ = 64;
  msgNotInitialized = "server was not created, nil pointer received";
  msgHandlerNotSet  = "response handler is not set";

TYPE
  server* = POINTER TO serverDesc;
  handler* = PROCEDURE (VAR s: server);
  serverDesc = RECORD
    Port: INTEGER;
    ListenOnStr: ARRAY 64 OF CHAR;  (* the address to listen on *)
    MaxQueue: INTEGER;
    listener: Sockets.Socket;
    conn: Sockets.Socket;
    newsockfd*: LONGINT;  (** the connection, in the handler *)
    clientIP-: ARRAY 46 OF CHAR;  (** the address of the client, in the handler *)
    pid-: LONGINT;  (** the process of the handler *)
    timeoutval-: LONGREAL;
    handle: handler
  END;

PROCEDURE -inclSgnl() "#include <signal.h>";
PROCEDURE -inclFcntl() "#include <fcntl.h>";
PROCEDURE -inclUnistd() "#include <unistd.h>";  (* fork, for netForker.fork *)
PROCEDURE -ignoreChildExit() "signal(SIGCHLD, SIG_IGN)";  (* else an ended child stays a zombie *)
PROCEDURE -nonBlocking(fd: LONGINT): LONGINT "(LONGINT)fcntl(fd, F_SETFL, fcntl(fd, F_GETFL, 0) | O_NONBLOCK)";

PROCEDURE Create*(): server;
VAR s: server;
BEGIN
  NEW(s);
  s^.Port := defaultPort;
  s^.MaxQueue := defaultMaxQ;
  s^.handle := NIL;
  s^.timeoutval := 60.0;
  s^.ListenOnStr := "127.0.0.1";
  s^.listener := NIL; s^.conn := NIL; s^.newsockfd := -1;
  RETURN s
END Create;

(** the local address to listen on: 127.0.0.1, ::1, 0.0.0.0 (all IPv4), :: (all, IPv6 and IPv4) ... *)
PROCEDURE setListenOn*(VAR s: server; ipstr: ARRAY OF CHAR);
BEGIN COPY(ipstr, s^.ListenOnStr)
END setListenOn;

PROCEDURE setHandler*(VAR s: server; h: handler);
BEGIN
  IF s # NIL THEN s^.handle := h ELSE Out.String(msgNotInitialized); Out.Ln END
END setHandler;

PROCEDURE setTimeOut*(VAR s: server; to: LONGREAL);
BEGIN s^.timeoutval := to
END setTimeOut;

PROCEDURE setPort*(VAR s: server; p: INTEGER);
BEGIN
  IF s # NIL THEN s^.Port := p ELSE Out.String(msgNotInitialized); Out.Ln END
END setPort;

PROCEDURE setMaxQueue*(VAR s: server; p: INTEGER);
BEGIN
  IF s # NIL THEN s^.MaxQueue := p ELSE Out.String(msgNotInitialized); Out.Ln END
END setMaxQueue;

(** listen on the address and port *)
PROCEDURE start*(VAR s: server);
VAR a: Sockets.Address;
BEGIN
  IF s^.handle = NIL THEN Out.String(msgHandlerNotSet); Out.Ln; HALT(1) END;
  IF ~Sockets.ParseAddress(s^.ListenOnStr, a) THEN
    Out.String("not an address: "); Out.String(s^.ListenOnStr); Out.Ln; HALT(1)
  END;
  s^.listener := Sockets.ListenAt(a, LONG(s^.Port) MOD 10000H, s^.MaxQueue);
  IF s^.listener = NIL THEN
    Out.String("listening on "); Out.String(s^.ListenOnStr); Out.String(" failed, error "); Out.Int(-Sockets.res, 0)
  ELSE Out.String("listening on "); Out.String(s^.ListenOnStr); Out.String(" port "); Out.Int(LONG(s^.Port) MOD 10000H, 0)
  END;
  Out.Ln
END start;

(** accept connections; each in a child process, which calls the handler and returns from serve.
  newNonBlock: the connection does not block (reads give no data instead of waiting) *)
PROCEDURE serve*(VAR s: server; newNonBlock: BOOLEAN);
VAR peer: Sockets.Address; port: LONGINT;
BEGIN
  IF s^.listener = NIL THEN Out.String("server: not listening (start)"); Out.Ln; RETURN END;
  ignoreChildExit();  (* change child handling only when actually serving *)
  LOOP
    s^.conn := Sockets.Accept(s^.listener, peer, port);
    IF s^.conn = NIL THEN Out.String("error on accept"); Out.Ln
    ELSE
      Sockets.AddressToString(peer, s^.clientIP);
      Out.String("connection from "); Out.String(s^.clientIP); Out.Ln;
      s^.pid := netForker.fork();
      IF s^.pid < 0 THEN Out.String("error on fork"); Out.Ln; Sockets.Close(s^.conn)
      ELSIF s^.pid = 0 THEN  (* the child *)
        Sockets.Close(s^.listener); s^.listener := NIL;
        s^.newsockfd := s^.conn.fd;
        IF newNonBlock & (nonBlocking(s^.newsockfd) < 0) THEN
          Out.String("setting the connection non-blocking failed"); Out.Ln
        END;
        s^.pid := Platform.PID;
        s^.handle(s);
        EXIT
      ELSE Sockets.Close(s^.conn)  (* the parent *)
      END
    END
  END
END serve;

END server.
