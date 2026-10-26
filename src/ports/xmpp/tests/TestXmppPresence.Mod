MODULE TestXmppPresence;

IMPORT SYSTEM, Out, Msg, Channel, S := LongStrings, Strings := oocStrings, Mem := IOMemory,
  T := XmppTypes, Items := XmppItems, Wire := XmppWire, C := XmppClient,
  Core := XmppCore, IQ := XmppIQ, P := XmppPresence, Track := XmppPresenceTracker;

TYPE
  Fake = POINTER TO FakeDesc;
  FakeDesc = RECORD (Wire.TransportDesc)
    script: Items.Bytes; position, chunk: LONGINT; ended, failWrite: BOOLEAN;
    output: Mem.Channel; writer: Channel.Writer;
  END;
  Hook = POINTER TO HookDesc;
  HookDesc = RECORD (C.HookDesc) ready, received, sent, errors, closed: LONGINT END;
  Observer = POINTER TO ObserverDesc;
  ObserverDesc = RECORD (Track.HookDesc)
    notices, resets: LONGINT; applied, unwatch, stop: BOOLEAN; last: P.Event;
  END;

VAR checks: LONGINT;

PROCEDURE (t: Fake) AuthenticatedFor(domain: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN ~t.ended & (domain = "example.org") END AuthenticatedFor;
PROCEDURE (t: Fake) Read(VAR bytes: ARRAY OF CHAR; VAR count: LONGINT): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  count := S.Length8(t.script^)-t.position;
  IF count > t.chunk THEN count := t.chunk END; IF count > LEN(bytes) THEN count := LEN(bytes) END;
  FOR i := 0 TO count-1 DO bytes[i] := t.script[t.position+i] END;
  INC(t.position, count); RETURN ~t.ended
END Read;
PROCEDURE (t: Fake) WriteBytes(VAR bytes: ARRAY OF SYSTEM.BYTE; start, count: LONGINT);
BEGIN
  IF t.failWrite THEN t.res := Wire.Error(); t.bytesWritten := 0; RETURN END;
  t.writer.WriteBytes(bytes, start, count); t.bytesWritten := t.writer.bytesWritten; t.res := t.writer.res
END WriteBytes;
PROCEDURE (t: Fake) Close;
BEGIN t.ended := TRUE END Close;
PROCEDURE (h: Hook) Ready(client: C.Client; jid: T.String);
BEGIN INC(h.ready) END Ready;
PROCEDURE (h: Hook) Received(client: C.Client; stanza: Core.Stanza);
BEGIN INC(h.received) END Received;
PROCEDURE (h: Hook) Sent(client: C.Client; stanza: Core.Stanza);
BEGIN INC(h.sent) END Sent;
PROCEDURE (h: Hook) Error(client: C.Client; error: Msg.Msg);
BEGIN INC(h.errors) END Error;
PROCEDURE (h: Hook) Closed(client: C.Client);
BEGIN INC(h.closed) END Closed;
PROCEDURE (h: Observer) Notice(tracker: Track.Tracker; event: P.Event; applied: BOOLEAN);
  VAR ok: BOOLEAN;
BEGIN
  INC(h.notices); h.last := event; h.applied := applied;
  IF h.unwatch THEN h.unwatch := FALSE; ok := tracker.Unwatch(event.bare^); ASSERT(ok) END;
  IF h.stop THEN h.stop := FALSE; tracker.Stop END
END Notice;
PROCEDURE (h: Observer) Reset(tracker: Track.Tracker);
BEGIN ASSERT(tracker.count = 0); INC(h.resets) END Reset;

PROCEDURE New(VAR t: Fake; VAR h: Hook; VAR r: IQ.Router; VAR tracker: Track.Tracker; VAR o: Observer): C.Client;
  VAR c: C.Client; user, password, resource, jid: T.String; error: Msg.Msg; state: SHORTINT;
BEGIN
  NEW(t); NEW(h); NEW(o); t.chunk := 8192;
  t.script := Items.Copy8('<s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features><mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><mechanism>PLAIN</mechanism></mechanisms></s:features><success xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/><s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0" xml:lang="hy"><s:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></s:features><iq id="voc-bind-1" type="result"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>user@example.org/r</jid></bind></iq>');
  t.output := Mem.Tmp("", {Mem.read, Mem.write}, error); ASSERT(error = NIL); t.writer := t.output.NewWriter();
  tracker := Track.New(h, o); ASSERT(tracker # NIL); r := IQ.New(tracker);
  jid := Items.Latin1("friend@example.net"); ASSERT(tracker.Watch(jid^));
  jid := Items.UTF8("օբերոն@ծոց.հայ"); ASSERT(tracker.Watch(jid^));
  user := Items.Latin1("user"); password := Items.Latin1("password"); resource := Items.Latin1("r");
  c := C.New(t, r, "example.org", user^, password^, resource^, TRUE, error); ASSERT((c # NIL) & (error = NIL));
  ASSERT(c.Start()); REPEAT state := c.Step() UNTIL (state = C.online) OR (state = C.failed);
  ASSERT((state = C.online) & tracker.active & (h.ready = 1) & (o.resets = 1)); RETURN c
END New;

PROCEDURE Feed(c: C.Client; t: Fake; xml: ARRAY OF CHAR);
  VAR steps: LONGINT; state: SHORTINT;
BEGIN
  t.script := Items.Copy8(xml); t.position := 0; steps := 0;
  REPEAT state := c.Step(); INC(steps); ASSERT(steps < 10000)
  UNTIL (t.position = S.Length8(t.script^)) OR (state = C.failed);
  ASSERT(state # C.failed)
END Feed;

PROCEDURE Presence(c: C.Client; t: Fake; attributes, children: ARRAY OF CHAR);
  VAR xml: Items.Bytes;
BEGIN
  NEW(xml, S.Length8(attributes)+S.Length8(children)+64); COPY('<presence ', xml^);
  Strings.Append(attributes, xml^); Strings.Append('>', xml^); Strings.Append(children, xml^);
  Strings.Append('</presence>', xml^); Feed(c, t, xml^)
END Presence;

PROCEDURE Bad(c: C.Client; t: Fake; o: Observer; attributes, children: ARRAY OF CHAR);
  VAR notices: LONGINT;
BEGIN
  notices := o.notices; Presence(c, t, attributes, children); ASSERT(o.notices = notices); INC(checks)
END Bad;

PROCEDURE Builders;
  VAR to, show, status, empty: T.String; stanza: Core.Stanza; value: T.String; kind: SHORTINT; child: Items.Item;
BEGIN
  to := Items.UTF8("օբերոն@xn--cbbu1a.xn--y9a3aq/մուտք😀"); show := Items.Latin1("away"); status := Items.UTF8("Բարեւ 😀"); empty := Items.Latin1("");
  stanza := P.Available(to^, show^, status^, -128); ASSERT(stanza # NIL); value := Items.UTF8("օբերոն@ծոց.հայ/մուտք😀");
  ASSERT(S.Equal(stanza.to^, value^) & (stanza.item.GetAttribute("", "type") = NIL));
  child := stanza.item.First("jabber:client", "priority"); value := child.Text(); ASSERT(S.Equal8(value^, "-128")); INC(checks);
  stanza := P.Available(empty^, empty^, empty^, 127); ASSERT((stanza # NIL) & (stanza.item.GetAttribute("", "to") = NIL)); INC(checks);
  ASSERT(P.Available(empty^, empty^, empty^, 128) = NIL); ASSERT(P.Available(empty^, empty^, empty^, -129) = NIL);
  value := Items.Latin1("invalid"); ASSERT(P.Available(empty^, value^, empty^, 0) = NIL); INC(checks);
  stanza := P.Unavailable(empty^, status^); ASSERT((stanza # NIL) & S.Equal8(stanza.type^, "unavailable"));
  ASSERT((stanza.item.First("jabber:client", "show") = NIL) & (stanza.item.First("jabber:client", "priority") = NIL)); INC(checks);
  ASSERT(P.Subscription(to^, empty^, P.subscribe) = NIL); to := Items.UTF8("օբերոն@ծոց.հայ");
  FOR kind := P.subscribe TO P.unsubscribed DO
    stanza := P.Subscription(to^, status^, kind); ASSERT((stanza # NIL) & (stanza.type[0] # 0)); INC(checks)
  END;
  ASSERT(P.Subscription(empty^, status^, P.subscribe) = NIL); ASSERT(P.Subscription(to^, status^, P.available) = NIL); INC(checks);
  stanza := P.NewPresence(to^, status^); ASSERT((stanza # NIL) & S.Equal(stanza.to^, to^)); INC(checks)
END Builders;

PROCEDURE DecodingAndState;
  VAR c: C.Client; t: Fake; h: Hook; r: IQ.Router; tracker: Track.Tracker; o: Observer;
    event, old: P.Event; jid, expected: T.String; i, notices, raw: LONGINT;
BEGIN
  c := New(t, h, r, tracker, o);
  Presence(c, t, 'from="օբերոն@xn--cbbu1a.xn--y9a3aq/մուտք😀" to="user@example.org/r"',
    '<show>chat</show><status>Բարեւ 😀</status><status xml:lang="EN">Hello</status><priority> +00127 </priority><c xmlns="http://jabber.org/protocol/caps"/>');
  event := o.last; ASSERT(o.applied & (tracker.count = 1) & (event.priority = 127) & (event.statusCount = 2));
  expected := Items.UTF8("Բարեւ 😀"); ASSERT(S.Equal(event.status^, expected^) & S.Equal8(event.statuses[0].language^, "hy"));
  ASSERT(S.Equal8(event.statuses[1].language^, "en")); jid := Items.UTF8("օբերոն@ծոց.հայ/մուտք😀");
  ASSERT(tracker.Find(jid^) = event); INC(checks);
  old := event;
  Presence(c, t, 'from="օբերոն@ծոց.հայ/մուտք😀"', '<priority>-128</priority>');
  ASSERT((tracker.count = 1) & (o.last.priority = -128) & (old.priority = 127));
  ASSERT(tracker.Best(jid^) = NIL); INC(checks);
  Presence(c, t, 'from="օբերոն@ծոց.հայ/b"', ''); ASSERT(o.applied & (o.last.priority = 0));
  Presence(c, t, 'from="օբերոն@ծոց.հայ/a"', '<priority>0</priority>');
  expected := Items.UTF8("օբերոն@ծոց.հայ/a"); event := tracker.Best(jid^); ASSERT(S.Equal(event.from^, expected^)); INC(checks);
  Bad(c, t, o, 'from="friend@example.net/r" type=""', '');
  Bad(c, t, o, 'from="friend@example.net/r" type="available"', '');
  Bad(c, t, o, '', ''); Bad(c, t, o, 'from=""', ''); Bad(c, t, o, 'from="bad..example"', '');
  Bad(c, t, o, 'from="friend@example.net/r" to=""', '');
  Bad(c, t, o, 'from="friend@example.net/r" to="user@example.org/other"', '');
  Bad(c, t, o, 'from="friend@example.net/r" to="other@example.org"', '');
  Bad(c, t, o, 'from="friend@example.net/r"', '<show/>');
  Bad(c, t, o, 'from="friend@example.net/r"', '<show>online</show>');
  Bad(c, t, o, 'from="friend@example.net/r"', '<show>away</show><show>chat</show>');
  Bad(c, t, o, 'from="friend@example.net/r"', '<priority>128</priority>');
  Bad(c, t, o, 'from="friend@example.net/r"', '<priority>-129</priority>');
  Bad(c, t, o, 'from="friend@example.net/r"', '<priority>999999999999999999999999999999999999</priority>');
  Bad(c, t, o, 'from="friend@example.net/r"', '<priority>1.0</priority>');
  Bad(c, t, o, 'from="friend@example.net/r"', '<priority>+</priority>');
  Bad(c, t, o, 'from="friend@example.net/r"', '<priority>0</priority><priority>1</priority>');
  Bad(c, t, o, 'from="friend@example.net/r"', '<status><x/></status>');
  Bad(c, t, o, 'from="friend@example.net/r"', '<status>A</status><status xml:lang="HY">B</status>');
  Bad(c, t, o, 'from="friend@example.net/r"', '<status xml:lang="-en">A</status>');
  Bad(c, t, o, 'from="friend@example.net/r"', '<unknown/>');
  Bad(c, t, o, 'from="friend@example.net/r"', 'text');
  Bad(c, t, o, 'from="friend@example.net/r" type="error"', '');
  Bad(c, t, o, 'from="friend@example.net/r"', '<error type="cancel"><forbidden xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/></error>');
  raw := h.received;
  Presence(c, t, 'from="stranger@example.net/r" type="subscribe"', '<status>request</status>');
  ASSERT((o.last.kind = P.subscribe) & ~o.applied & (h.sent = 0) & (h.received = raw+1)); INC(checks);
  Presence(c, t, 'from="friend@example.net/r" type="subscribed"', ''); ASSERT((o.last.kind = P.subscribed) & ~o.applied); INC(checks);
  Presence(c, t, 'from="friend@example.net/r" type="error"', '<error type="cancel"><forbidden xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/></error>');
  ASSERT((o.last.kind = P.stanzaError) & (o.last.error # NIL) & ~o.applied); INC(checks);
  FOR i := 1 TO 110 DO
    t.chunk := i; notices := o.notices;
    Presence(c, t, 'from="friend@example.net/split"', '<show>away</show><status>Բարեւ 😀</status><priority>5</priority>');
    ASSERT((o.notices = notices+1) & o.applied); INC(checks)
  END;
  ASSERT(tracker.count = 4);
  Presence(c, t, 'from="օբերոն@ծոց.հայ/b" type="unavailable"', '<status>bye</status>'); ASSERT(tracker.count = 3); INC(checks);
  Presence(c, t, 'from="օբերոն@ծոց.հայ" type="unavailable"', ''); ASSERT((tracker.count = 1) & o.applied); INC(checks);
  jid := Items.Latin1("friend@example.net"); o.unwatch := TRUE;
  Presence(c, t, 'from="friend@example.net/split"', ''); ASSERT((tracker.count = 0) & (tracker.watchCount = 1)); INC(checks);
  ASSERT(tracker.Watch(jid^)); o.stop := TRUE; Presence(c, t, 'from="friend@example.net/split"', '');
  ASSERT(~tracker.active & (tracker.count = 0)); notices := o.notices;
  Presence(c, t, 'from="friend@example.net/split"', ''); ASSERT(o.notices = notices); INC(checks);
  r.Stop; c.Abort; t.output.Close
END DecodingAndState;

PROCEDURE Deliver(c: C.Client; r: IQ.Router; jid: ARRAY OF T.CodeUnit; status: T.String);
  VAR stanza: Core.Stanza; empty: T.String;
BEGIN
  empty := Items.Latin1(""); stanza := P.Available(empty^, empty^, status^, 0); ASSERT(stanza # NIL);
  stanza.item.SetParam("from", jid); stanza := Core.Wrap(stanza.item, NIL); r.Received(c, stanza)
END Deliver;

PROCEDURE LimitsAndClosure;
  VAR c: C.Client; t: Fake; h: Hook; r: IQ.Router; tracker: Track.Tracker; o: Observer;
    jid, status, empty: T.String; text: ARRAY 128 OF T.CodeUnit; i, j, count, notices: LONGINT;
    stanza: Core.Stanza; error: Msg.Msg;
BEGIN
  c := New(t, h, r, tracker, o); empty := Items.Latin1(""); jid := Items.Latin1("friend@example.net");
  ASSERT(tracker.Watch(jid^) & (tracker.watchCount = 2));
  jid := Items.Latin1("friend@example.net/r"); ASSERT(~tracker.Watch(jid^)); INC(checks);
  FOR i := 0 TO Track.maxResources-1 DO
    S.Long("friend@example.net/", text); text[19] := ORD("a")+i; text[20] := 0;
    Deliver(c, r, text, empty); ASSERT(o.applied)
  END;
  ASSERT(tracker.count = Track.maxResources); Deliver(c, r, text, empty); ASSERT(o.applied & (tracker.count = Track.maxResources)); INC(checks);
  jid := Items.Latin1("friend@example.net/overflow"); Deliver(c, r, jid^, empty); ASSERT(~o.applied & (tracker.count = Track.maxResources)); INC(checks);
  FOR i := 0 TO Track.maxContacts-3 DO
    S.Long("contact", text); text[7] := ORD("a")+i DIV 26; text[8] := ORD("a")+i MOD 26; text[9] := 0;
    S.Append8("@example.net", text); ASSERT(tracker.Watch(text))
  END;
  ASSERT(tracker.watchCount = Track.maxContacts); jid := Items.Latin1("overflow@example.net"); ASSERT(~tracker.Watch(jid^)); INC(checks);
  tracker.Clear; ASSERT((tracker.count = 0) & (tracker.watchCount = Track.maxContacts));
  FOR i := 0 TO Track.maxEntries DIV Track.maxResources-1 DO
    S.Long("contact", text); text[7] := ORD("a")+i DIV 26; text[8] := ORD("a")+i MOD 26; text[9] := 0;
    S.Append8("@example.net/", text); count := S.Length(text);
    FOR j := 0 TO Track.maxResources-1 DO text[count] := ORD("a")+j; text[count+1] := 0; Deliver(c, r, text, empty); ASSERT(o.applied) END
  END;
  ASSERT(tracker.count = Track.maxEntries); jid := Items.Latin1("friend@example.net/r"); Deliver(c, r, jid^, empty);
  ASSERT(~o.applied & (tracker.count = Track.maxEntries)); INC(checks);
  jid := Items.Latin1("contactaa@example.net/a"); ASSERT(tracker.Forget(jid^) & (tracker.count = Track.maxEntries-1));
  jid := Items.Latin1("contactaa@example.net"); ASSERT(tracker.Unwatch(jid^) & (tracker.count = Track.maxEntries-Track.maxResources)); INC(checks);
  notices := o.resets; Feed(c, t, '</s:stream>'); ASSERT((c.state = C.closed) & ~tracker.active & (tracker.count = 0));
  ASSERT((h.closed = 1) & (o.resets = notices+1)); t.output.Close; INC(checks);
  c := New(t, h, r, tracker, o); jid := Items.Latin1("friend@example.net/r"); Deliver(c, r, jid^, empty);
  t.failWrite := TRUE; stanza := P.Available(empty^, empty^, empty^, 0); c.Send(stanza, error);
  ASSERT((error # NIL) & (h.errors = 1) & ~tracker.active & (tracker.count = 0));
  r.Stop; c.Abort; t.output.Close; INC(checks);
  c := New(t, h, r, tracker, o); NEW(status, P.maxStatusUnits+2);
  FOR i := 0 TO P.maxStatusUnits DO status[i] := ORD("a") END; status[P.maxStatusUnits+1] := 0;
  ASSERT(P.Available(empty^, empty^, status^, 0) = NIL); status[P.maxStatusUnits] := 0;
  ASSERT(P.Available(empty^, empty^, status^, 0) # NIL); INC(checks);
  tracker.Stop; r.Stop; c.Abort; t.output.Close
END LimitsAndClosure;

PROCEDURE TextBudgets;
  VAR c: C.Client; t: Fake; h: Hook; r: IQ.Router; tracker: Track.Tracker; o: Observer;
    jid, status, lang, empty: T.String; text: ARRAY IQ.maxJIDUnits+1 OF T.CodeUnit;
    stanza: Core.Stanza; child: Items.Item; i, j, notices: LONGINT;
BEGIN
  c := New(t, h, r, tracker, o); empty := Items.Latin1(""); NEW(status, P.maxStatusUnits+1);
  FOR i := 0 TO P.maxStatusUnits-1 DO status[i] := ORD("a") END; status[P.maxStatusUnits] := 0;
  jid := Items.Latin1("other@example.net"); ASSERT(tracker.Watch(jid^));
  FOR i := 0 TO 31 DO
    IF i < 16 THEN S.Long("friend@example.net/", text) ELSE S.Long("other@example.net/", text) END;
    j := S.Length(text); text[j] := ORD("a")+i MOD 16; text[j+1] := 0;
    stanza := P.Available(empty^, empty^, status^, 0); stanza.item.SetParam("from", text);
    child := Items.New("status", "jabber:client"); lang := Items.Latin1("en");
    jid := Items.Latin1("lang"); child.SetAttribute(jid^, Core.xmlURI, lang^);
    child.AddText(status^, 0, S.Length(status^)); stanza.item.AddChild(child);
    stanza := Core.Wrap(stanza.item, NIL); r.Received(c, stanza);
    IF i < 31 THEN ASSERT(o.applied) ELSE ASSERT(~o.applied) END
  END;
  ASSERT(tracker.count = 31); jid := Items.Latin1("friend@example.net/a"); ASSERT(tracker.Forget(jid^));
  r.Received(c, stanza); ASSERT(o.applied & (tracker.count = 31)); INC(checks);
  child := Items.New("status", "jabber:client"); lang := Items.Latin1("hy");
  jid := Items.Latin1("lang"); child.SetAttribute(jid^, Core.xmlURI, lang^);
  child.AddText(status^, 0, 1); stanza.item.AddChild(child); notices := o.notices;
  r.Received(c, stanza); ASSERT(o.notices = notices); INC(checks);
  stanza := Core.NewStanza("presence"); jid := Items.Latin1("friend@example.net/a"); stanza.item.SetParam("from", jid^);
  FOR i := 0 TO P.maxStatuses DO
    child := Items.New("status", "jabber:client"); text[0] := ORD("a")+i; text[1] := 0;
    jid := Items.Latin1("lang"); child.SetAttribute(jid^, Core.xmlURI, text); stanza.item.AddChild(child);
    IF i = P.maxStatuses-1 THEN ASSERT(P.Read(Core.Wrap(stanza.item, NIL)) # NIL) END
  END;
  ASSERT(P.Read(Core.Wrap(stanza.item, NIL)) = NIL); INC(checks);
  tracker.Stop; r.Stop; c.Abort; t.output.Close;
  c := New(t, h, r, tracker, o);
  FOR j := 0 TO 1022 DO text[j] := ORD("a") END; text[1023] := 0; S.Append8("@example.net", text);
  i := 0;
  LOOP
    text[0] := ORD("a")+i DIV 26; text[1] := ORD("a")+i MOD 26;
    IF ~tracker.Watch(text) THEN EXIT END;
    INC(i); ASSERT(i < Track.maxContacts)
  END;
  ASSERT((i > 1) & (tracker.watchCount < Track.maxContacts)); INC(checks);
  tracker.Stop; r.Stop; c.Abort; t.output.Close
END TextBudgets;

BEGIN
  checks := 0; Builders; DecodingAndState; LimitsAndClosure; TextBudgets;
  Out.String("XMPP presence and resource-tracking checks passed: "); Out.Int(checks, 0); Out.Ln
END TestXmppPresence.
