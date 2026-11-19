MODULE TestXmppRosterPubSub;

IMPORT SYSTEM, Out, Msg, Channel, S := LongStrings, Strings := oocStrings, Mem := IOMemory,
  T := XmppTypes, Items := XmppItems, Wire := XmppWire, C := XmppClient,
  Core := XmppCore, IQ := XmppIQ, Roster := XmppRoster, PubSub := XmppPubSub,
  RSM := XmppRSM, XML := XmppXmlGen;

TYPE
  Fake = POINTER TO FakeDesc;
  FakeDesc = RECORD (Wire.TransportDesc)
    script: Items.Bytes; position, chunk: LONGINT; ended, failWrite: BOOLEAN;
    output: Mem.Channel; writer: Channel.Writer;
  END;
  Hook = POINTER TO HookDesc;
  HookDesc = RECORD (C.HookDesc) sent: LONGINT; last: Core.Stanza END;
  RosterHook = POINTER TO RosterHookDesc;
  RosterHookDesc = RECORD (Roster.HookDesc)
    loads, changes: LONGINT; accepted, chain: BOOLEAN; next: IQ.Request;
  END;
  Action = POINTER TO ActionDesc;
  ActionDesc = RECORD (IQ.ActionDesc) calls: LONGINT END;

VAR checks: LONGINT;

PROCEDURE Check(value: BOOLEAN; message: ARRAY OF CHAR);
BEGIN
  INC(checks);
  IF ~value THEN
    Out.String("TestXmppRosterPubSub: "); Out.String(message); Out.Ln; HALT(100)
  END
END Check;

PROCEDURE (t: Fake) AuthenticatedFor(domain: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN ~t.ended & (domain = "example.org") END AuthenticatedFor;
PROCEDURE (t: Fake) Read(VAR bytes: ARRAY OF CHAR; VAR count: LONGINT): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  count := S.Length8(t.script^)-t.position;
  IF count > t.chunk THEN count := t.chunk END;
  IF count > LEN(bytes) THEN count := LEN(bytes) END;
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
PROCEDURE (h: Hook) Sent(client: C.Client; stanza: Core.Stanza);
BEGIN INC(h.sent); h.last := stanza END Sent;
PROCEDURE (a: Action) Done(router: IQ.Router; request: IQ.Request);
BEGIN INC(a.calls) END Done;
PROCEDURE (h: RosterHook) Loaded(roster: Roster.Roster; request: IQ.Request; accepted: BOOLEAN);
  VAR error: Msg.Msg;
BEGIN
  INC(h.loads); h.accepted := accepted;
  IF h.chain THEN h.chain := FALSE; h.next := roster.Fetch(10, error); ASSERT(error = NIL) END
END Loaded;
PROCEDURE (h: RosterHook) Changed(roster: Roster.Roster; entry: Roster.Entry);
BEGIN INC(h.changes) END Changed;

PROCEDURE New(VAR t: Fake; VAR h: Hook; VAR r: IQ.Router; VAR roster: Roster.Roster; VAR rh: RosterHook): C.Client;
  VAR c: C.Client; user, password, resource: T.String; error: Msg.Msg; state: SHORTINT;
BEGIN
  NEW(t); NEW(h); NEW(rh); t.chunk := 8192;
  t.script := Items.Copy8('<s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features><mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><mechanism>PLAIN</mechanism></mechanisms></s:features><success xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/><s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></s:features><iq id="voc-bind-1" type="result"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>user@example.org/r</jid></bind></iq>');
  t.output := Mem.Tmp("", {Mem.read, Mem.write}, error); ASSERT(error = NIL); t.writer := t.output.NewWriter();
  r := IQ.New(h); roster := Roster.New(r, rh); ASSERT(roster # NIL);
  user := Items.Latin1("user"); password := Items.Latin1("password"); resource := Items.Latin1("r");
  c := C.New(t, r, "example.org", user^, password^, resource^, TRUE, error); ASSERT((c # NIL) & (error = NIL));
  ASSERT(c.Start()); REPEAT state := c.Step() UNTIL (state = C.online) OR (state = C.failed);
  ASSERT(state = C.online); RETURN c
END New;

PROCEDURE Feed(c: C.Client; t: Fake; text: ARRAY OF CHAR);
  VAR state: SHORTINT; steps: LONGINT;
BEGIN
  t.script := Items.Copy8(text); t.position := 0; steps := 0;
  REPEAT state := c.Step(); INC(steps); ASSERT(steps < 10000)
  UNTIL (t.position = S.Length8(t.script^)) OR (state = C.failed);
  ASSERT(state # C.failed)
END Feed;

PROCEDURE Reply(c: C.Client; t: Fake; request: IQ.Request; attributes, content: ARRAY OF CHAR);
  VAR xml, bytes: Items.Bytes;
BEGIN
  NEW(xml, S.Length8(attributes)+S.Length8(content)+256); bytes := Items.UTF8Bytes(request.id^);
  COPY('<iq id="', xml^); Strings.Append(bytes^, xml^); Strings.Append('" ', xml^);
  Strings.Append(attributes, xml^); Strings.Append('>', xml^); Strings.Append(content, xml^);
  Strings.Append('</iq>', xml^); Feed(c, t, xml^)
END Reply;

PROCEDURE Push(c: C.Client; t: Fake; attributes, content: ARRAY OF CHAR);
  VAR xml: Items.Bytes;
BEGIN
  NEW(xml, S.Length8(attributes)+S.Length8(content)+256); COPY('<iq type="set" id="push" ', xml^);
  Strings.Append(attributes, xml^); Strings.Append('><query xmlns="jabber:iq:roster">', xml^);
  Strings.Append(content, xml^); Strings.Append('</query></iq>', xml^); Feed(c, t, xml^)
END Push;

PROCEDURE Condition(h: Hook; condition: ARRAY OF CHAR);
  VAR error: Items.Item;
BEGIN
  ASSERT(S.Equal8(h.last.type^, "error")); error := h.last.item.First("jabber:client", "error");
  ASSERT((error # NIL) & (error.First("urn:ietf:params:xml:ns:xmpp-stanzas", condition) # NIL)); INC(checks)
END Condition;

PROCEDURE Rosters;
  VAR c: C.Client; t: Fake; h: Hook; r: IQ.Router; roster: Roster.Roster; rh: RosterHook;
    request, duplicate: IQ.Request; error: Msg.Msg; e: Roster.Entry; text, jid, name: T.String;
    before: Roster.Snapshot; sent, i: LONGINT; groups: ARRAY 2 OF T.String; a: Action; query, item: Items.Item;
BEGIN
  c := New(t, h, r, roster, rh); ASSERT(~roster.complete & (roster.snapshot.count = 0));
  request := roster.Fetch(100, error); ASSERT((error = NIL) & (request # NIL));
  duplicate := roster.Fetch(100, error); ASSERT((duplicate = NIL) & (error.code = IQ.invalidRequest)); INC(checks);
  Reply(c, t, request, 'type="result"', '<query xmlns="jabber:iq:roster"><item jid="օբերոն@xn--cbbu1a.xn--y9a3aq" name="Հայերեն😀" subscription="both" ask="subscribe" approved="true"><group>Ընկերներ</group><group>Work</group></item></query>');
  ASSERT(rh.accepted & (rh.loads = 1) & roster.complete & (roster.snapshot.count = 1));
  jid := Items.UTF8("օբերոն@ծոց.հայ"); e := roster.Find(jid^); ASSERT((e # NIL) & (e.subscription = Roster.both));
  text := Items.UTF8("Հայերեն😀"); ASSERT(S.Equal(e.name^, text^) & e.pending & e.approved & (e.groupCount = 2)); INC(checks);
  before := roster.snapshot; sent := h.sent;
  Push(c, t, 'from="attacker@example.net"', '<item jid="victim@example.net"/>');
  Push(c, t, 'from="example.org"', '<item jid="victim@example.net"/>');
  Push(c, t, 'from="user@example.org/r"', '<item jid="victim@example.net"/>');
  Push(c, t, 'from="user@example.org/other"', '<item jid="victim@example.net"/>');
  Push(c, t, 'from=""', '<item jid="victim@example.net"/>');
  Push(c, t, 'from="attacker@example.net"', '<item/><item/>');
  ASSERT((h.sent = sent) & (rh.changes = 0) & (roster.snapshot = before)); INC(checks);
  Push(c, t, 'from="user@EXAMPLE.org" to="user@example.org/r"', '<item jid="օբերոն@ծոց.հայ" name="New" subscription="to"/>');
  ASSERT((rh.changes = 1) & S.Equal8(h.last.type^, "result") & (roster.snapshot.count = 1));
  ASSERT((before.entries[0] = e) & (roster.Find(jid^) # e)); INC(checks);
  Push(c, t, '', '<item jid="new@example.net"/>'); ASSERT((rh.changes = 2) & (roster.snapshot.count = 2)); INC(checks);
  before := roster.snapshot;
  Push(c, t, '', ''); Condition(h, "bad-request");
  Push(c, t, '', '<item jid="a@example.net"/><item jid="b@example.net"/>'); Condition(h, "bad-request");
  Push(c, t, '', '<item jid="a@example.net/r"/>'); Condition(h, "bad-request");
  Push(c, t, '', '<item jid="bad..example"/>'); Condition(h, "bad-request");
  Push(c, t, '', '<item jid="a@example.net" subscription="invalid"/>'); Condition(h, "bad-request");
  Push(c, t, '', '<item jid="a@example.net" ask="other"/>'); Condition(h, "bad-request");
  Push(c, t, '', '<item jid="a@example.net" approved="yes"/>'); Condition(h, "bad-request");
  Push(c, t, '', '<item jid="a@example.net"><group>A</group><group>A</group></item>'); Condition(h, "bad-request");
  Push(c, t, '', '<item jid="a@example.net"><group><x/></group></item>'); Condition(h, "bad-request");
  Push(c, t, '', '<item jid="a@example.net">text</item>'); Condition(h, "bad-request");
  ASSERT(roster.snapshot = before); INC(checks);
  request := roster.Fetch(100, error);
  Reply(c, t, request, 'type="result"', '<query xmlns="jabber:iq:roster"><item jid="dup@EXAMPLE.net"/><item jid="dup@example.net"/></query>');
  ASSERT(~rh.accepted & (roster.snapshot = before)); INC(checks);
  request := roster.Fetch(100, error);
  Reply(c, t, request, 'type="result"', '<query xmlns="jabber:iq:roster"><item jid="a@example.net" subscription="remove"/></query>');
  ASSERT(~rh.accepted & (roster.snapshot = before)); INC(checks);
  request := roster.Fetch(100, error); Push(c, t, '', '<item jid="new@example.net" subscription="remove"/>');
  before := roster.snapshot; ASSERT(before.count = 1);
  Reply(c, t, request, 'type="result"', '<query xmlns="jabber:iq:roster"/>');
  ASSERT(~rh.accepted & (roster.snapshot = before)); INC(checks);
  request := roster.Fetch(100, error); rh.chain := TRUE;
  Reply(c, t, request, 'type="result"', '<query xmlns="jabber:iq:roster"/>');
  ASSERT(rh.accepted & (roster.snapshot.count = 0) & (rh.next # NIL));
  r.Tick(10); ASSERT((rh.next.status = IQ.timedOut) & ~rh.accepted); INC(checks);
  jid := Items.UTF8("օբերոն@xn--cbbu1a.xn--y9a3aq"); name := Items.UTF8("Հայերեն😀");
  groups[0] := Items.UTF8("Ընկերներ"); groups[1] := Items.Latin1("Work"); NEW(a);
  request := Roster.Set(r, jid^, name^, groups, FALSE, 100, a, error); ASSERT((request # NIL) & (error = NIL));
  item := request.payload.First(Roster.namespaceURI, "item"); text := item.GetAttribute("", "jid");
  jid := Items.UTF8("օբերոն@ծոց.հայ"); ASSERT(S.Equal(text^, jid^) & (item.GetAttribute("", "subscription") = NIL));
  Reply(c, t, request, 'type="result"', ''); ASSERT(IQ.EmptyResult(request) & (a.calls = 1)); INC(checks);
  query := Roster.BuildSet(jid^, name^, groups, TRUE); item := query.First(Roster.namespaceURI, "item");
  text := item.GetAttribute("", "subscription"); ASSERT(S.Equal8(text^, "remove") & (item.content = NIL)); INC(checks);
  groups[1] := groups[0]; ASSERT(Roster.BuildSet(jid^, name^, groups, FALSE) = NIL); INC(checks);
  (* Every split point keeps authenticated pushes and acknowledgements singular. *)
  FOR i := 1 TO 110 DO
    t.chunk := i; sent := rh.changes; Push(c, t, '', '<item jid="split@example.net"/>');
    ASSERT((rh.changes = sent+1) & S.Equal8(h.last.type^, "result")); INC(checks)
  END;
  request := roster.Fetch(100, error); r.Stop; ASSERT((request.status = IQ.cancelled) & ~rh.accepted);
  c.Abort; t.output.Close; INC(checks);
  c := New(t, h, r, roster, rh); t.failWrite := TRUE; request := roster.Fetch(100, error);
  ASSERT((error # NIL) & (request.status = IQ.sendFailed) & (rh.loads = 1) & ~rh.accepted);
  t.output.Close; INC(checks)
END Rosters;

PROCEDURE Boundaries;
  VAR c: C.Client; t: Fake; h: Hook; r: IQ.Router; roster: Roster.Roster; rh: RosterHook;
    request: IQ.Request; error: Msg.Msg; query, item, group: Items.Item; stanza: Core.Stanza;
    jid, name: T.String; number: ARRAY 32 OF T.CodeUnit; i, j: LONGINT; before: Roster.Snapshot;
    groups: ARRAY Roster.maxGroups+1 OF T.String;
BEGIN
  c := New(t, h, r, roster, rh); request := roster.Fetch(100, error); query := Items.New("query", Roster.namespaceURI);
  FOR i := 0 TO Roster.maxItems-1 DO
    item := Items.New("item", Roster.namespaceURI); S.Long("u", number); number[1] := ORD("a")+i DIV 26;
    number[2] := ORD("a")+i MOD 26; number[3] := 0; S.Append8("@example.net", number);
    item.SetParam("jid", number); query.AddChild(item)
  END;
  stanza := IQ.Response(h.last, query); r.Received(c, stanza);
  ASSERT(rh.accepted & (roster.snapshot.count = Roster.maxItems)); INC(checks);
  before := roster.snapshot; Push(c, t, '', '<item jid="overflow@example.net"/>'); Condition(h, "resource-constraint");
  ASSERT(roster.snapshot = before); INC(checks);
  request := roster.Fetch(100, error); query := Items.New("query", Roster.namespaceURI);
  FOR i := 0 TO Roster.maxItems DO
    item := Items.New("item", Roster.namespaceURI); S.Long("u", number); number[1] := ORD("a")+i DIV 26;
    number[2] := ORD("a")+i MOD 26; number[3] := 0; S.Append8("@example.net", number);
    item.SetParam("jid", number); query.AddChild(item)
  END;
  stanza := IQ.Response(h.last, query); r.Received(c, stanza);
  ASSERT(~rh.accepted & (roster.snapshot = before)); INC(checks);
  item := Items.New("item", Roster.namespaceURI); jid := Items.Latin1("a@example.net"); item.SetParam("jid", jid^);
  FOR i := 0 TO Roster.maxGroups DO
    group := Items.New("group", Roster.namespaceURI); number[0] := ORD("a")+i; number[1] := 0;
    groups[i] := Items.Copy16(number); group.AddText(number, 0, 1); item.AddChild(group);
    IF i = Roster.maxGroups-1 THEN ASSERT(Roster.ReadEntry(item, FALSE) # NIL); INC(checks) END
  END;
  ASSERT(Roster.ReadEntry(item, FALSE) = NIL); ASSERT(Roster.BuildSet(jid^, jid^, groups, FALSE) = NIL); INC(checks);
  item := Items.New("item", Roster.namespaceURI); item.SetParam("jid", jid^);
  NEW(jid, Roster.maxValueUnits+2); FOR j := 0 TO Roster.maxValueUnits DO jid[j] := ORD("a") END;
  jid[Roster.maxValueUnits+1] := 0; item.SetParam("name", jid^);
  ASSERT(Roster.ReadEntry(item, FALSE) = NIL); INC(checks);
  (* A full snapshot's aggregate retained text has its own bound. *)
  NEW(name, Roster.maxValueUnits+1);
  FOR j := 0 TO Roster.maxValueUnits-1 DO name[j] := ORD("a") END; name[Roster.maxValueUnits] := 0;
  request := roster.Fetch(100, error); query := Items.New("query", Roster.namespaceURI);
  FOR i := 0 TO Roster.maxItems-1 DO
    item := Items.New("item", Roster.namespaceURI); S.Long("u", number); number[1] := ORD("a")+i DIV 26;
    number[2] := ORD("a")+i MOD 26; number[3] := 0; S.Append8("@example.net", number);
    item.SetParam("jid", number); item.SetParam("name", name^); query.AddChild(item)
  END;
  stanza := IQ.Response(h.last, query); r.Received(c, stanza);
  ASSERT(~rh.accepted & (roster.snapshot = before)); INC(checks);
  request := roster.Fetch(100, error); query := Items.New("query", Roster.namespaceURI);
  FOR i := 0 TO Roster.maxItems-9 DO
    item := Items.New("item", Roster.namespaceURI); S.Long("u", number); number[1] := ORD("a")+i DIV 26;
    number[2] := ORD("a")+i MOD 26; number[3] := 0; S.Append8("@example.net", number);
    item.SetParam("jid", number); item.SetParam("name", name^); query.AddChild(item)
  END;
  stanza := IQ.Response(h.last, query); r.Received(c, stanza);
  ASSERT(rh.accepted & (roster.snapshot.count = Roster.maxItems-8)); before := roster.snapshot; INC(checks);
  query := Items.New("query", Roster.namespaceURI); item := Items.New("item", Roster.namespaceURI);
  jid := Items.Latin1("uaa@example.net"); item.SetParam("jid", jid^); item.SetParam("name", name^); query.AddChild(item);
  FOR i := 0 TO 7 DO
    group := Items.New("group", Roster.namespaceURI); name[0] := ORD("a")+i;
    group.AddText(name^, 0, S.Length(name^)); item.AddChild(group)
  END;
  stanza := Core.NewStanza("iq"); jid := Items.Latin1("push-limit"); stanza.item.SetParam("id", jid^);
  jid := Items.Latin1("set"); stanza.item.SetParam("type", jid^); stanza.item.AddChild(query);
  stanza := Core.Wrap(stanza.item, NIL); r.Received(c, stanza); Condition(h, "resource-constraint");
  ASSERT(roster.snapshot = before); INC(checks);
  r.Stop; c.Abort; t.output.Close
END Boundaries;

PROCEDURE PubSubs;
  VAR c: C.Client; t: Fake; h: Hook; r: IQ.Router; roster: Roster.Roster; rh: RosterHook;
    request: IQ.Request; a: Action; error: Msg.Msg; peer, node, id, empty: T.String; payload: Items.Item;
BEGIN
  c := New(t, h, r, roster, rh); NEW(a); peer := Items.Latin1("user@example.org");
  node := Items.Latin1("urn:xmpp:microblog:0"); id := Items.UTF8("Հայերեն😀"); empty := Items.Latin1("");
  request := PubSub.Publish(r, peer^, node^, id^, Items.New("entry", "http://www.w3.org/2005/Atom"), 100, a, error);
  ASSERT(error = NIL); Reply(c, t, request, 'type="result"', ''); ASSERT(PubSub.Published(request)); INC(checks);
  request := PubSub.Publish(r, peer^, node^, id^, Items.New("entry", "http://www.w3.org/2005/Atom"), 100, a, error);
  Reply(c, t, request, 'type="result"', '<pubsub xmlns="http://jabber.org/protocol/pubsub"><publish node="urn:xmpp:microblog:0"><item id="Հայերեն😀"/></publish></pubsub>');
  ASSERT(PubSub.Published(request)); INC(checks);
  request := PubSub.Publish(r, peer^, node^, id^, Items.New("entry", "http://www.w3.org/2005/Atom"), 100, a, error);
  Reply(c, t, request, 'type="result"', '<pubsub xmlns="http://jabber.org/protocol/pubsub"><publish node="wrong"><item id="Հայերեն😀"/></publish></pubsub>');
  ASSERT(~PubSub.Published(request)); INC(checks);
  request := PubSub.Publish(r, peer^, node^, id^, Items.New("entry", "http://www.w3.org/2005/Atom"), 100, a, error);
  Reply(c, t, request, 'type="result"', '<pubsub xmlns="http://jabber.org/protocol/pubsub"><publish node="urn:xmpp:microblog:0"><item id="wrong"/></publish></pubsub>');
  ASSERT(~PubSub.Published(request)); INC(checks);
  request := PubSub.Fetch(r, peer^, node^, id^, 1, 100, a, error);
  Reply(c, t, request, 'type="result"', '<pubsub xmlns="http://jabber.org/protocol/pubsub"><items node="urn:xmpp:microblog:0"><item id="Հայերեն😀"><entry xmlns="http://www.w3.org/2005/Atom"/></item></items></pubsub>');
  ASSERT(PubSub.ReadItems(request) # NIL); INC(checks);
  request := PubSub.Fetch(r, peer^, node^, id^, 1, 100, a, error);
  Reply(c, t, request, 'type="result"', '<pubsub xmlns="http://jabber.org/protocol/pubsub"><items node="urn:xmpp:microblog:0"><item id="wrong"><x/></item></items></pubsub>');
  ASSERT(PubSub.ReadItems(request) = NIL); INC(checks);
  request := PubSub.Fetch(r, peer^, node^, empty^, 2, 100, a, error);
  Reply(c, t, request, 'type="result"', '<pubsub xmlns="http://jabber.org/protocol/pubsub"><items node="urn:xmpp:microblog:0"><item id="same"><x/></item><item id="same"><x/></item></items></pubsub>');
  ASSERT(PubSub.ReadItems(request) = NIL); INC(checks);
  request := PubSub.Fetch(r, peer^, node^, empty^, 1, 100, a, error);
  Reply(c, t, request, 'type="result"', '<pubsub xmlns="http://jabber.org/protocol/pubsub"><items node="urn:xmpp:microblog:0"><item id="one"><x/></item><item id="two"><x/></item></items></pubsub>');
  ASSERT(PubSub.ReadItems(request) = NIL); INC(checks);
  request := PubSub.Fetch(r, peer^, node^, empty^, 1, 100, a, error);
  Reply(c, t, request, 'type="result"', '<pubsub xmlns="http://jabber.org/protocol/pubsub"><items node="urn:xmpp:microblog:0"><item id="one"><x/><y/></item></items></pubsub>');
  ASSERT(PubSub.ReadItems(request) = NIL); INC(checks);
  request := PubSub.Fetch(r, peer^, node^, empty^, 1, 100, a, error);
  Reply(c, t, request, 'type="result"', '<pubsub xmlns="http://jabber.org/protocol/pubsub"><items node="urn:xmpp:microblog:0"/></pubsub>');
  ASSERT(PubSub.ReadItems(request) # NIL); INC(checks);
  request := PubSub.Retract(r, peer^, node^, id^, TRUE, 100, a, error);
  Reply(c, t, request, 'type="result"', ''); ASSERT(PubSub.Retracted(request) & ~PubSub.Published(request)); INC(checks);
  ASSERT(PubSub.BuildItems(node^, id^, 0) = NIL); ASSERT(PubSub.BuildItems(node^, id^, PubSub.maxItems+1) = NIL);
  ASSERT(PubSub.BuildPublish(empty^, id^, Items.New("x", "test")) = NIL);
  payload := Items.New("x", "test"); payload.AddChild(Items.New("y", "test"));
  ASSERT(PubSub.BuildPublish(node^, id^, payload.First("test", "y")) = NIL); INC(checks);
  request := PubSub.Retract(r, peer^, node^, empty^, TRUE, 100, a, error);
  ASSERT((request = NIL) & (error.code = IQ.invalidRequest)); INC(checks);
  r.Stop; c.Abort; t.output.Close
END PubSubs;

PROCEDURE SubscriptionData(node, jid, id: ARRAY OF T.CodeUnit; state: ARRAY OF CHAR): Items.Item;
  VAR root, item: Items.Item; value: T.String;
BEGIN
  root := Items.New("pubsub", PubSub.namespaceURI);
  item := Items.New("subscription", PubSub.namespaceURI); root.AddChild(item);
  item.SetParam("node", node); item.SetParam("jid", jid); value := Items.Latin1(state);
  item.SetParam("subscription", value^);
  IF id[0] # 0 THEN item.SetParam("subid", id) END;
  RETURN root
END SubscriptionData;

PROCEDURE Subscriptions;
  VAR c: C.Client; t: Fake; h: Hook; r: IQ.Router; roster: Roster.Roster; rh: RosterHook;
    request: IQ.Request; a: Action; error: Msg.Msg; peer, node, jid, canonical, id, empty, value: T.String;
    payload, item, options, required: Items.Item; sub: PubSub.Subscription; i: LONGINT;
BEGIN
  c := New(t, h, r, roster, rh); NEW(a); peer := Items.Latin1("pubsub.example.net");
  node := Items.UTF8("Հրապարակումներ"); jid := Items.UTF8("օբերոն@xn--cbbu1a.xn--y9a3aq/reader");
  canonical := Items.UTF8("օբերոն@ծոց.հայ/reader"); id := Items.UTF8("բաժանորդ😀"); empty := Items.Latin1("");
  payload := PubSub.BuildSubscribe(node^, jid^); item := payload.First(PubSub.namespaceURI, "subscribe");
  value := item.GetAttribute("", "jid"); Check(S.Equal(value^, canonical^), "canonical subscription JID");
  Check(item.GetAttribute("", "subid") = NIL, "subscribe does not invent a subscription ID");
  request := PubSub.Subscribe(r, peer^, node^, jid^, 100, a, error);
  Check((request # NIL) & (error = NIL), "queued subscription");
  payload := SubscriptionData(node^, canonical^, id^, "subscribed");
  r.Received(c, IQ.Response(h.last, payload)); sub := PubSub.ReadSubscription(request);
  Check((sub # NIL) & (a.calls = 1), "subscription completion");
  Check((sub.state = PubSub.subscriptionSubscribed) & ~sub.configurationRequired &
    S.Equal(sub.jid^, canonical^) & S.Equal(sub.id^, id^), "subscription identity and state");
  FOR i := PubSub.subscriptionNone TO PubSub.subscriptionSubscribed DO
    request := PubSub.Subscribe(r, peer^, node^, jid^, 100, a, error);
    CASE i OF
    | PubSub.subscriptionNone: payload := SubscriptionData(node^, canonical^, empty^, "none")
    | PubSub.subscriptionPending: payload := SubscriptionData(node^, canonical^, empty^, "pending")
    | PubSub.subscriptionUnconfigured: payload := SubscriptionData(node^, canonical^, empty^, "unconfigured")
    | PubSub.subscriptionSubscribed: payload := SubscriptionData(node^, canonical^, empty^, "subscribed")
    ELSE HALT(100)
    END;
    r.Received(c, IQ.Response(h.last, payload)); sub := PubSub.ReadSubscription(request);
    Check((sub # NIL) & (sub.state = i) & (sub.id[0] = 0), "subscription state decoding");
    Check(sub.configurationRequired = (i = PubSub.subscriptionUnconfigured), "configuration state remains explicit")
  END;
  request := PubSub.Subscribe(r, peer^, node^, jid^, 100, a, error);
  payload := SubscriptionData(node^, canonical^, id^, "unconfigured");
  options := Items.New("subscribe-options", PubSub.namespaceURI);
  required := Items.New("required", PubSub.namespaceURI); options.AddChild(required);
  item := payload.First(PubSub.namespaceURI, "subscription"); item.AddChild(options);
  r.Received(c, IQ.Response(h.last, payload)); sub := PubSub.ReadSubscription(request);
  Check((sub # NIL) & sub.configurationRequired, "required configuration marker");
  FOR i := 0 TO 7 DO
    request := PubSub.Subscribe(r, peer^, node^, jid^, 100, a, error);
    payload := SubscriptionData(node^, canonical^, id^, "subscribed");
    item := payload.First(PubSub.namespaceURI, "subscription"); value := Items.Latin1("wrong");
    CASE i OF
    | 0: item.SetParam("node", value^)
    | 1: value := Items.Latin1("other@example.net"); item.SetParam("jid", value^)
    | 2: item.SetParam("subscription", value^)
    | 3: item.SetParam("subid", empty^)
    | 4: payload.AddChild(Items.New("subscription", PubSub.namespaceURI))
    | 5: item.AddChild(Items.New("subscribe-options", "urn:wrong"))
    | 6: options := Items.New("subscribe-options", PubSub.namespaceURI); item.AddChild(options)
    | 7: value := Items.UTF8("օբերոն@ծոց.հայ/other"); item.SetParam("jid", value^)
    ELSE HALT(100)
    END;
    r.Received(c, IQ.Response(h.last, payload));
    Check(PubSub.ReadSubscription(request) = NIL, "rejecting malformed or mismatched subscription")
  END;
  request := PubSub.Subscribe(r, peer^, node^, jid^, 100, a, error);
  r.Received(c, IQ.Response(h.last, NIL));
  Check(PubSub.ReadSubscription(request) = NIL, "empty success does not establish a subscription");
  payload := PubSub.BuildUnsubscribe(node^, jid^, id^);
  item := payload.First(PubSub.namespaceURI, "unsubscribe"); value := item.GetAttribute("", "subid");
  Check(S.Equal(value^, id^), "unsubscribe retains exact subscription ID");
  request := PubSub.Unsubscribe(r, peer^, node^, jid^, id^, 100, a, error);
  r.Received(c, IQ.Response(h.last, NIL));
  Check(PubSub.Unsubscribed(request) & (PubSub.ReadSubscription(request) = NIL), "unsubscribe acknowledgement");
  payload := PubSub.BuildUnsubscribe(node^, jid^, empty^);
  item := payload.First(PubSub.namespaceURI, "unsubscribe");
  Check(item.GetAttribute("", "subid") = NIL, "optional subscription ID is omitted");
  value := Items.Latin1("invalid..example");
  Check(PubSub.BuildSubscribe(node^, value^) = NIL, "rejecting malformed subscriber JID");
  Check(PubSub.BuildSubscribe(empty^, jid^) = NIL, "rejecting empty node");
  NEW(value, PubSub.maxIDUnits+2);
  FOR i := 0 TO PubSub.maxIDUnits DO value[i] := ORD("x") END; value[PubSub.maxIDUnits+1] := 0;
  Check(PubSub.BuildUnsubscribe(node^, jid^, value^) = NIL, "bounding subscription ID");
  jid := Items.Latin1("user@example.org"); node := Items.Latin1("feed");
  FOR i := 1 TO 3 DO
    t.chunk := i; request := PubSub.Subscribe(r, peer^, node^, jid^, 100, a, error);
    Reply(c, t, request, 'from="attacker.example.net" type="result"', '');
    Check((request.status = IQ.pending) & (PubSub.ReadSubscription(request) = NIL), "rejecting foreign reply");
    Reply(c, t, request, 'from="pubsub.example.net" type="result"',
      '<pubsub xmlns="http://jabber.org/protocol/pubsub"><subscription node="feed" jid="user@example.org" subscription="subscribed"/></pubsub>');
    Check(PubSub.ReadSubscription(request) # NIL, "fragmented subscription result")
  END;
  request := PubSub.Subscribe(r, peer^, node^, jid^, 100, a, error); r.Tick(100);
  Check((request.status = IQ.timedOut) & (PubSub.ReadSubscription(request) = NIL), "subscription timeout");
  request := PubSub.Unsubscribe(r, peer^, node^, jid^, empty^, 100, a, error); r.Stop;
  Check((request.status = IQ.cancelled) & ~PubSub.Unsubscribed(request), "cancelled unsubscribe is not acknowledged");
  c.Abort; t.output.Close
END Subscriptions;

PROCEDURE PageField(parent: Items.Item; name, text: ARRAY OF CHAR): Items.Item;
  VAR item: Items.Item; value: T.String;
BEGIN
  item := Items.New(name, RSM.namespaceURI); value := Items.Latin1(text);
  item.AddText(value^, 0, S.Length(value^)); parent.AddChild(item); RETURN item
END PageField;

PROCEDURE PageReplyCount(node: ARRAY OF T.CodeUnit; count: ARRAY OF CHAR): Items.Item;
  VAR root, items, item, set, first, unused: Items.Item; value: T.String;
BEGIN
  root := Items.New("pubsub", PubSub.namespaceURI); items := Items.New("items", PubSub.namespaceURI);
  items.SetParam("node", node); root.AddChild(items);
  item := Items.New("item", PubSub.namespaceURI); value := Items.Latin1("a"); item.SetParam("id", value^); items.AddChild(item);
  item := Items.New("item", PubSub.namespaceURI); value := Items.Latin1("b"); item.SetParam("id", value^); items.AddChild(item);
  set := Items.New("set", RSM.namespaceURI); root.AddChild(set); first := PageField(set, "first", "a");
  value := Items.Latin1("0"); first.SetParam("index", value^);
  unused := PageField(set, "last", "b"); unused := PageField(set, "count", count); RETURN root
END PageReplyCount;

PROCEDURE PageReply(node: ARRAY OF T.CodeUnit): Items.Item;
BEGIN RETURN PageReplyCount(node, "2")
END PageReply;

PROCEDURE Pages;
  VAR c: C.Client; t: Fake; h: Hook; r: IQ.Router; roster: Roster.Roster; rh: RosterHook;
    request: IQ.Request; a: Action; error: Msg.Msg; peer, node, empty, value, cursor: T.String;
    payload, items, item, set, field: Items.Item; page: PubSub.Page; bytes: Items.Bytes; length, i: LONGINT;
BEGIN
  c := New(t, h, r, roster, rh); NEW(a); peer := Items.Latin1("pubsub.example.net");
  node := Items.Latin1("feed"); empty := Items.Latin1("");
  request := PubSub.FetchPage(r, peer^, node^, empty^, RSM.firstPage, 2, 100, a, error);
  Check((request # NIL) & (error = NIL), "queued paged item request");
  payload := PageReply(node^); r.Received(c, IQ.Response(h.last, payload)); page := PubSub.ReadPage(request);
  Check((page # NIL) & (a.calls = 1), "paged result completion");
  Check((page.size = 2) & page.info.hasCount & (page.info.count = 2) &
    page.info.hasIndex & (page.info.index = 0), "checked page size and metadata");
  Check(PubSub.ReadItems(request) = page.items, "paged result available through item reader");
  Check(PubSub.BuildPage(node^, empty^, RSM.firstPage, PubSub.maxItems+1) = NIL, "bounding requested page size");
  Check(PubSub.BuildPage(node^, empty^, RSM.afterPage, 2) = NIL, "after-page request needs cursor");
  FOR i := 0 TO 12 DO
    request := PubSub.FetchPage(r, peer^, node^, empty^, RSM.firstPage, 2, 100, a, error);
    payload := PageReply(node^); items := payload.First(PubSub.namespaceURI, "items");
    set := payload.First(RSM.namespaceURI, "set"); value := Items.Latin1("wrong");
    CASE i OF
    | 0: items.SetParam("node", value^)
    | 1: payload.AddChild(Items.New("set", RSM.namespaceURI))
    | 2: payload.AddChild(Items.New("items", PubSub.namespaceURI))
    | 3: field := PageField(set, "first", "a")
    | 4: field := set.First(RSM.namespaceURI, "first"); value := Items.Latin1("2"); field.SetParam("index", value^)
    | 5: item := Items.New("item", PubSub.namespaceURI); item.SetParam("id", value^); items.AddChild(item)
    | 6: field := set.First(RSM.namespaceURI, "last"); field.AddChild(Items.New("x", RSM.namespaceURI))
    | 7: payload.AddChild(Items.New("set", "urn:wrong"))
    | 8: field := set.First(RSM.namespaceURI, "count"); field.AddText(value^, 0, S.Length(value^))
    | 9: field := set.First(RSM.namespaceURI, "first"); field.AddText(value^, 0, S.Length(value^))
    | 10: field := set.First(RSM.namespaceURI, "last"); field.AddText(value^, 0, S.Length(value^))
    | 11: payload := PageReplyCount(node^, "1")
    | 12: payload := Items.New("pubsub", PubSub.namespaceURI);
      items := Items.New("items", PubSub.namespaceURI); items.SetParam("node", node^); payload.AddChild(items);
      item := Items.New("item", PubSub.namespaceURI); item.SetParam("id", value^); items.AddChild(item);
      set := Items.New("set", RSM.namespaceURI); payload.AddChild(set); field := PageField(set, "count", "2")
    ELSE HALT(100)
    END;
    r.Received(c, IQ.Response(h.last, payload));
    Check((PubSub.ReadPage(request) = NIL) & (PubSub.ReadItems(request) = NIL), "rejecting malformed page result")
  END;
  request := PubSub.FetchPage(r, peer^, node^, empty^, RSM.firstPage, 2, 100, a, error);
  payload := Items.New("pubsub", PubSub.namespaceURI); items := Items.New("items", PubSub.namespaceURI);
  items.SetParam("node", node^); payload.AddChild(items);
  r.Received(c, IQ.Response(h.last, payload));
  Check(PubSub.ReadPage(request) = NIL, "missing RSM metadata does not establish a complete page");
  request := PubSub.FetchPage(r, peer^, node^, empty^, RSM.firstPage, 0, 100, a, error);
  payload := Items.New("pubsub", PubSub.namespaceURI); set := Items.New("set", RSM.namespaceURI); payload.AddChild(set);
  field := PageField(set, "count", "5"); r.Received(c, IQ.Response(h.last, payload)); page := PubSub.ReadPage(request);
  Check((page # NIL) & (page.size = 0) & page.info.hasCount & (page.info.count = 5), "count-only result without item wrapper");
  request := PubSub.FetchPage(r, peer^, node^, empty^, RSM.beforePage, 2, 100, a, error);
  payload := PageReply(node^); r.Received(c, IQ.Response(h.last, payload));
  Check(PubSub.ReadPage(request) # NIL, "last-page retrieval");
  cursor := Items.Latin1("a"); request := PubSub.FetchPage(r, peer^, node^, cursor^, RSM.afterPage, 2, 100, a, error);
  payload := PageReply(node^); r.Received(c, IQ.Response(h.last, payload));
  Check(PubSub.ReadPage(request) = NIL, "after-page result must exclude requested cursor");
  cursor := Items.Latin1("z"); request := PubSub.FetchPage(r, peer^, node^, cursor^, RSM.beforePage, 2, 100, a, error);
  payload := PageReply(node^); r.Received(c, IQ.Response(h.last, payload));
  Check(PubSub.ReadPage(request) # NIL, "before-page retrieval with opaque cursor");
  request := PubSub.Fetch(r, peer^, node^, empty^, 2, 100, a, error);
  payload := PageReply(node^); r.Received(c, IQ.Response(h.last, payload));
  Check((PubSub.ReadItems(request) # NIL) & (PubSub.ReadPage(request) = NIL), "legacy fetch accepts valid sibling RSM metadata");
  FOR i := 1 TO 3 DO
    request := PubSub.FetchPage(r, peer^, node^, empty^, RSM.firstPage, 2, 100, a, error);
    Reply(c, t, request, 'from="attacker.example.net" type="result"', '');
    Check((request.status = IQ.pending) & (PubSub.ReadPage(request) = NIL), "rejecting foreign page reply");
    payload := PageReply(node^); XML.Encode(payload, 4096, bytes, length, error);
    Check(error = NIL, "serializing paged fixture"); t.chunk := i;
    Reply(c, t, request, 'from="pubsub.example.net" type="result"', bytes^);
    Check(PubSub.ReadPage(request) # NIL, "fragmented paged reply")
  END;
  request := PubSub.FetchPage(r, peer^, node^, empty^, RSM.firstPage, 2, 100, a, error); r.Stop;
  Check((request.status = IQ.cancelled) & (PubSub.ReadPage(request) = NIL), "cancelled page is not accepted");
  c.Abort; t.output.Close
END Pages;

PROCEDURE Events;
  VAR stanza: Core.Stanza; root, event, operation, item, payload: Items.Item; e: PubSub.Event;
    peer, node, value: T.String; i: LONGINT;
BEGIN
  peer := Items.UTF8("օբերոն@ծոց.հայ"); node := Items.Latin1("urn:xmpp:microblog:0");
  root := Items.New("message", "jabber:client"); value := Items.UTF8("օբերոն@xn--cbbu1a.xn--y9a3aq");
  root.SetParam("from", value^); value := Items.Latin1("headline"); root.SetParam("type", value^);
  event := Items.New("event", PubSub.eventURI); root.AddChild(event);
  operation := Items.New("items", PubSub.eventURI); operation.SetParam("node", node^); event.AddChild(operation);
  item := Items.New("item", PubSub.eventURI); value := Items.UTF8("Հայերեն😀"); item.SetParam("id", value^);
  payload := Items.New("entry", "http://www.w3.org/2005/Atom"); item.AddChild(payload); operation.AddChild(item);
  item := Items.New("retract", PubSub.eventURI); value := Items.Latin1("old"); item.SetParam("id", value^); operation.AddChild(item);
  stanza := Core.Wrap(root, NIL); e := PubSub.ReadEvent(stanza, peer^, node^);
  ASSERT((e # NIL) & (e.count = 2) & (e.updates[0].kind = PubSub.published) & (e.updates[0].payload = payload));
  ASSERT((e.updates[1].kind = PubSub.retracted) & (e.updates[1].payload = NIL)); INC(checks);
  value := Items.Latin1("wrong"); ASSERT(PubSub.ReadEvent(stanza, peer^, value^) = NIL);
  value := Items.Latin1("attacker@example.net"); ASSERT(PubSub.ReadEvent(stanza, value^, node^) = NIL); INC(checks);
  value := Items.UTF8("օբերոն@ծոց.հայ/r"); root.SetParam("from", value^); stanza := Core.Wrap(root, NIL);
  ASSERT(PubSub.ReadEvent(stanza, peer^, node^) = NIL); INC(checks);
  root.SetParam("from", peer^); value := Items.Latin1("error"); root.SetParam("type", value^); stanza := Core.Wrap(root, NIL);
  ASSERT(PubSub.ReadEvent(stanza, peer^, node^) = NIL); INC(checks);
  value := Items.Latin1("headline"); root.SetParam("type", value^);
  root.AddChild(Items.New("event", PubSub.eventURI)); stanza := Core.Wrap(root, NIL);
  ASSERT(PubSub.ReadEvent(stanza, peer^, node^) = NIL); INC(checks);
  FOR i := PubSub.purged TO PubSub.deleted DO
    root := Items.New("message", "jabber:client"); root.SetParam("from", peer^);
    event := Items.New("event", PubSub.eventURI); root.AddChild(event);
    IF i = PubSub.purged THEN operation := Items.New("purge", PubSub.eventURI) ELSE operation := Items.New("delete", PubSub.eventURI) END;
    operation.SetParam("node", node^); event.AddChild(operation); stanza := Core.Wrap(root, NIL);
    e := PubSub.ReadEvent(stanza, peer^, node^); ASSERT((e # NIL) & (e.kind = i) & (e.count = 0)); INC(checks)
  END
END Events;

PROCEDURE PubSubBounds;
  VAR root, event, operation, item, payload, pubsub: Items.Item; stanza: Core.Stanza;
    peer, node, id, text: T.String; number: ARRAY 4 OF T.CodeUnit; i: LONGINT; e: PubSub.Event;
BEGIN
  peer := Items.Latin1("friend@example.net"); node := Items.Latin1("test"); id := Items.Latin1("id");
  NEW(text, PubSub.maxPayloadBytes+1);
  FOR i := 0 TO PubSub.maxPayloadBytes-1 DO text[i] := ORD("a") END; text[PubSub.maxPayloadBytes] := 0;
  payload := Items.New("x", "urn:test"); payload.AddText(text^, 0, PubSub.maxPayloadBytes);
  ASSERT(PubSub.BuildPublish(node^, id^, payload) = NIL); ASSERT(payload.parent = NIL); INC(checks);
  payload := Items.New("x", "urn:test"); payload.AddText(text^, 0, 16384);
  pubsub := PubSub.BuildPublish(node^, id^, payload); ASSERT(pubsub # NIL); INC(checks);
  NEW(text, PubSub.maxNodeUnits+2);
  FOR i := 0 TO PubSub.maxNodeUnits DO text[i] := ORD("a") END; text[PubSub.maxNodeUnits+1] := 0;
  ASSERT(PubSub.BuildItems(text^, id^, 1) = NIL); ASSERT(PubSub.BuildRetract(node^, text^, TRUE) = NIL); INC(checks);
  text[PubSub.maxNodeUnits] := 0; ASSERT(PubSub.BuildItems(text^, id^, PubSub.maxItems) # NIL); INC(checks);
  root := Items.New("message", "jabber:client"); root.SetParam("from", peer^);
  event := Items.New("event", PubSub.eventURI); root.AddChild(event);
  operation := Items.New("items", PubSub.eventURI); operation.SetParam("node", node^); event.AddChild(operation);
  FOR i := 0 TO PubSub.maxItems-1 DO
    item := Items.New("item", PubSub.eventURI); number[0] := ORD("a")+i DIV 26;
    number[1] := ORD("a")+i MOD 26; number[2] := 0; item.SetParam("id", number); operation.AddChild(item)
  END;
  stanza := Core.Wrap(root, NIL); e := PubSub.ReadEvent(stanza, peer^, node^);
  ASSERT((e # NIL) & (e.count = PubSub.maxItems) & (e.updates[0].payload = NIL)); INC(checks);
  item := Items.New("item", PubSub.eventURI); item.SetParam("id", id^); operation.AddChild(item);
  ASSERT(PubSub.ReadEvent(stanza, peer^, node^) = NIL); INC(checks);
  root := Items.New("message", "jabber:client"); root.SetParam("from", peer^);
  event := Items.New("event", PubSub.eventURI); root.AddChild(event);
  operation := Items.New("items", PubSub.eventURI); operation.SetParam("node", node^); event.AddChild(operation);
  item := Items.New("item", PubSub.eventURI); operation.AddChild(item); stanza := Core.Wrap(root, NIL);
  ASSERT(PubSub.ReadEvent(stanza, peer^, node^) = NIL); INC(checks);
  item.SetParam("id", id^); ASSERT(PubSub.ReadEvent(stanza, peer^, node^) # NIL); INC(checks);
  item := Items.New("retract", PubSub.eventURI); item.SetParam("id", id^); operation.AddChild(item);
  ASSERT(PubSub.ReadEvent(stanza, peer^, node^) = NIL); INC(checks);
  root := Items.New("message", "jabber:client"); root.SetParam("from", peer^);
  event := Items.New("event", PubSub.eventURI); root.AddChild(event);
  operation := Items.New("items", PubSub.eventURI); operation.SetParam("node", node^); event.AddChild(operation);
  NEW(text, 24001);
  FOR i := 0 TO LEN(text^)-2 DO text[i] := ORD("a") END; text[LEN(text^)-1] := 0;
  FOR i := 0 TO 2 DO
    item := Items.New("item", PubSub.eventURI); number[0] := ORD("a")+i; number[1] := 0;
    item.SetParam("id", number); payload := Items.New("x", "urn:test");
    payload.AddText(text^, 0, S.Length(text^)); item.AddChild(payload); operation.AddChild(item)
  END;
  stanza := Core.Wrap(root, NIL); ASSERT(PubSub.ReadEvent(stanza, peer^, node^) = NIL); INC(checks)
END PubSubBounds;

BEGIN
  checks := 0; Rosters; Boundaries; PubSubs; Subscriptions; Pages; Events; PubSubBounds;
  Out.String("XMPP roster and PubSub/PEP checks passed: "); Out.Int(checks, 0); Out.Ln
END TestXmppRosterPubSub.
