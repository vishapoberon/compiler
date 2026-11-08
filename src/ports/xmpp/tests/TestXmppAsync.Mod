MODULE TestXmppAsync;

IMPORT SYSTEM, Args, Out, Msg, Platform, IntStr, Sockets, S := LongStrings,
  T := XmppTypes, Items := XmppItems, Core := XmppCore, C := XmppClient,
  M := XmppMessenger, TCP := XmppAsyncTCP;

TYPE
  Hook = POINTER TO HookDesc;
  HookDesc = RECORD (C.HookDesc) ready, messages, sent, errors, closed: LONGINT END;

VAR hook: Hook; transport: TCP.Transport; client: C.Client; address: Sockets.Address;
  error: Msg.Msg; user, password, resource, target, text: T.String;
  portText, mode, direct, service: ARRAY 256 OF CHAR; literal: ARRAY 16 OF CHAR;
  port, turns: LONGINT; result: IntStr.ConvResults; state: SHORTINT; sent, closing: BOOLEAN;

PROCEDURE (h: Hook) Ready(client: C.Client; jid: T.String);
BEGIN INC(h.ready) END Ready;
PROCEDURE (h: Hook) Received(client: C.Client; stanza: Core.Stanza);
  VAR body, expected: T.String;
BEGIN
  ASSERT(stanza.kind = Core.message); body := M.Body(stanza); expected := Items.UTF8("Բարեւ <աշխարհ> & 😀");
  ASSERT(S.Equal(body^, expected^)); INC(h.messages)
END Received;
PROCEDURE (h: Hook) Sent(client: C.Client; stanza: Core.Stanza);
BEGIN INC(h.sent) END Sent;
PROCEDURE (h: Hook) Error(client: C.Client; error: Msg.Msg);
BEGIN INC(h.errors) END Error;
PROCEDURE (h: Hook) Closed(client: C.Client);
BEGIN INC(h.closed) END Closed;

PROCEDURE Limits;
  VAR listener: Sockets.Socket; endpoint: Sockets.Address; port: LONGINT; t: TCP.Transport;
    bytes: POINTER TO ARRAY OF SYSTEM.BYTE; error: Msg.Msg;
BEGIN
  endpoint := address; listener := Sockets.ListenNonblocking(endpoint, 0, 4);
  ASSERT((listener # NIL) & Sockets.LocalAddress(listener, endpoint, port));
  t := TCP.OpenAddress(endpoint, 0, "localhost", FALSE, 1, error); ASSERT((t = NIL) & (error # NIL));
  t := TCP.OpenAddress(endpoint, port, "localhost", FALSE, 0, error); ASSERT((t = NIL) & (error # NIL));
  t := TCP.OpenAddress(endpoint, port, "bad_domain", FALSE, 1, error); ASSERT((t = NIL) & (error # NIL));
  t := TCP.OpenAddress(endpoint, port, "localhost", FALSE, 1, error); ASSERT(t # NIL);
  t.Tick(1); ASSERT((t.state = TCP.closed) & (t.res.code = TCP.timedOut) & (t.Descriptor() = -1));
  NEW(bytes, TCP.maxQueuedBytes+1);
  t := TCP.OpenAddress(endpoint, port, "localhost", FALSE, 1, error); ASSERT(t # NIL);
  t.WriteBytes(bytes^, 0, LEN(bytes^)); ASSERT((t.state = TCP.closed) & (t.res.code = TCP.queueFull) & (t.bytesWritten = 0));
  t := TCP.OpenAddress(endpoint, port, "localhost", FALSE, 1, error); ASSERT(t # NIL);
  t.WriteBytes(bytes^, 0, TCP.maxQueuedBytes); ASSERT(t.bytesWritten = TCP.maxQueuedBytes);
  t.WriteBytes(bytes^, 0, 1); ASSERT((t.state = TCP.closed) & (t.res.code = TCP.queueFull) & (t.bytesWritten = 0));
  Sockets.Close(listener)
END Limits;

BEGIN
  Args.Get(1, portText); Args.Get(2, mode); Args.Get(3, direct); Args.Get(4, service);
  IF service = "" THEN service := "localhost" END;
  IntStr.StrToInt(portText, port, result); ASSERT(result = 0);
  literal := "127.0.0.1"; ASSERT(Sockets.ParseAddress(literal, address));
  Limits;
  transport := TCP.OpenAddress(address, port, service, direct = "yes", 3000, error);
  ASSERT((transport # NIL) & (error = NIL)); NEW(hook);
  user := Items.UTF8("օգտվող"); password := Items.UTF8("գաղտնիք😀"); resource := Items.UTF8("մուտք😀");
  client := C.New(transport, hook, service, user^, password^, resource^, TRUE, error); ASSERT((client # NIL) & (error = NIL));
  turns := 0;
  REPEAT
    state := transport.Drive(client); INC(turns); ASSERT(turns < 10000);
    IF mode = "cancel" THEN transport.Cancel; state := client.state END;
    IF (mode = "success") & (state = C.online) & ~sent THEN
      ASSERT(transport.AuthenticatedFor(service) & ~transport.AuthenticatedFor("127.0.0.1"));
      target := Items.UTF8("peer@localhost/r"); text := Items.UTF8("Բարեւ <աշխարհ> & 😀");
      client.Send(M.NewMessage(target^, text^), error); ASSERT(error = NIL); sent := TRUE
    END;
    IF (hook.messages = 1) & ~closing THEN client.Close(error); ASSERT(error = NIL); closing := TRUE END;
    Platform.Delay(1); transport.Tick(1)
  UNTIL (client.state = C.failed) OR ((client.state = C.closed) & (transport.state = TCP.closed));
  IF mode = "success" THEN
    ASSERT((client.state = C.closed) & (hook.ready = 1) & (hook.messages = 1) & (hook.sent = 1) & (hook.closed = 1) & (hook.errors = 0))
  ELSIF mode = "cancel" THEN ASSERT((client.state = C.closed) & (hook.ready = 0) & (hook.errors = 0))
  ELSE
    ASSERT((client.state = C.failed) & (hook.errors = 1) & (hook.ready = 0));
    IF mode = "stall" THEN ASSERT(transport.res.code = TCP.timedOut) END
  END;
  ASSERT(transport.Descriptor() = -1); transport.Cancel;
  Out.String("XMPP asynchronous TCP/TLS "); Out.String(mode); Out.String(" checks passed"); Out.Ln
END TestXmppAsync.
