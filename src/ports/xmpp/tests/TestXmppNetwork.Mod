MODULE TestXmppNetwork;

IMPORT Args, Out, Msg, S := LongStrings, T := XmppTypes, Items := XmppItems,
  TCP := XmppTCP, Client := XmppClient, Core := XmppCore,
  Messenger := XmppMessenger, Sasl := XmppSasl, TLS := TLS13Live, HS := TLS13EncHandshake;

TYPE
  Hook = POINTER TO HookDesc;
  HookDesc = RECORD (Client.HookDesc)
    ready, received, sent, errors, closed: LONGINT;
  END;

VAR port, mode, direct: ARRAY 64 OF CHAR; transport: TCP.Transport; client: Client.Client;
  domain: ARRAY 256 OF CHAR;
  hook: Hook; user, password, resource, to, body: T.String; stanza: Core.Stanza;
  error: Msg.Msg; state: SHORTINT; steps: LONGINT; success: BOOLEAN;

PROCEDURE (h: Hook) Ready(client: Client.Client; jid: T.String);
  VAR expected: T.String;
BEGIN
  IF domain = "localhost" THEN expected := Items.UTF8("օգտվող@localhost/մուտք😀")
  ELSIF mode = "alabel" THEN expected := Items.UTF8("օգտվող@xn--cbbu1a.xn--y9a3aq/մուտք😀")
  ELSE expected := Items.UTF8("օգտվող@ծոց.հայ/մուտք😀")
  END;
  ASSERT(S.Equal(jid^, expected^)); INC(h.ready)
END Ready;

PROCEDURE (h: Hook) Received(client: Client.Client; stanza: Core.Stanza);
  VAR body, expected: T.String;
BEGIN
  ASSERT(stanza.kind = Core.message); body := Messenger.Body(stanza); expected := Items.UTF8("Բարեւ 😀");
  ASSERT(S.Equal(body^, expected^)); INC(h.received)
END Received;

PROCEDURE (h: Hook) Sent(client: Client.Client; stanza: Core.Stanza);
BEGIN INC(h.sent) END Sent;
PROCEDURE (h: Hook) Error(client: Client.Client; error: Msg.Msg);
BEGIN INC(h.errors) END Error;
PROCEDURE (h: Hook) Closed(client: Client.Client);
BEGIN INC(h.closed) END Closed;

PROCEDURE InvalidConfiguration;
  VAR t: TCP.Transport; error: Msg.Msg; domain: ARRAY 300 OF CHAR; i: LONGINT;
BEGIN
  t := TCP.Open("127.0.0.1", "5222", "", TRUE, 1000, error); ASSERT((t = NIL) & (error # NIL));
  t := TCP.Open("127.0.0.1", "5222", "localhost.", TRUE, 1000, error); ASSERT((t = NIL) & (error # NIL));
  t := TCP.Open("127.0.0.1", "5222", "bad_domain", TRUE, 1000, error); ASSERT((t = NIL) & (error # NIL));
  t := TCP.Open("127.0.0.1", "65536", "localhost", TRUE, 1000, error); ASSERT((t = NIL) & (error # NIL));
  t := TCP.Open("127.0.0.1", "5222", "localhost", TRUE, 0, error); ASSERT((t = NIL) & (error # NIL));
  FOR i := 0 TO LEN(domain)-2 DO domain[i] := "a" END; domain[LEN(domain)-1] := 0X;
  t := TCP.Open("127.0.0.1", "5222", domain, TRUE, 1000, error); ASSERT((t = NIL) & (error # NIL))
END InvalidConfiguration;

PROCEDURE FailureReset;
  VAR state: TLS.State;
BEGIN
  TLS.keyPin := "stale"; TLS.certPin := "stale"; TLS.pinned := TRUE; TLS.identitySent := TRUE;
  ASSERT(~TLS.Connect("127.0.0.1", "invalid", state));
  ASSERT((state.fd = -1) & ~state.connected & ~state.handshakeDone);
  ASSERT((TLS.lastError = "no connection") & (TLS.keyPin = "") & (TLS.certPin = ""));
  ASSERT(~TLS.pinned & ~TLS.identitySent & (HS.CapturedCertCount() = 0) & ~HS.HostnameOK());
  TLS.keyPin := "stale"; TLS.certPin := "stale"; TLS.pinned := TRUE; TLS.identitySent := TRUE;
  ASSERT(~TLS.Start("localhost", -1, state));
  ASSERT((state.fd = -1) & ~state.connected & ~state.handshakeDone);
  ASSERT((state.clientAppKey.len = 0) & (state.serverAppKey.len = 0));
  ASSERT((TLS.lastError = "no connection") & (TLS.keyPin = "") & (TLS.certPin = ""));
  ASSERT(~TLS.pinned & ~TLS.identitySent & (HS.CapturedCertCount() = 0) & ~HS.HostnameOK())
END FailureReset;

BEGIN
  InvalidConfiguration;
  Args.Get(1, port); Args.Get(2, mode); Args.Get(3, direct);
  Args.Get(4, domain); IF domain = "" THEN domain := "localhost" END;
  success := (mode = "starttls") OR (mode = "direct") OR (mode = "unicode") OR (mode = "alabel");
  transport := TCP.Open("127.0.0.1", port, domain, direct = "yes", 2000, error);
  IF transport = NIL THEN ASSERT(~success & (error # NIL))
  ELSE
    NEW(hook); user := Items.UTF8("օգտվող"); password := Items.UTF8("գաղտնի😀"); resource := Items.UTF8("մուտք😀");
    client := Client.New(transport, hook, domain, user^, password^, resource^, TRUE, error);
    Sasl.Wipe(password); ASSERT((client # NIL) & (error = NIL)); ASSERT(client.Start()); steps := 0;
    REPEAT state := client.Step(); INC(steps); ASSERT(steps < 10000)
    UNTIL (state = Client.online) OR (state = Client.failed) OR (state = Client.closed);
    IF ~success THEN
      ASSERT((state = Client.failed) & (client.error # NIL) & (hook.ready = 0) & (hook.errors = 1));
      client.Abort
    ELSE
      ASSERT((state = Client.online) & client.authenticated & transport.AuthenticatedFor(domain));
      ASSERT(~transport.AuthenticatedFor("127.0.0.1"));
      ASSERT((hook.ready = 1) & (hook.sent = 0));
      to := Items.Latin1("friend@localhost"); body := Items.UTF8("Բարեւ 😀");
      stanza := Messenger.NewMessage(to^, body^); client.Send(stanza, error); ASSERT(error = NIL);
      REPEAT state := client.Step() UNTIL (hook.received > 0) OR (state = Client.failed);
      ASSERT((state = Client.online) & (hook.received = 1) & (hook.sent = 1));
      client.Close(error); ASSERT(error = NIL);
      REPEAT state := client.Step() UNTIL (state = Client.closed) OR (state = Client.failed);
      ASSERT((state = Client.closed) & (hook.closed = 1) & (hook.errors = 0))
    END
  END;
  FailureReset;
  Out.String("XMPP loopback client passed"); Out.Ln
END TestXmppNetwork.
