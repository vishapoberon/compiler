MODULE XmppSocks5TCP;

(* Nonblocking TCP connection and bounded XEP-0065 SOCKS5 client negotiation. *)

IMPORT Msg, S := LongStrings, Sockets, DNS, IDNA, K := XmppSocks5;

CONST
  connecting* = 0; negotiating* = 1; ready* = 2; failed* = 3; closed* = 4;
  invalidAddress* = 1; connectError* = 2; ioError* = 3; protocolError* = 4;
  timedOut* = 5; cancelled* = 6;

TYPE
  Client* = POINTER TO ClientDesc;
  ClientDesc* = RECORD
    state-: SHORTINT;
    error-: Msg.Msg;
    socket: Sockets.Socket;
    handshake: K.Handshake;
    addresses: ARRAY 8 OF Sockets.Address;
    count, next, port, remaining: LONGINT
  END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR text: Msg.LString);
BEGIN
  CASE message.code OF
  | invalidAddress: S.Long("Invalid SOCKS5 endpoint, destination or timeout", text)
  | connectError: S.Long("Connecting to the approved SOCKS5 endpoint failed", text)
  | protocolError: S.Long("Invalid or mismatched XMPP SOCKS5 negotiation reply", text)
  | timedOut: S.Long("The SOCKS5 connection or negotiation deadline expired", text)
  | cancelled: S.Long("The SOCKS5 connection was cancelled", text)
  ELSE S.Long("SOCKS5 socket I/O failed or ended before negotiation completed", text)
  END
END GetTemplate;

PROCEDURE Fail(client: Client; code: SHORTINT);
BEGIN
  IF client.error = NIL THEN client.error := Msg.New(context, code) END;
  Sockets.Close(client.socket); client.socket := NIL; client.handshake.End; client.state := failed
END Fail;

PROCEDURE Dial(client: Client);
  VAR local: Sockets.Address;
BEGIN
  WHILE client.next < client.count DO
    Sockets.AnyAddress(client.addresses[client.next].family, local);
    client.socket := Sockets.ConnectFrom(local, client.addresses[client.next], client.port); INC(client.next);
    IF client.socket # NIL THEN RETURN END
  END;
  Fail(client, connectError)
END Dial;

PROCEDURE Create(port: LONGINT; destination: ARRAY OF CHAR; timeoutMS: LONGINT; VAR error: Msg.Msg): Client;
  VAR client: Client;
BEGIN
  error := NIL;
  IF (port < 1) OR (port > 65535) OR (timeoutMS < 1) OR (timeoutMS > 600000) OR ~K.Valid(destination) THEN
    error := Msg.New(context, invalidAddress); RETURN NIL
  END;
  NEW(client); client.handshake := K.New(destination); client.port := port; client.remaining := timeoutMS; RETURN client
END Create;

PROCEDURE OpenAddress*(VAR address: Sockets.Address; port: LONGINT; destination: ARRAY OF CHAR;
                       timeoutMS: LONGINT; VAR error: Msg.Msg): Client;
  VAR client: Client;
BEGIN
  client := Create(port, destination, timeoutMS, error); IF client = NIL THEN RETURN NIL END;
  IF (address.family # Sockets.Inet4) & (address.family # Sockets.Inet6) THEN error := Msg.New(context, invalidAddress); RETURN NIL END;
  client.addresses[0] := address; client.count := 1; Dial(client);
  IF client.state = failed THEN error := client.error; RETURN NIL END;
  RETURN client
END OpenAddress;

PROCEDURE Open*(host: ARRAY OF CHAR; port: LONGINT; destination: ARRAY OF CHAR;
                timeoutMS: LONGINT; VAR error: Msg.Msg): Client;
  VAR client: Client; copy: ARRAY 254 OF CHAR; unicode, ascii: IDNA.String; status, i, colons, digits: LONGINT;
    numeric: BOOLEAN;
BEGIN
  client := Create(port, destination, timeoutMS, error); IF client = NIL THEN RETURN NIL END;
  IF (S.Length8(host) = 0) OR (S.Length8(host) > 253) THEN error := Msg.New(context, invalidAddress); RETURN NIL END;
  COPY(host, copy); numeric := TRUE; colons := 0;
  IF (host[0] = "[") # (host[S.Length8(host)-1] = "]") THEN error := Msg.New(context, invalidAddress); RETURN NIL END;
  FOR i := 0 TO S.Length8(host)-1 DO
    IF host[i] = ":" THEN INC(colons) END;
    IF host[i] = "%" THEN error := Msg.New(context, invalidAddress); RETURN NIL END;
    IF ~(((host[i] >= "0") & (host[i] <= "9")) OR (host[i] = ".")) THEN numeric := FALSE END
  END;
  IF numeric OR (colons > 0) THEN
    (* Bound numeric groups before calling the shared literal parser. *)
    digits := 0;
    FOR i := 0 TO S.Length8(host)-1 DO
      IF ((host[i] >= "0") & (host[i] <= "9")) OR ((colons > 0) & (CAP(host[i]) >= "A") & (CAP(host[i]) <= "F")) THEN
        INC(digits);
        IF (digits > 4) OR (numeric & (digits > 3)) THEN error := Msg.New(context, invalidAddress); RETURN NIL END
      ELSIF (host[i] = ":") OR (host[i] = ".") OR ((i = 0) & (host[i] = "[")) OR ((i = S.Length8(host)-1) & (host[i] = "]")) THEN digits := 0
      ELSE error := Msg.New(context, invalidAddress); RETURN NIL
      END
    END;
    IF ~Sockets.ParseAddress(copy, client.addresses[0]) THEN error := Msg.New(context, invalidAddress); RETURN NIL END;
    client.count := 1
  ELSE
    FOR i := 0 TO S.Length8(host)-1 DO
      IF (host[i] = "[") OR (host[i] = "]") THEN error := Msg.New(context, invalidAddress); RETURN NIL END
    END;
    IDNA.Names(host, unicode, ascii, status);
    IF status # 0 THEN error := Msg.New(context, invalidAddress); RETURN NIL END;
    DNS.Lookup(ascii^, DNS.Any, client.addresses, client.count)
  END;
  IF (client.count < 1) OR (client.count > LEN(client.addresses)) THEN error := Msg.New(context, connectError); RETURN NIL END;
  Dial(client); IF client.state = failed THEN error := client.error; RETURN NIL END;
  RETURN client
END Open;

PROCEDURE (client: Client) Descriptor*(): LONGINT;
BEGIN IF client.socket = NIL THEN RETURN -1 ELSE RETURN client.socket.fd END END Descriptor;
PROCEDURE (client: Client) WantWrite*(): BOOLEAN;
BEGIN RETURN (client.state = connecting) OR ((client.state = negotiating) & (client.handshake.Pending() > 0)) END WantWrite;
PROCEDURE (client: Client) WantRead*(): BOOLEAN;
BEGIN RETURN (client.state = negotiating) & (client.handshake.Needed() > 0) END WantRead;

PROCEDURE (client: Client) Step*(): SHORTINT;
  VAR n, consumed: LONGINT; bytes: ARRAY K.packetBytes OF CHAR; state: SHORTINT;
BEGIN
  IF client.state = connecting THEN
    n := Sockets.PollConnect(client.socket);
    IF n = 0 THEN client.state := negotiating
    ELSIF n < 0 THEN Sockets.Close(client.socket); client.socket := NIL; Dial(client)
    END;
    RETURN client.state
  END;
  IF client.state # negotiating THEN RETURN client.state END;
  n := client.handshake.Pending();
  IF n > 0 THEN
    n := client.handshake.Output(bytes, 0, n); n := Sockets.SendSome(client.socket, bytes, 0, n);
    IF Sockets.WouldBlock(n) OR Sockets.Interrupted(n) THEN RETURN client.state END;
    IF n <= 0 THEN Fail(client, ioError)
    ELSIF ~client.handshake.Sent(n) THEN Fail(client, protocolError)
    END
  ELSE
    n := client.handshake.Needed();
    IF n <= 0 THEN Fail(client, protocolError); RETURN client.state END;
    n := Sockets.ReceiveSome(client.socket, bytes, 0, n);
    IF Sockets.WouldBlock(n) OR Sockets.Interrupted(n) THEN RETURN client.state END;
    IF n <= 0 THEN Fail(client, ioError)
    ELSE
      state := client.handshake.Feed(bytes, 0, n, consumed);
      IF (state = K.failed) OR (consumed # n) THEN Fail(client, protocolError)
      ELSIF state = K.ready THEN client.state := ready
      END
    END
  END;
  RETURN client.state
END Step;

PROCEDURE (client: Client) Tick*(elapsedMS: LONGINT);
BEGIN
  ASSERT(elapsedMS >= 0);
  IF (client.state = connecting) OR (client.state = negotiating) THEN
    IF elapsedMS >= client.remaining THEN Fail(client, timedOut) ELSE DEC(client.remaining, elapsedMS) END
  END
END Tick;

PROCEDURE (client: Client) Cancel*;
BEGIN IF (client.state # failed) & (client.state # closed) THEN Fail(client, cancelled) END END Cancel;

PROCEDURE (client: Client) Release*(): Sockets.Socket;
  VAR socket: Sockets.Socket;
BEGIN
  IF client.state # ready THEN RETURN NIL END;
  socket := client.socket; client.socket := NIL; client.state := closed; RETURN socket
END Release;

BEGIN NEW(context); Msg.InitContext(context, "XmppSocks5TCP")
END XmppSocks5TCP.
