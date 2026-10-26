MODULE TestXmppNetwork;

IMPORT Args, Out, Msg, S := LongStrings, T := XmppTypes, Items := XmppItems,
  TCP := XmppTCP, Client := XmppClient, Core := XmppCore,
  Messenger := XmppMessenger, Sasl := XmppSasl, TLS := TLS13Live, HS := TLS13EncHandshake,
  IQ := XmppIQ, Ping := XmppPing, Version := XmppVersion, Disco := XmppDisco,
  Roster := XmppRoster, PubSub := XmppPubSub, P := XmppPresence, Track := XmppPresenceTracker;

TYPE
  Hook = POINTER TO HookDesc;
  HookDesc = RECORD (Client.HookDesc)
    ready, received, sent, errors, closed: LONGINT;
  END;
  Action = POINTER TO ActionDesc;
  ActionDesc = RECORD (IQ.ActionDesc) calls: LONGINT; kind: SHORTINT END;
  RosterHook = POINTER TO RosterHookDesc;
  RosterHookDesc = RECORD (Roster.HookDesc) loads, changes: LONGINT END;
  PresenceHook = POINTER TO PresenceHookDesc;
  PresenceHookDesc = RECORD (Track.HookDesc) notices: LONGINT END;

VAR port, mode, direct: ARRAY 64 OF CHAR; transport: TCP.Transport; client: Client.Client;
  domain: ARRAY 256 OF CHAR;
  hook: Hook; user, password, resource, to, body: T.String; stanza: Core.Stanza;
  error: Msg.Msg; state: SHORTINT; steps: LONGINT; success: BOOLEAN;
  router: IQ.Router; ping: Ping.Pinger; version: Version.Version; disco: Disco.Disco;
  action: Action; request: IQ.Request; name, number, os: T.String;
  roster: Roster.Roster; rosterHook: RosterHook; events: LONGINT;
  tracker: Track.Tracker; presenceHook: PresenceHook;

PROCEDURE (a: Action) Done(router: IQ.Router; request: IQ.Request);
BEGIN
  IF a.kind = 1 THEN ASSERT(PubSub.Published(request))
  ELSIF a.kind = 2 THEN ASSERT(PubSub.ReadItems(request) # NIL)
  ELSE ASSERT(IQ.EmptyResult(request))
  END;
  INC(a.calls)
END Done;

PROCEDURE (h: RosterHook) Loaded(roster: Roster.Roster; request: IQ.Request; accepted: BOOLEAN);
BEGIN ASSERT(accepted); INC(h.loads) END Loaded;
PROCEDURE (h: RosterHook) Changed(roster: Roster.Roster; entry: Roster.Entry);
BEGIN INC(h.changes) END Changed;
PROCEDURE (h: PresenceHook) Notice(tracker: Track.Tracker; event: P.Event; applied: BOOLEAN);
BEGIN INC(h.notices) END Notice;

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
  VAR body, expected, node: T.String; event: PubSub.Event;
BEGIN
  IF (mode = "presence") & (stanza.kind = Core.presence) THEN RETURN END;
  IF mode = "roster-pep" THEN
    expected := Items.UTF8("friend@ծոց.հայ"); node := Items.Latin1("urn:xmpp:microblog:0");
    event := PubSub.ReadEvent(stanza, expected^, node^);
    IF event # NIL THEN
      ASSERT((event.count = 2) & (event.updates[0].kind = PubSub.published) & (event.updates[1].kind = PubSub.retracted));
      INC(events); RETURN
    END
  END;
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

PROCEDURE RosterPEP;
  VAR jid, text, empty, node, id: T.String; groups: ARRAY 1 OF T.String;
    item: Items.Item;
BEGIN
  request := roster.Fetch(2000, error); ASSERT(error = NIL);
  REPEAT state := client.Step() UNTIL (rosterHook.loads = 1) OR (state = Client.failed);
  ASSERT(roster.complete & (roster.snapshot.count = 1));
  REPEAT state := client.Step() UNTIL (rosterHook.changes = 1) OR (state = Client.failed);
  jid := Items.UTF8("friend@ծոց.հայ"); ASSERT(roster.Find(jid^) # NIL);
  NEW(action); text := Items.UTF8("Ընկեր😀"); groups[0] := Items.UTF8("Ընկերներ");
  request := Roster.Set(router, jid^, text^, groups, FALSE, 2000, action, error); ASSERT(error = NIL);
  REPEAT state := client.Step() UNTIL (action.calls = 1) OR (state = Client.failed);
  ASSERT((action.calls = 1) & (roster.snapshot.count = 1));
  empty := Items.Latin1(""); node := Items.Latin1("urn:xmpp:microblog:0"); id := Items.UTF8("գրառում😀");
  item := Items.New("entry", "http://www.w3.org/2005/Atom"); item.AddText(text^, 0, S.Length(text^)); action.kind := 1;
  request := PubSub.Publish(router, empty^, node^, id^, item, 2000, action, error); ASSERT(error = NIL);
  REPEAT state := client.Step() UNTIL (action.calls = 2) OR (state = Client.failed);
  action.kind := 2; request := PubSub.Fetch(router, jid^, node^, id^, 1, 2000, action, error); ASSERT(error = NIL);
  REPEAT state := client.Step() UNTIL (action.calls = 3) OR (state = Client.failed);
  REPEAT state := client.Step() UNTIL (events = 1) OR (state = Client.failed);
  action.kind := 0; request := PubSub.Retract(router, empty^, node^, id^, TRUE, 2000, action, error); ASSERT(error = NIL);
  REPEAT state := client.Step() UNTIL (action.calls = 4) OR (state = Client.failed);
  ASSERT(PubSub.Retracted(request) & (router.count = 0)); hook.sent := 0
END RosterPEP;

PROCEDURE PresenceTest;
  VAR empty, jid, show, status: T.String; best: P.Event;
BEGIN
  empty := Items.Latin1(""); jid := Items.UTF8("friend@ծոց.հայ");
  show := Items.Latin1("chat"); status := Items.UTF8("Բարեւ 😀");
  stanza := P.Available(empty^, show^, status^, 5); client.Send(stanza, error); ASSERT(error = NIL);
  stanza := P.Subscription(jid^, empty^, P.subscribe); client.Send(stanza, error); ASSERT(error = NIL);
  REPEAT state := client.Step() UNTIL (presenceHook.notices = 4) OR (state = Client.failed);
  ASSERT((tracker.count = 2) & (hook.sent = 2)); best := tracker.Best(jid^); ASSERT((best # NIL) & (best.priority = 10));
  stanza := P.Subscription(jid^, empty^, P.subscribed); client.Send(stanza, error); ASSERT(error = NIL);
  stanza := P.Subscription(jid^, empty^, P.unsubscribe); client.Send(stanza, error); ASSERT(error = NIL);
  REPEAT state := client.Step() UNTIL (presenceHook.notices = 6) OR (state = Client.failed);
  ASSERT(tracker.count = 0);
  stanza := P.Subscription(jid^, empty^, P.unsubscribed); client.Send(stanza, error); ASSERT(error = NIL);
  stanza := P.Unavailable(empty^, empty^); client.Send(stanza, error); ASSERT(error = NIL); hook.sent := 0
END PresenceTest;

BEGIN
  InvalidConfiguration;
  Args.Get(1, port); Args.Get(2, mode); Args.Get(3, direct);
  Args.Get(4, domain); IF domain = "" THEN domain := "localhost" END;
  success := (mode = "starttls") OR (mode = "direct") OR (mode = "unicode") OR (mode = "alabel") OR (mode = "extensions") OR (mode = "roster-pep") OR (mode = "presence");
  transport := TCP.Open("127.0.0.1", port, domain, direct = "yes", 2000, error);
  IF transport = NIL THEN ASSERT(~success & (error # NIL))
  ELSE
    NEW(hook); user := Items.UTF8("օգտվող"); password := Items.UTF8("գաղտնի😀"); resource := Items.UTF8("մուտք😀");
    NEW(presenceHook); tracker := Track.New(hook, presenceHook); ASSERT(tracker # NIL);
    name := Items.UTF8("friend@ծոց.հայ"); ASSERT(tracker.Watch(name^));
    router := IQ.New(tracker); ping := Ping.New(router); ASSERT(ping # NIL);
    name := Items.UTF8("VOC Հայերեն😀"); number := Items.Latin1("4.0.2"); os := Items.Latin1("");
    version := Version.New(router, name^, number^, os^); ASSERT(version # NIL);
    name := Items.Latin1("client"); number := Items.Latin1("console");
    disco := Disco.New(router, name^, number^, os^); ASSERT(disco # NIL);
    NEW(rosterHook); roster := Roster.New(router, rosterHook); ASSERT(roster # NIL);
    client := Client.New(transport, router, domain, user^, password^, resource^, TRUE, error);
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
      IF mode = "extensions" THEN
        NEW(action); to := Items.Latin1(""); request := Ping.Query(router, to^, 2000, action, error); ASSERT(error = NIL);
        REPEAT state := client.Step() UNTIL (action.calls > 0) OR (state = Client.failed);
        ASSERT((action.calls = 1) & (router.count = 0) & (hook.sent = 4));
        hook.sent := 0
      END;
      IF mode = "roster-pep" THEN RosterPEP END;
      IF mode = "presence" THEN PresenceTest END;
      to := Items.Latin1("friend@localhost"); body := Items.UTF8("Բարեւ 😀");
      stanza := Messenger.NewMessage(to^, body^); client.Send(stanza, error); ASSERT(error = NIL);
      REPEAT state := client.Step() UNTIL (hook.received > 0) OR (state = Client.failed);
      ASSERT((state = Client.online) & (hook.received = 1) & (hook.sent = 1));
      client.Close(error); ASSERT(error = NIL);
      REPEAT state := client.Step() UNTIL (state = Client.closed) OR (state = Client.failed);
      ASSERT((state = Client.closed) & (hook.closed = 1) & (hook.errors = 0));
      ASSERT(~tracker.active & (tracker.count = 0))
    END
  END;
  FailureReset;
  Out.String("XMPP loopback client passed"); Out.Ln
END TestXmppNetwork.
