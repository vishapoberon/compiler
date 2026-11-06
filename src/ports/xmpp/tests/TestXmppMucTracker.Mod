MODULE TestXmppMucTracker;

IMPORT SYSTEM, Out, Msg, Channel, IntStr, S := LongStrings, Strings := oocStrings, Mem := IOMemory,
  T := XmppTypes, Items := XmppItems, Wire := XmppWire, Client := XmppClient,
  Core := XmppCore, IQ := XmppIQ, P := XmppPresence, M := XmppMuc, Track := XmppMucTracker;

TYPE
  Fake = POINTER TO FakeDesc;
  FakeDesc = RECORD (Wire.TransportDesc)
    script: Items.Bytes; position, chunk: LONGINT; ended, failWrite, trusted: BOOLEAN;
    output: Mem.Channel; writer: Channel.Writer;
    reply: Core.Stanza; tracker: Track.Tracker; client: Client.Client
  END;
  Hook = POINTER TO HookDesc;
  HookDesc = RECORD (Client.HookDesc)
    ready, received, sent, errors, closed: LONGINT; last: Core.Stanza
  END;
  Observer = POINTER TO ObserverDesc;
  ObserverDesc = RECORD (Track.HookDesc)
    changes, notices, resets: LONGINT; applied, stopChange, stopPresence, forgetChange, repeatStop, tickChange: BOOLEAN;
    last: M.Occupant;
    leaveChange: Track.Room
  END;

VAR checks: LONGINT;

PROCEDURE Check(ok: BOOLEAN; name: ARRAY OF CHAR);
BEGIN
  IF ~ok THEN Out.String("MUC tracker check failed: "); Out.String(name); Out.Ln; HALT(1) END;
  INC(checks)
END Check;

PROCEDURE (t: Fake) AuthenticatedFor(domain: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN ~t.ended & t.trusted & (domain = "example.org") END AuthenticatedFor;
PROCEDURE (t: Fake) Read(VAR bytes: ARRAY OF CHAR; VAR count: LONGINT): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  count := S.Length8(t.script^)-t.position;
  IF count > t.chunk THEN count := t.chunk END; IF count > LEN(bytes) THEN count := LEN(bytes) END;
  FOR i := 0 TO count-1 DO bytes[i] := t.script[t.position+i] END;
  INC(t.position, count); RETURN ~t.ended
END Read;
PROCEDURE (t: Fake) WriteBytes(VAR bytes: ARRAY OF SYSTEM.BYTE; start, count: LONGINT);
  VAR stanza: Core.Stanza;
BEGIN
  IF t.failWrite THEN t.res := Wire.Error(); t.bytesWritten := 0; RETURN END;
  t.writer.WriteBytes(bytes, start, count); t.bytesWritten := t.writer.bytesWritten; t.res := t.writer.res;
  IF t.reply # NIL THEN
    stanza := t.reply; t.reply := NIL; t.tracker.Received(t.client, stanza)
  END
END WriteBytes;
PROCEDURE (t: Fake) Close;
BEGIN t.ended := TRUE END Close;
PROCEDURE (h: Hook) Ready(client: Client.Client; jid: T.String);
BEGIN INC(h.ready) END Ready;
PROCEDURE (h: Hook) Received(client: Client.Client; stanza: Core.Stanza);
BEGIN INC(h.received) END Received;
PROCEDURE (h: Hook) Sent(client: Client.Client; stanza: Core.Stanza);
BEGIN INC(h.sent); h.last := stanza END Sent;
PROCEDURE (h: Hook) Error(client: Client.Client; error: Msg.Msg);
BEGIN INC(h.errors) END Error;
PROCEDURE (h: Hook) Closed(client: Client.Client);
BEGIN INC(h.closed) END Closed;
PROCEDURE (h: Observer) Changed(tracker: Track.Tracker; room: Track.Room);
  VAR other: Track.Room; empty: T.String; error: Msg.Msg;
BEGIN
  INC(h.changes);
  IF h.stopChange THEN h.stopChange := FALSE; tracker.Stop END;
  IF h.forgetChange THEN h.forgetChange := FALSE; Check(tracker.Forget(room), "forgetting from a change callback") END;
  IF h.leaveChange # NIL THEN
    other := h.leaveChange; h.leaveChange := NIL; empty := Items.Latin1("");
    Check(tracker.Leave(other, empty^, 10, error), "starting another transition from a timeout callback")
  END;
  IF h.tickChange THEN h.tickChange := FALSE; tracker.Tick(1000) END
END Changed;
PROCEDURE (h: Observer) Presence(tracker: Track.Tracker; room: Track.Room; event: M.Occupant; applied: BOOLEAN);
BEGIN
  INC(h.notices); h.last := event; h.applied := applied;
  IF h.stopPresence THEN h.stopPresence := FALSE; tracker.Stop END
END Presence;
PROCEDURE (h: Observer) Reset(tracker: Track.Tracker);
BEGIN
  Check((tracker.count = 0) & (tracker.occupantCount = 0), "clearing state before reset callbacks"); INC(h.resets);
  IF h.repeatStop THEN h.repeatStop := FALSE; tracker.Stop END
END Reset;

PROCEDURE New(VAR t: Fake; VAR h: Hook; VAR tracker: Track.Tracker; VAR o: Observer): Client.Client;
  VAR c: Client.Client; router: IQ.Router; user, password, resource: T.String; error: Msg.Msg; state: SHORTINT;
BEGIN
  NEW(t); NEW(h); NEW(o); t.chunk := 8192; t.trusted := TRUE;
  t.script := Items.Copy8('<s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features><mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><mechanism>PLAIN</mechanism></mechanisms></s:features><success xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/><s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></s:features><iq id="voc-bind-1" type="result"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>user@example.org/r</jid></bind></iq>');
  t.output := Mem.Tmp("", {Mem.read, Mem.write}, error); ASSERT(error = NIL); t.writer := t.output.NewWriter();
  tracker := Track.New(h, o); ASSERT(tracker # NIL); router := IQ.New(tracker);
  user := Items.Latin1("user"); password := Items.Latin1("password"); resource := Items.Latin1("r");
  c := Client.New(t, router, "example.org", user^, password^, resource^, TRUE, error); ASSERT((c # NIL) & (error = NIL));
  ASSERT(c.Start()); REPEAT state := c.Step() UNTIL (state = Client.online) OR (state = Client.failed);
  Check((state = Client.online) & tracker.active & (h.ready = 1) & (o.resets = 1), "starting an online tracker");
  t.tracker := tracker; t.client := c; RETURN c
END New;

PROCEDURE Feed(c: Client.Client; t: Fake; xml: ARRAY OF CHAR);
  VAR state: SHORTINT; steps: LONGINT;
BEGIN
  t.script := Items.Copy8(xml); t.position := 0; steps := 0;
  REPEAT state := c.Step(); INC(steps); ASSERT(steps < 10000)
  UNTIL (t.position = S.Length8(t.script^)) OR (state = Client.failed);
  ASSERT(state # Client.failed)
END Feed;

PROCEDURE Dispose(c: Client.Client; t: Fake);
BEGIN t.tracker.Stop; c.Abort; t.output.Close END Dispose;

PROCEDURE Presence(c: Client.Client; t: Fake; attributes, children: ARRAY OF CHAR);
  VAR xml: Items.Bytes;
BEGIN
  NEW(xml, S.Length8(attributes)+S.Length8(children)+64); COPY('<presence ', xml^);
  Strings.Append(attributes, xml^); Strings.Append('>', xml^); Strings.Append(children, xml^);
  Strings.Append('</presence>', xml^); Feed(c, t, xml^)
END Presence;

PROCEDURE Packet(room: Track.Room; nick: ARRAY OF T.CodeUnit; unavailable: BOOLEAN; code: LONGINT): Core.Stanza;
  VAR stanza: Core.Stanza; address, value: T.String; x, item, status: Items.Item; number: ARRAY 16 OF CHAR;
BEGIN
  stanza := Core.NewStanza("presence"); address := M.OccupantJID(room.address^, nick); ASSERT(address # NIL);
  stanza.item.SetParam("from", address^);
  IF unavailable THEN value := Items.Latin1("unavailable"); stanza.item.SetParam("type", value^) END;
  x := Items.New("x", M.userURI); item := Items.New("item", M.userURI);
  value := Items.Latin1("member"); item.SetParam("affiliation", value^);
  IF unavailable THEN value := Items.Latin1("none") ELSE value := Items.Latin1("participant") END;
  item.SetParam("role", value^); x.AddChild(item);
  IF code # 0 THEN
    status := Items.New("status", M.userURI); IntStr.IntToStr(code, number); value := Items.Latin1(number);
    status.SetParam("code", value^); x.AddChild(status)
  END;
  stanza.item.AddChild(x); RETURN Core.Wrap(stanza.item, NIL)
END Packet;

PROCEDURE Join(tracker: Track.Tracker; timeoutMS: LONGINT): Track.Room;
  VAR address, nick, password: T.String; room: Track.Room; error: Msg.Msg;
BEGIN
  address := Items.Latin1("room@conference.example.org"); nick := Items.UTF8("Անի😀"); password := Items.Latin1("room-secret");
  room := tracker.Join(address^, nick^, password^, 0, timeoutMS, error);
  Check((room # NIL) & (error = NIL), "sending an explicit join"); RETURN room
END Join;

PROCEDURE Confirm(tracker: Track.Tracker; room: Track.Room);
BEGIN
  tracker.Received(tracker.client, Packet(room, room.nick^, FALSE, 110));
  Check((room.state = Track.joined) & (room.count = 1), "confirming self presence")
END Confirm;

PROCEDURE Lifecycle;
  VAR c: Client.Client; t: Fake; h: Hook; o: Observer; tracker: Track.Tracker; room: Track.Room;
    empty, nick, address: T.String; event: M.Occupant; error: Msg.Msg; notices, i: LONGINT;
BEGIN
  c := New(t, h, tracker, o); room := Join(tracker, 100); empty := Items.Latin1("");
  Check((room.state = Track.joining) & (tracker.count = 1) & (h.sent = 1), "waiting for self presence");
  Check(~tracker.Forget(room), "keeping pending joins tracked");
  notices := o.notices;
  Presence(c, t, 'from="room@elsewhere.example/Other"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="participant"/></x>');
  Presence(c, t, 'from="room@conference.example.org/Other" to="other@example.org"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="participant"/></x>');
  Presence(c, t, 'from="room@conference.example.org/Other" to=""', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="participant"/></x>');
  Check((o.notices = notices) & (room.count = 0), "ignoring other rooms and recipients");
  Presence(c, t, 'from="room@conference.example.org/Other" to="user@example.org"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="participant"/></x>');
  Check((room.state = Track.joining) & (room.count = 1) & o.applied, "tracking occupants before self confirmation");
  Presence(c, t, 'from="room@conference.example.org/Wrong"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="participant"/><status code="110"/></x>');
  Check((room.state = Track.joining) & (room.count = 1) & ~o.applied, "rejecting unexpected self identities");
  FOR i := 1 TO 110 DO
    t.chunk := i;
    Presence(c, t, 'from="room@CONFERENCE.example.org/Անի😀" to="user@example.org/r"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="participant"/><status code="110"/></x>');
    Check((room.state = Track.joined) & (room.count = 2) & (tracker.occupantCount = 2), "fragmented Unicode self presence")
  END;
  tracker.Tick(1000); Check(room.state = Track.joined, "ending the join deadline on confirmation");
  address := Items.Latin1("room@conference.example.org"); nick := Items.Latin1("Duplicate");
  Check(tracker.Join(address^, nick^, empty^, 0, 100, error) = NIL, "rejecting duplicate room joins");
  Check((tracker.Find(address^) = room) & (h.sent = 1), "finding the canonical room without sending twice");
  Presence(c, t, 'from="room@conference.example.org/Other"', '<show>away</show><x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="moderator"/></x>');
  nick := Items.Latin1("Other"); event := room.Find(nick^);
  Check((event # NIL) & S.Equal8(event.role^, "moderator") & S.Equal8(event.presence.show^, "away") & (room.count = 2), "updating occupant state");
  Presence(c, t, 'from="room@conference.example.org/Other" type="unavailable"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="participant" nick="Other2"/><status code="303"/></x>');
  Check((room.Find(nick^) = NIL) & (room.count = 1), "removing an old nickname before replacement presence");
  Presence(c, t, 'from="room@conference.example.org/Other2"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="participant"/></x>');
  nick := Items.UTF8("Նոր😀"); Check(tracker.Rename(room, nick^, 100, error), "requesting a nickname change");
  Check((room.state = Track.renaming) & S.Equal(room.wantedNick^, nick^) & (h.sent = 2), "waiting for nickname confirmation");
  Presence(c, t, 'from="room@conference.example.org/Անի😀"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="participant"/><status code="110"/></x>');
  Check(room.state = Track.renaming, "old self presence cannot confirm a new nickname");
  Presence(c, t, 'from="room@conference.example.org/Անի😀" type="unavailable"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="participant" nick="Նոր😀"/><status code="110"/><status code="303"/></x>');
  Check((room.state = Track.renaming) & S.Equal(room.nick^, nick^) & (room.count = 1), "sequencing the server nickname transition");
  Presence(c, t, 'from="room@conference.example.org/Նոր😀"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="participant"/><status code="110"/></x>');
  Check((room.state = Track.joined) & (room.count = 2), "confirming the replacement nickname");
  Check(tracker.Leave(room, empty^, 100, error), "requesting a departure");
  Check((room.state = Track.leaving) & ~tracker.Forget(room) & (h.sent = 3), "waiting for departure confirmation");
  Presence(c, t, 'from="room@conference.example.org/Նոր😀" type="unavailable"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="none"/></x>');
  Check((room.state = Track.left) & (room.count = 0) & (tracker.occupantCount = 0), "clearing a departed room");
  Check(tracker.Forget(room) & (tracker.count = 0) & (tracker.Find(address^) = NIL), "forgetting a confirmed departure");
  Check(~tracker.Forget(room), "rejecting an already forgotten room");
  Feed(c, t, '</s:stream>'); Check(~tracker.active & (h.closed = 1), "closing with the client"); t.output.Close
END Lifecycle;

PROCEDURE ErrorsAndDeadlines;
  VAR c: Client.Client; t: Fake; h: Hook; o: Observer; tracker: Track.Tracker; room: Track.Room;
    nick, empty: T.String; error: Msg.Msg;
BEGIN
  c := New(t, h, tracker, o); room := Join(tracker, 10); empty := Items.Latin1("");
  Presence(c, t, 'from="room@conference.example.org/Other" type="error"', '<error type="cancel"><conflict xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/></error>');
  Check((room.state = Track.joining) & ~o.applied, "unrelated occupant errors cannot cancel joins");
  Presence(c, t, 'from="room@conference.example.org" type="error"', '<error type="auth"><forbidden xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/></error>');
  Check((room.state = Track.failed) & ~room.expired & ~room.uncertain & (room.count = 0), "reporting explicit join errors");
  Check(tracker.Forget(room), "forgetting a rejected join"); room := Join(tracker, 10); Confirm(tracker, room);
  nick := Items.Latin1("New"); Check(tracker.Rename(room, nick^, 10, error), "starting a rejected rename");
  Presence(c, t, 'from="room@conference.example.org/New" type="error"', '<error type="cancel"><conflict xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/></error>');
  Check((room.state = Track.joined) & S.Equal(room.nick^, room.wantedNick^) & (room.count = 1), "keeping the confirmed nickname after rejection");
  Check(tracker.Leave(room, empty^, 10, error), "starting a rejected leave");
  Presence(c, t, 'from="room@conference.example.org" type="error"', '<error type="cancel"><not-allowed xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/></error>');
  Check((room.state = Track.joined) & (room.count = 1), "not claiming a rejected leave succeeded");
  Check(tracker.Rename(room, nick^, 10, error), "starting a rename timeout"); tracker.Tick(9);
  Check(room.state = Track.renaming, "keeping an unexpired transition"); tracker.Tick(1);
  Check((room.state = Track.failed) & room.expired & room.uncertain & (room.count = 0), "expiring uncertain nickname state");
  Check(~tracker.Forget(room), "blocking unsafe retries on a timed-out stream");
  tracker.Received(c, Packet(room, nick^, FALSE, 110)); Check((room.state = Track.failed) & (room.count = 0), "ignoring late self presence");
  Check((c.state = Client.online) & (h.errors = 0), "leaving unrelated client work online");
  Feed(c, t, '</s:stream>');
  Check((room.state = Track.disconnected) & ~tracker.active & (tracker.count = 0), "detaching expired state on disconnect"); t.output.Close;
  c := New(t, h, tracker, o); room := Join(tracker, 1); tracker.Tick(1);
  Check((room.state = Track.failed) & room.expired & ~tracker.Forget(room), "expiring unconfirmed joins");
  Dispose(c, t);
  c := New(t, h, tracker, o); room := Join(tracker, 10); Confirm(tracker, room);
  Check(tracker.Rename(room, nick^, 10, error), "starting an interrupted nickname switch");
  Presence(c, t, 'from="room@conference.example.org/Անի😀" type="unavailable"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="participant" nick="New"/><status code="110"/><status code="303"/></x>');
  Presence(c, t, 'from="room@conference.example.org/New" type="error"', '<error type="cancel"><conflict xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/></error>');
  Check((room.state = Track.failed) & room.uncertain & ~room.expired & ~tracker.Forget(room), "not restoring a nickname already removed by the room");
  Dispose(c, t)
END ErrorsAndDeadlines;

PROCEDURE AssignedAndRemoved;
  VAR c: Client.Client; t: Fake; h: Hook; o: Observer; tracker: Track.Tracker; room: Track.Room; nick: T.String;
BEGIN
  c := New(t, h, tracker, o); room := Join(tracker, 100);
  Presence(c, t, 'from="room@conference.example.org/Assigned"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="owner" role="moderator"/><status code="110"/><status code="210"/><status code="201"/></x>');
  Check((room.state = Track.joined) & room.created & S.Equal8(room.nick^, "Assigned"), "accepting an explicitly assigned nickname");
  Presence(c, t, 'from="room@conference.example.org/Assigned" type="unavailable"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="none" role="none"/><destroy><reason>Closed</reason></destroy></x>');
  Check((room.state = Track.left) & (room.count = 0) & o.last.destroyed, "clearing destroyed room state");
  Check(tracker.Forget(room), "forgetting a destroyed room"); room := Join(tracker, 100); Confirm(tracker, room);
  Presence(c, t, 'from="room@conference.example.org/Անի😀" type="unavailable"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="outcast" role="none"/><status code="301"/><status code="110"/></x>');
  Check((room.state = Track.left) & (tracker.occupantCount = 0) & o.last.HasStatus(301), "clearing kicked or banned membership");
  Check(tracker.Forget(room), "forgetting a removed membership"); room := Join(tracker, 100); Confirm(tracker, room);
  Presence(c, t, 'from="room@conference.example.org/Անի😀" type="unavailable"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="participant" nick="Server"/><status code="303"/></x>');
  Check((room.state = Track.renaming) & S.Equal8(room.nick^, "Server"), "tracking server-initiated nickname changes");
  tracker.Tick(Track.transitionTimeoutMS-1); Check(room.state = Track.renaming, "bounding server-initiated transitions");
  tracker.Received(c, Packet(room, room.nick^, FALSE, 110));
  tracker.Tick(Track.transitionTimeoutMS); Check(room.state = Track.joined, "confirming a server-initiated nickname change");
  Dispose(c, t)
END AssignedAndRemoved;

PROCEDURE Limits;
  VAR c: Client.Client; t: Fake; h: Hook; o: Observer; tracker: Track.Tracker; room, extra: Track.Room;
    address, nick, empty, text: T.String; error: Msg.Msg; stanza: Core.Stanza; status, x, item: Items.Item;
    i, accepted: LONGINT; number, raw: ARRAY 64 OF CHAR;
BEGIN
  c := New(t, h, tracker, o); empty := Items.Latin1(""); nick := Items.Latin1("Nick");
  Check(tracker.Join(empty^, nick^, empty^, 0, 100, error) = NIL, "rejecting an empty room");
  address := Items.Latin1("room@conference.example.org");
  Check(tracker.Join(address^, nick^, empty^, 0, 0, error) = NIL, "rejecting zero deadlines");
  Check(tracker.Join(address^, nick^, empty^, 0, IQ.maxTimeoutMS+1, error) = NIL, "rejecting oversized deadlines");
  FOR i := 0 TO Track.maxRooms DO
    raw := "room"; IntStr.IntToStr(i, number); Strings.Append(number, raw); Strings.Append("@conference.example.org", raw);
    address := Items.Latin1(raw); extra := tracker.Join(address^, nick^, empty^, 0, 100, error);
    IF i < Track.maxRooms THEN Check((extra # NIL) & (error = NIL), "room capacity")
    ELSE Check((extra = NIL) & (error.code = Track.capacity) & (tracker.count = Track.maxRooms), "room overflow") END
  END;
  Feed(c, t, '</s:stream>');
  Check((tracker.count = 0) & (tracker.occupantCount = 0), "clearing all rooms on disconnect"); t.output.Close;
  c := New(t, h, tracker, o); room := Join(tracker, 100); Confirm(tracker, room);
  FOR i := 1 TO Track.maxOccupants DO
    IntStr.IntToStr(i, raw); nick := Items.Latin1(raw); tracker.Received(c, Packet(room, nick^, FALSE, 0));
    IF i < Track.maxOccupants THEN Check(o.applied, "occupant capacity")
    ELSE Check(~o.applied & room.truncated & (room.count = Track.maxOccupants), "occupant overflow") END
  END;
  nick := Items.Latin1("1"); tracker.Received(c, Packet(room, nick^, FALSE, 0));
  Check(o.applied & (room.count = Track.maxOccupants), "updating occupants at capacity");
  tracker.Received(c, Packet(room, nick^, TRUE, 0));
  Check((room.Find(nick^) = NIL) & (room.count = Track.maxOccupants-1), "releasing occupant capacity");
  nick := Items.Latin1("extra"); tracker.Received(c, Packet(room, nick^, FALSE, 0)); Check(o.applied, "reusing released occupant capacity");
  Dispose(c, t);
  c := New(t, h, tracker, o); room := Join(tracker, 100); Confirm(tracker, room);
  NEW(text, P.maxStatusUnits+1); FOR i := 0 TO P.maxStatusUnits-1 DO text[i] := ORD("a") END; text[P.maxStatusUnits] := 0;
  accepted := 0; i := 0;
  REPEAT
    INC(i); IntStr.IntToStr(i, raw); nick := Items.Latin1(raw); stanza := Packet(room, nick^, FALSE, 0);
    status := Items.New("status", "jabber:client"); status.AddText(text^, 0, S.Length(text^)); stanza.item.AddChild(status);
    x := stanza.item.First(M.userURI, "x"); item := x.First(M.userURI, "item");
    status := Items.New("reason", M.userURI); status.AddText(text^, 0, S.Length(text^)); item.AddChild(status);
    tracker.Received(c, stanza); IF o.applied THEN INC(accepted) END
  UNTIL ~o.applied OR (i = Track.maxOccupants);
  Check((accepted > 0) & (accepted < Track.maxOccupants-1) & ~o.applied & room.truncated, "bounding total retained text");
  nick := Items.Latin1("1"); tracker.Received(c, Packet(room, nick^, FALSE, 0)); Check(o.applied, "releasing text budget on replacement");
  nick := Items.Latin1(raw); tracker.Received(c, Packet(room, nick^, FALSE, 0)); Check(o.applied, "reusing retained-text budget");
  Dispose(c, t)
END Limits;

PROCEDURE ReentryAndFailures;
  VAR c: Client.Client; t: Fake; h: Hook; o: Observer; tracker, fresh: Track.Tracker; room: Track.Room;
    nick, empty, address: T.String; error: Msg.Msg; notices, changes: LONGINT;
BEGIN
  c := New(t, h, tracker, o); o.stopChange := TRUE; room := Join(tracker, 100);
  Check(~tracker.active & (tracker.count = 0) & (room.state = Track.disconnected), "stopping from a join callback");
  Dispose(c, t);
  c := New(t, h, tracker, o); room := Join(tracker, 100); o.stopPresence := TRUE;
  tracker.Received(c, Packet(room, room.nick^, FALSE, 110));
  Check(~tracker.active & (room.count = 0) & (room.state = Track.disconnected), "stopping from an occupant callback");
  Dispose(c, t);
  c := New(t, h, tracker, o); room := Join(tracker, 100); Confirm(tracker, room); empty := Items.Latin1("");
  Check(tracker.Leave(room, empty^, 100, error), "leaving before a reentrant forget"); notices := o.notices; o.forgetChange := TRUE;
  tracker.Received(c, Packet(room, room.nick^, TRUE, 110));
  Check((tracker.count = 0) & (o.notices = notices), "not notifying a room removed by its state callback");
  o.repeatStop := TRUE; tracker.Stop; Check(~tracker.active & ~o.repeatStop, "guarding recursive stop callbacks");
  Dispose(c, t);
  c := New(t, h, tracker, o); room := Join(tracker, 100); Confirm(tracker, room);
  nick := Items.Latin1("Now"); changes := o.changes; t.reply := Packet(room, nick^, FALSE, 110);
  Check(tracker.Rename(room, nick^, 100, error), "sending a rename with a reentrant reply");
  Check((room.state = Track.joined) & (room.count = 1) & S.Equal8(room.nick^, "Now") &
    (o.changes = changes+1), "installing transition state before writing");
  fresh := Track.New(h, o); Check(~fresh.Rename(room, nick^, 100, error) & (error.code = Track.offline), "rejecting offline transitions");
  Dispose(c, t);
  c := New(t, h, tracker, o); t.failWrite := TRUE;
  address := Items.Latin1("room@conference.example.org"); nick := Items.Latin1("Nick");
  room := tracker.Join(address^, nick^, empty^, 0, 100, error);
  Check((room # NIL) & (error # NIL) & ~tracker.active & (room.state = Track.disconnected) &
    (tracker.count = 0) & (h.errors = 1), "cleaning state after synchronous write failure");
  Dispose(c, t);
  c := New(t, h, tracker, o); room := Join(tracker, 100); Confirm(tracker, room);
  t.script := Items.Copy8(""); t.position := 0;
  Check((c.Step() = Client.failed) & ~tracker.active & (room.state = Track.disconnected) &
    (tracker.count = 0) & (h.errors = 1), "clearing rooms after transport EOF");
  Dispose(c, t);
  c := New(t, h, tracker, o); room := Join(tracker, 100); Confirm(tracker, room);
  t.trusted := FALSE; nick := Items.Latin1("Blocked");
  Check(~tracker.Rename(room, nick^, 100, error) & (error # NIL) & ~tracker.active &
    (room.state = Track.disconnected) & (tracker.count = 0), "clearing transitions rejected before a write");
  Check(h.sent = 1, "not writing after transport identity is lost");
  Dispose(c, t)
END ReentryAndFailures;

PROCEDURE ReentrantDeadlines;
  VAR c: Client.Client; t: Fake; h: Hook; o: Observer; tracker: Track.Tracker;
    first, second: Track.Room; address, nick, empty: T.String; error: Msg.Msg;
BEGIN
  c := New(t, h, tracker, o); first := Join(tracker, 1);
  address := Items.Latin1("other@conference.example.org"); nick := Items.Latin1("Other"); empty := Items.Latin1("");
  second := tracker.Join(address^, nick^, empty^, 0, 100, error); ASSERT((second # NIL) & (error = NIL)); Confirm(tracker, second);
  o.leaveChange := second; o.tickChange := TRUE; tracker.Tick(1);
  Check((first.state = Track.failed) & (second.state = Track.leaving), "not aging a newly created deadline in the current tick");
  tracker.Tick(9); Check(second.state = Track.leaving, "preserving a reentrant transition's full deadline");
  tracker.Tick(1); Check((second.state = Track.failed) & second.expired, "expiring the replacement deadline exactly once");
  Dispose(c, t)
END ReentrantDeadlines;

BEGIN
  checks := 0; Lifecycle; ErrorsAndDeadlines; AssignedAndRemoved; Limits; ReentryAndFailures; ReentrantDeadlines;
  Out.String("XMPP room-state tracking checks passed: "); Out.Int(checks, 0); Out.Ln
END TestXmppMucTracker.
