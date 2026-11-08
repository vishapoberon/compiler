MODULE XmppAsyncTCP;

(* Bounded nonblocking TCP/TLS transport for caller-fed XMPP clients. *)

IMPORT SYSTEM, Msg, S := LongStrings, IDNA, Sockets, TLS := TLS13Live,
  Items := XmppItems, Wire := XmppWire, C := XmppClient;

CONST
  connecting* = 0; plain* = 1; handshaking* = 2; secure* = 3; closed* = 4;
  maxQueuedBytes* = 131072;
  invalidConfig* = 1; connectionError* = 2; ioError* = 3; tlsError* = 4;
  queueFull* = 5; timedOut* = 6;

TYPE
  Transport* = POINTER TO TransportDesc;
  TransportDesc* = RECORD (Wire.TransportDesc)
    state-: SHORTINT;
    socket: Sockets.Socket;
    tls: TLS.State;
    domain, tlsName: Items.Bytes;
    client: C.Client;
    output: ARRAY maxQueuedBytes OF CHAR;
    input: ARRAY 8192 OF CHAR;
    first, last, position, length, remaining: LONGINT;
    direct, started, tlsOwned, finishing: BOOLEAN
  END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR text: Msg.LString);
BEGIN
  CASE message.code OF
  | invalidConfig: S.Long("Invalid asynchronous XMPP endpoint or client", text)
  | connectionError: S.Long("Connecting the asynchronous XMPP socket failed", text)
  | tlsError: S.Long("Asynchronous XMPP TLS verification or record operation failed", text)
  | queueFull: S.Long("Asynchronous XMPP output queue is full", text)
  | timedOut: S.Long("Asynchronous XMPP negotiation deadline expired", text)
  ELSE S.Long("Asynchronous XMPP socket I/O failed", text)
  END
END GetTemplate;

PROCEDURE Shutdown(t: Transport);
  VAR i: LONGINT;
BEGIN
  IF t.tlsOwned THEN TLS.CloseNow(t.tls); t.tlsOwned := FALSE END;
  Sockets.Close(t.socket); t.socket := NIL; t.state := closed;
  FOR i := 0 TO LEN(t.output)-1 DO t.output[i] := 0X END;
  FOR i := 0 TO LEN(t.input)-1 DO t.input[i] := 0X END;
  t.first := 0; t.last := 0; t.position := 0; t.length := 0; t.finishing := FALSE
END Shutdown;

PROCEDURE (t: Transport) Close*;
BEGIN
  IF (t.client # NIL) & (t.client.state = C.closed) & (t.first # t.last) &
    ((t.state = plain) OR (t.state = secure)) THEN t.finishing := TRUE
  ELSE Shutdown(t)
  END
END Close;

PROCEDURE Fail(t: Transport; code: SHORTINT);
BEGIN
  IF t.res = NIL THEN t.res := Msg.New(context, code) END;
  IF t.client # NIL THEN t.client.End END;
  Shutdown(t)
END Fail;

PROCEDURE (t: Transport) DomainName*(domain: ARRAY OF CHAR; VAR canonical: Items.Bytes): BOOLEAN;
  VAR unicode, ascii: IDNA.String; status: LONGINT;
BEGIN
  canonical := NIL; IF (S.Length8(domain) = 0) OR (S.Length8(domain) > 1024) THEN RETURN FALSE END;
  IDNA.Names(domain, unicode, ascii, status); IF status # 0 THEN RETURN FALSE END;
  canonical := Items.Copy8(unicode^); RETURN TRUE
END DomainName;

PROCEDURE (t: Transport) AuthenticatedFor*(domain: ARRAY OF CHAR): BOOLEAN;
  VAR canonical: Items.Bytes;
BEGIN
  RETURN (t.state = secure) & t.tls.connected & t.tls.handshakeDone &
    t.DomainName(domain, canonical) & (canonical^ = t.domain^)
END AuthenticatedFor;

PROCEDURE (t: Transport) WriteBytes*(VAR bytes: ARRAY OF SYSTEM.BYTE; start, count: LONGINT);
  VAR i, queued: LONGINT;
BEGIN
  t.bytesWritten := 0;
  IF (t.state = closed) OR t.finishing THEN IF t.res = NIL THEN t.res := Msg.New(context, ioError) END; RETURN END;
  IF (start < 0) OR (count < 0) OR (start > LEN(bytes)) OR (count > LEN(bytes)-start) THEN Fail(t, invalidConfig); RETURN END;
  queued := t.last-t.first;
  IF count > LEN(t.output)-queued THEN Fail(t, queueFull); RETURN END;
  IF count > LEN(t.output)-t.last THEN
    FOR i := 0 TO queued-1 DO t.output[i] := t.output[t.first+i] END;
    FOR i := queued TO t.last-1 DO t.output[i] := 0X END;
    t.first := 0; t.last := queued
  END;
  FOR i := 0 TO count-1 DO t.output[t.last+i] := SYSTEM.VAL(CHAR, bytes[start+i]) END;
  INC(t.last, count); t.bytesWritten := count
END WriteBytes;

PROCEDURE Flush(t: Transport): BOOLEAN;
  VAR n, i: LONGINT; result: INTEGER;
BEGIN
  IF t.first = t.last THEN
    IF t.state = secure THEN
      result := TLS.FlushOutput(t.tls); IF result < 0 THEN Fail(t, tlsError); RETURN FALSE END
    END;
    RETURN TRUE
  END;
  n := t.last-t.first; IF n > 16384 THEN n := 16384 END;
  IF t.state = plain THEN
    n := Sockets.SendSome(t.socket, t.output, t.first, n);
    IF Sockets.WouldBlock(n) OR Sockets.Interrupted(n) THEN RETURN TRUE END
  ELSIF t.state = secure THEN
    n := TLS.WriteSome(t.tls, t.output, t.first, n); IF n = -2 THEN RETURN TRUE END
  ELSE RETURN TRUE
  END;
  IF n <= 0 THEN Fail(t, ioError); RETURN FALSE END;
  FOR i := t.first TO t.first+n-1 DO t.output[i] := 0X END;
  INC(t.first, n); IF t.first = t.last THEN t.first := 0; t.last := 0 END;
  RETURN TRUE
END Flush;

PROCEDURE BeginTLS(t: Transport): BOOLEAN;
  VAR fd: LONGINT;
BEGIN
  IF (t.state # plain) OR (t.first # t.last) OR (t.position # t.length) THEN Fail(t, tlsError); RETURN FALSE END;
  fd := t.socket.fd; t.socket.fd := -1; t.socket := NIL; t.tlsOwned := TRUE;
  IF ~TLS.Begin(t.tlsName^, fd, t.tls) THEN Fail(t, tlsError); RETURN FALSE END;
  t.state := handshaking; RETURN TRUE
END BeginTLS;

PROCEDURE OpenAddress*(VAR address: Sockets.Address; port: LONGINT; service: ARRAY OF CHAR;
                       direct: BOOLEAN; timeoutMS: LONGINT; VAR error: Msg.Msg): Transport;
  VAR t: Transport; local: Sockets.Address; unicode, ascii: IDNA.String; status: LONGINT;
BEGIN
  error := NIL;
  IF ((address.family # Sockets.Inet4) & (address.family # Sockets.Inet6)) OR
    (port < 1) OR (port > 65535) OR (timeoutMS < 1) OR (timeoutMS > 600000) OR
    (S.Length8(service) = 0) OR (S.Length8(service) > 1024) THEN error := Msg.New(context, invalidConfig); RETURN NIL END;
  IDNA.Names(service, unicode, ascii, status); IF status # 0 THEN error := Msg.New(context, invalidConfig); RETURN NIL END;
  NEW(t); TLS.Init(t.tls); t.domain := Items.Copy8(unicode^); t.tlsName := Items.Copy8(ascii^);
  t.direct := direct; t.remaining := timeoutMS; Sockets.AnyAddress(address.family, local);
  t.socket := Sockets.ConnectFrom(local, address, port);
  IF t.socket = NIL THEN error := Msg.New(context, connectionError); RETURN NIL END;
  RETURN t
END OpenAddress;

PROCEDURE (t: Transport) Descriptor*(): LONGINT;
BEGIN
  IF t.socket # NIL THEN RETURN t.socket.fd END;
  IF t.tlsOwned THEN RETURN t.tls.fd END;
  RETURN -1
END Descriptor;

PROCEDURE (t: Transport) WantWrite*(): BOOLEAN;
BEGIN RETURN (t.state = connecting) OR (((t.state = plain) OR (t.state = secure)) & (t.first # t.last)) END WantWrite;
PROCEDURE (t: Transport) WantRead*(): BOOLEAN;
BEGIN RETURN ~t.finishing & ((t.state = plain) OR (t.state = secure) OR (t.state = handshaking)) END WantRead;

PROCEDURE (t: Transport) Drive*(client: C.Client): SHORTINT;
  VAR n, consumed, events: LONGINT; result: INTEGER; state: SHORTINT;
BEGIN
  ASSERT(client # NIL);
  IF t.client = NIL THEN t.client := client
  ELSIF t.client # client THEN RETURN C.failed
  END;
  IF client.state = C.failed THEN Shutdown(t); RETURN client.state END;
  IF client.state = C.closed THEN
    IF t.finishing THEN
      IF ~Flush(t) THEN RETURN client.state END;
      IF t.first = t.last THEN Shutdown(t) END
    ELSE Shutdown(t)
    END;
    RETURN client.state
  END;
  IF t.state = closed THEN client.End; RETURN client.state END;
  IF t.state = connecting THEN
    n := Sockets.PollConnect(t.socket);
    IF n < 0 THEN Fail(t, connectionError)
    ELSIF n = 0 THEN t.state := plain
    END;
    IF t.state # plain THEN RETURN client.state END
  END;
  IF t.state = handshaking THEN
    result := TLS.PollHandshake(t.tls);
    IF result < 0 THEN Fail(t, tlsError); RETURN client.state END;
    IF result = 0 THEN RETURN client.state END;
    t.state := secure;
    IF t.started & ~client.TLSReady() THEN RETURN client.state END
  END;
  IF ~t.started THEN
    IF t.direct & (t.state = plain) THEN
      IF ~BeginTLS(t) THEN RETURN client.state END;
      RETURN client.state
    END;
    t.started := TRUE; IF ~client.Start() THEN RETURN client.state END
  END;
  IF ~Flush(t) THEN RETURN client.state END;
  IF client.state = C.upgrading THEN
    IF t.position # t.length THEN Fail(t, tlsError)
    ELSIF t.first = t.last THEN
      IF ~BeginTLS(t) THEN RETURN client.state END
    END;
    RETURN client.state
  END;
  IF t.position = t.length THEN
    IF t.state = secure THEN n := TLS.ReadSome(t.tls, t.input, 0, LEN(t.input))
    ELSE
      n := Sockets.ReceiveSome(t.socket, t.input, 0, LEN(t.input));
      IF Sockets.WouldBlock(n) OR Sockets.Interrupted(n) THEN n := -2 END
    END;
    IF n = -2 THEN RETURN client.state END;
    IF n <= 0 THEN Fail(t, ioError); RETURN client.state END;
    t.position := 0; t.length := n
  END;
  events := 0;
  REPEAT
    state := client.Feed(t.input, t.position, t.length-t.position, consumed);
    INC(t.position, consumed); INC(events);
    IF (state = C.failed) OR (state = C.closed) OR (state = C.upgrading) THEN RETURN state END;
    IF consumed = 0 THEN Fail(t, ioError); RETURN client.state END
  UNTIL (t.position = t.length) OR (events = 8);
  RETURN client.state
END Drive;

PROCEDURE (t: Transport) Tick*(elapsedMS: LONGINT);
BEGIN
  ASSERT(elapsedMS >= 0);
  IF (t.state = closed) OR ((t.client # NIL) & (t.client.state = C.online)) THEN RETURN END;
  IF elapsedMS >= t.remaining THEN Fail(t, timedOut) ELSE DEC(t.remaining, elapsedMS) END
END Tick;

PROCEDURE (t: Transport) Cancel*;
BEGIN
  IF t.client # NIL THEN t.client.Abort END;
  Shutdown(t)
END Cancel;

BEGIN NEW(context); Msg.InitContext(context, "XmppAsyncTCP")
END XmppAsyncTCP.
