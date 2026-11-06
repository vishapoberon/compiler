MODULE TestXmppNetwork;

IMPORT Args, Out, Msg, S := LongStrings, T := XmppTypes, Items := XmppItems,
  TCP := XmppTCP, Client := XmppClient, Core := XmppCore,
  Messenger := XmppMessenger, Sasl := XmppSasl, TLS := TLS13Live, HS := TLS13EncHandshake,
  IQ := XmppIQ, Ping := XmppPing, Version := XmppVersion, Disco := XmppDisco,
  Roster := XmppRoster, PubSub := XmppPubSub, P := XmppPresence, Track := XmppPresenceTracker,
  Muc := XmppMuc, Rooms := XmppMucTracker, Channel, Mem := IOMemory,
  Ibb := XmppIbbTransfer;

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
  RoomHook = POINTER TO RoomHookDesc;
  RoomHookDesc = RECORD (Rooms.HookDesc) changes, notices, resets: LONGINT END;
  IbbHook = POINTER TO IbbHookDesc;
  IbbHookDesc = RECORD (Ibb.HookDesc) finished: LONGINT END;

VAR port, mode, direct: ARRAY 64 OF CHAR; transport: TCP.Transport; client: Client.Client;
  domain: ARRAY 256 OF CHAR;
  hook: Hook; user, password, resource, to, body: T.String; stanza: Core.Stanza;
  error: Msg.Msg; state: SHORTINT; steps: LONGINT; success: BOOLEAN;
  router: IQ.Router; ping: Ping.Pinger; version: Version.Version; disco: Disco.Disco;
  action: Action; request: IQ.Request; name, number, os: T.String;
  roster: Roster.Roster; rosterHook: RosterHook; events: LONGINT;
  tracker: Track.Tracker; presenceHook: PresenceHook;
  rooms: Rooms.Tracker; roomHook: RoomHook; mucRoom: Rooms.Room;
  mucPresences, mucMessages, mucSubjects, mucRejected, mucInvitations: LONGINT;
  ibb: Ibb.Manager; ibbHook: IbbHook; incomingFile: Mem.Channel;

PROCEDURE (h: IbbHook) Incoming(manager: Ibb.Manager; transfer: Ibb.Transfer;
  VAR writer: Channel.Writer; VAR maximum: LONGINT): BOOLEAN;
BEGIN
  IF ~S.Equal8(transfer.peer^, "peer@example.org/resource") OR ~S.Equal8(transfer.sid^, "download") THEN RETURN FALSE END;
  writer := incomingFile.NewWriter(); maximum := 513; RETURN TRUE
END Incoming;
PROCEDURE (h: IbbHook) Done(manager: Ibb.Manager; transfer: Ibb.Transfer);
BEGIN ASSERT((transfer.status = Ibb.done) & (transfer.bytes = 513)); INC(h.finished) END Done;

PROCEDURE (a: Action) Done(router: IQ.Router; request: IQ.Request);
BEGIN
  IF a.kind = 1 THEN ASSERT(PubSub.Published(request))
  ELSIF a.kind = 2 THEN ASSERT(PubSub.ReadItems(request) # NIL)
  ELSIF a.kind = 3 THEN ASSERT(Muc.ReadConfiguration(request) # NIL)
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
PROCEDURE (h: RoomHook) Changed(tracker: Rooms.Tracker; room: Rooms.Room);
BEGIN INC(h.changes) END Changed;
PROCEDURE (h: RoomHook) Presence(tracker: Rooms.Tracker; room: Rooms.Room; event: Muc.Occupant; applied: BOOLEAN);
BEGIN ASSERT(applied); INC(h.notices) END Presence;
PROCEDURE (h: RoomHook) Reset(tracker: Rooms.Tracker);
BEGIN ASSERT((tracker.count = 0) & (tracker.occupantCount = 0)); INC(h.resets) END Reset;

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
  VAR body, expected, node: T.String; event: PubSub.Event; occupant: Muc.Occupant;
    message: Muc.Message; invitation: Muc.Invitation;
BEGIN
  IF (mode = "ibb") & (stanza.kind = Core.iq) THEN RETURN END;
  IF (mode = "presence") & (stanza.kind = Core.presence) THEN RETURN END;
  IF mode = "muc" THEN
    node := Items.Latin1("room@conference.example.org");
    IF stanza.kind = Core.presence THEN
      occupant := Muc.ReadPresence(stanza, node^);
      IF occupant = NIL THEN INC(mucRejected)
      ELSE
        ASSERT(occupant.HasStatus(110));
        IF mucPresences < 2 THEN expected := Items.UTF8("Անի😀") ELSE expected := Items.UTF8("Նոր😀") END;
        ASSERT(S.Equal(occupant.nick^, expected^));
        IF (mucPresences = 0) OR (mucPresences = 2) THEN ASSERT(occupant.presence.kind = P.available)
        ELSE ASSERT((mucPresences < 4) & (occupant.presence.kind = P.unavailable)) END;
        INC(mucPresences)
      END;
      RETURN
    ELSIF S.Equal8(stanza.type^, "groupchat") THEN
      message := Muc.ReadMessage(stanza, node^); ASSERT(message # NIL);
      IF message.bodyCount > 0 THEN expected := Items.UTF8("Բարեւ 😀"); ASSERT(S.Equal(message.body^, expected^)); INC(mucMessages)
      ELSE expected := Items.UTF8("Թեմա😀"); ASSERT(S.Equal(message.subject^, expected^)); INC(mucSubjects)
      END;
      RETURN
    ELSIF stanza.kind = Core.iq THEN
      INC(mucRejected); RETURN
    ELSIF stanza.kind = Core.message THEN
      invitation := Muc.ReadInvitation(stanza, node^);
      IF invitation # NIL THEN
        ASSERT(~invitation.declined & S.Equal8(invitation.peer^, "person@example.org"));
        ASSERT(S.Equal8(invitation.password^, "room-secret")); INC(mucInvitations); RETURN
      END
    END
  END;
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

PROCEDURE IbbTest;
  VAR source: Mem.Channel; writer: Channel.Writer; reader: Channel.Reader;
    raw, copy: ARRAY 513 OF CHAR; peer, sid: T.String; transfer: Ibb.Transfer; i: LONGINT;
BEGIN
  source := Mem.Tmp("", {Mem.read, Mem.write}, error); ASSERT(error = NIL);
  incomingFile := Mem.Tmp("", {Mem.read, Mem.write}, error); ASSERT(error = NIL);
  FOR i := 0 TO LEN(raw)-1 DO raw[i] := CHR(i MOD 256) END;
  writer := source.NewWriter(); writer.WriteBytes(raw, 0, LEN(raw)); ASSERT(writer.res = NIL);
  reader := source.NewReader(); peer := Items.Latin1("peer@example.org/resource"); sid := Items.Latin1("upload");
  transfer := ibb.Send(peer^, sid^, reader, LEN(raw), 256, error); ASSERT((transfer # NIL) & (error = NIL));
  REPEAT state := client.Step() UNTIL (ibbHook.finished = 2) OR (state = Client.failed);
  ASSERT((state = Client.online) & (transfer.status = Ibb.done) & (ibb.count = 0) & (router.count = 0));
  reader := incomingFile.NewReader(); reader.ReadBytes(copy, 0, LEN(copy)); ASSERT((reader.res = NIL) & (reader.bytesRead = LEN(copy)));
  FOR i := 0 TO LEN(raw)-1 DO ASSERT(copy[i] = raw[i]) END;
  source.Close; incomingFile.Close; hook.sent := 0
END IbbTest;

PROCEDURE WaitRoomRequest;
BEGIN
  ASSERT((request # NIL) & (error = NIL));
  REPEAT state := client.Step() UNTIL (request.status # IQ.pending) OR (state = Client.failed);
  ASSERT(request.status = IQ.result)
END WaitRoomRequest;

PROCEDURE MucTest;
  VAR room, nick, password, empty, text, peer, role: T.String; form, field, value: Items.Item;
BEGIN
  room := Items.Latin1("room@conference.example.org"); nick := Items.UTF8("Անի😀");
  password := Items.Latin1("room-secret"); empty := Items.Latin1("");
  mucRoom := rooms.Join(room^, nick^, password^, 0, 2000, error); ASSERT((mucRoom # NIL) & (error = NIL));
  ASSERT(mucRoom.state = Rooms.joining);
  REPEAT state := client.Step() UNTIL (mucPresences = 1) OR (state = Client.failed);
  ASSERT((mucPresences = 1) & (mucRejected = 1) & (mucRoom.state = Rooms.joined) & (mucRoom.count = 1));
  text := Items.UTF8("Բարեւ 😀"); stanza := Muc.GroupMessage(room^, text^); client.Send(stanza, error); ASSERT(error = NIL);
  REPEAT state := client.Step() UNTIL (mucMessages = 1) OR (state = Client.failed);
  ASSERT(mucMessages = 1);
  text := Items.UTF8("Թեմա😀"); stanza := Muc.Subject(room^, text^); client.Send(stanza, error); ASSERT(error = NIL);
  REPEAT state := client.Step() UNTIL (mucSubjects = 1) OR (state = Client.failed);
  ASSERT(mucSubjects = 1);
  peer := Items.Latin1("person@example.org"); text := Items.UTF8("Միացիր😀");
  stanza := Muc.Invite(room^, peer^, text^); client.Send(stanza, error); ASSERT(error = NIL);
  REPEAT state := client.Step() UNTIL (mucInvitations = 1) OR (state = Client.failed);
  ASSERT(mucInvitations = 1);
  stanza := Muc.Decline(room^, peer^, text^); client.Send(stanza, error); ASSERT(error = NIL);
  NEW(action); action.kind := 3;
  request := Muc.RequestConfiguration(router, room^, 2000, action, error); WaitRoomRequest;
  ASSERT(mucRejected = 2); action.kind := 0;
  form := Items.New("x", Muc.formURI); text := Items.Latin1("submit"); form.SetParam("type", text^);
  field := Items.New("field", Muc.formURI); text := Items.Latin1("FORM_TYPE"); field.SetParam("var", text^);
  value := Items.New("value", Muc.formURI); text := Items.Latin1(Muc.configURI);
  value.AddText(text^, 0, S.Length(text^)); field.AddChild(value); form.AddChild(field);
  request := Muc.SubmitConfiguration(router, room^, form, 2000, action, error); WaitRoomRequest;
  request := Muc.ConfigureDefault(router, room^, FALSE, 2000, action, error); WaitRoomRequest;
  role := Items.Latin1("visitor"); text := Items.UTF8("Կարգ😀");
  request := Muc.SetRole(router, room^, nick^, role^, text^, 2000, action, error); WaitRoomRequest;
  role := Items.Latin1("member");
  request := Muc.SetAffiliation(router, room^, peer^, role^, text^, 2000, action, error); WaitRoomRequest;
  nick := Items.UTF8("Նոր😀"); ASSERT(rooms.Rename(mucRoom, nick^, 2000, error));
  REPEAT state := client.Step() UNTIL (mucPresences = 3) OR (state = Client.failed);
  ASSERT((mucPresences = 3) & (mucRoom.state = Rooms.joined) & S.Equal(mucRoom.nick^, nick^) & (mucRoom.count = 1));
  ASSERT(rooms.Leave(mucRoom, empty^, 2000, error));
  REPEAT state := client.Step() UNTIL (mucPresences = 4) OR (state = Client.failed);
  ASSERT((mucPresences = 4) & (mucRoom.state = Rooms.left) & (rooms.occupantCount = 0));
  request := Muc.Destroy(router, room^, empty^, text^, 2000, action, error); WaitRoomRequest;
  ASSERT((hook.sent = 13) & (action.calls = 6) & (roomHook.notices = 4)); hook.sent := 0
END MucTest;

BEGIN
  InvalidConfiguration;
  Args.Get(1, port); Args.Get(2, mode); Args.Get(3, direct);
  Args.Get(4, domain); IF domain = "" THEN domain := "localhost" END;
  success := (mode = "starttls") OR (mode = "direct") OR (mode = "unicode") OR (mode = "alabel") OR (mode = "extensions") OR (mode = "roster-pep") OR (mode = "presence") OR (mode = "muc") OR (mode = "ibb");
  transport := TCP.Open("127.0.0.1", port, domain, direct = "yes", 2000, error);
  IF transport = NIL THEN ASSERT(~success & (error # NIL))
  ELSE
    NEW(hook); user := Items.UTF8("օգտվող"); password := Items.UTF8("գաղտնի😀"); resource := Items.UTF8("մուտք😀");
    NEW(roomHook); rooms := Rooms.New(hook, roomHook); ASSERT(rooms # NIL);
    NEW(presenceHook); tracker := Track.New(rooms, presenceHook); ASSERT(tracker # NIL);
    name := Items.UTF8("friend@ծոց.հայ"); ASSERT(tracker.Watch(name^));
    IF mode = "ibb" THEN
      NEW(ibbHook); ibb := Ibb.New(tracker, ibbHook, 513, 256, 2000); ASSERT(ibb # NIL); router := ibb.router
    ELSE router := IQ.New(tracker)
    END;
    ping := Ping.New(router); ASSERT(ping # NIL);
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
      IF mode = "muc" THEN MucTest END;
      IF mode = "ibb" THEN IbbTest END;
      to := Items.Latin1("friend@localhost"); body := Items.UTF8("Բարեւ 😀");
      stanza := Messenger.NewMessage(to^, body^); client.Send(stanza, error); ASSERT(error = NIL);
      REPEAT state := client.Step() UNTIL (hook.received > 0) OR (state = Client.failed);
      ASSERT((state = Client.online) & (hook.received = 1) & (hook.sent = 1));
      client.Close(error); ASSERT(error = NIL);
      REPEAT state := client.Step() UNTIL (state = Client.closed) OR (state = Client.failed);
      ASSERT((state = Client.closed) & (hook.closed = 1) & (hook.errors = 0));
      ASSERT(~tracker.active & (tracker.count = 0));
      ASSERT(~rooms.active & (rooms.count = 0) & (rooms.occupantCount = 0))
    END
  END;
  FailureReset;
  Out.String("XMPP loopback client passed"); Out.Ln
END TestXmppNetwork.
