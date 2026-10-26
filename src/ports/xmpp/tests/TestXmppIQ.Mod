MODULE TestXmppIQ;

IMPORT SYSTEM, Out, Msg, Channel, S := LongStrings, Mem := IOMemory,
  T := XmppTypes, Items := XmppItems, Wire := XmppWire, C := XmppClient,
  Core := XmppCore, IQ := XmppIQ, Ping := XmppPing, Version := XmppVersion, Disco := XmppDisco;

TYPE
  Fake = POINTER TO FakeDesc;
  FakeDesc = RECORD (Wire.TransportDesc)
    script: Items.Bytes; position, chunk: LONGINT; ended, failWrite: BOOLEAN;
    output: Mem.Channel; writer: Channel.Writer;
  END;
  Hook = POINTER TO HookDesc;
  HookDesc = RECORD (C.HookDesc)
    ready, received, sent, errors, closed: LONGINT; last: Core.Stanza;
  END;
  Action = POINTER TO ActionDesc;
  ActionDesc = RECORD (IQ.ActionDesc)
    calls: LONGINT; last, spawned: IQ.Request; chain: BOOLEAN;
  END;

VAR checks: LONGINT;

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
  t.writer.WriteBytes(bytes, start, count); t.bytesWritten := t.writer.bytesWritten;
  t.res := t.writer.res
END WriteBytes;
PROCEDURE (t: Fake) Close;
BEGIN t.ended := TRUE END Close;

PROCEDURE (h: Hook) Ready(client: C.Client; jid: T.String);
BEGIN INC(h.ready) END Ready;
PROCEDURE (h: Hook) Received(client: C.Client; stanza: Core.Stanza);
BEGIN INC(h.received) END Received;
PROCEDURE (h: Hook) Sent(client: C.Client; stanza: Core.Stanza);
BEGIN INC(h.sent); h.last := stanza END Sent;
PROCEDURE (h: Hook) Error(client: C.Client; error: Msg.Msg);
BEGIN INC(h.errors) END Error;
PROCEDURE (h: Hook) Closed(client: C.Client);
BEGIN INC(h.closed) END Closed;

PROCEDURE (a: Action) Done(router: IQ.Router; request: IQ.Request);
  VAR target: T.String; error: Msg.Msg;
BEGIN
  INC(a.calls); a.last := request; ASSERT(request.status # IQ.pending);
  IF a.chain THEN
    a.chain := FALSE; target := Items.Latin1("example.org");
    a.spawned := Ping.Query(router, target^, 10, a, error); ASSERT((error = NIL) & (a.spawned # NIL))
  END
END Done;

PROCEDURE New(VAR t: Fake; VAR h: Hook; VAR r: IQ.Router): C.Client;
  VAR c: C.Client; user, password, resource, name, version, os, category, type: T.String;
    error: Msg.Msg; ping: Ping.Pinger; ver: Version.Version; disco: Disco.Disco; state: SHORTINT;
BEGIN
  NEW(t); NEW(h); t.chunk := 8192;
  t.script := Items.Copy8('<s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features><mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><mechanism>PLAIN</mechanism></mechanisms></s:features><success xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/><s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></s:features><iq id="voc-bind-1" type="result"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>user@example.org/r</jid></bind></iq>');
  t.output := Mem.Tmp("", {Mem.read, Mem.write}, error); ASSERT(error = NIL); t.writer := t.output.NewWriter();
  r := IQ.New(h); ping := Ping.New(r); ASSERT(ping # NIL);
  name := Items.UTF8("VOC Հայերեն😀"); version := Items.Latin1("4.0.2"); os := Items.Latin1("");
  ver := Version.New(r, name^, version^, os^); ASSERT(ver # NIL);
  category := Items.Latin1("client"); type := Items.Latin1("console");
  disco := Disco.New(r, category^, type^, name^); ASSERT(disco # NIL);
  ASSERT(disco.AddFeature(Ping.namespaceURI)); ASSERT(disco.AddFeature(Version.namespaceURI));
  ASSERT(~disco.AddFeature(Ping.namespaceURI));
  name := Items.UTF8("ծոց.հայ"); category := Items.Latin1("node"); type := Items.UTF8("Հայերեն😀");
  ASSERT(disco.AddItem(name^, category^, type^)); ASSERT(~disco.AddItem(name^, category^, type^));
  user := Items.Latin1("user"); password := Items.Latin1("password"); resource := Items.Latin1("r");
  c := C.New(t, r, "example.org", user^, password^, resource^, TRUE, error); ASSERT((c # NIL) & (error = NIL));
  ASSERT(c.Start()); REPEAT state := c.Step() UNTIL (state = C.online) OR (state = C.failed);
  ASSERT((state = C.online) & (h.ready = 1) & (h.errors = 0)); RETURN c
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
  VAR xml: ARRAY 4096 OF CHAR; bytes: Items.Bytes;
  PROCEDURE Append(text: ARRAY OF CHAR);
    VAR i, n: LONGINT;
  BEGIN
    n := S.Length8(xml); ASSERT(n+S.Length8(text) < LEN(xml));
    FOR i := 0 TO S.Length8(text) DO xml[n+i] := text[i] END
  END Append;
BEGIN
  bytes := Items.UTF8Bytes(request.id^); xml := '<iq id="'; Append(bytes^); Append('" ');
  Append(attributes); Append('>'); Append(content); Append('</iq>'); Feed(c, t, xml)
END Reply;

PROCEDURE Condition(h: Hook; condition: ARRAY OF CHAR);
  VAR error: Items.Item;
BEGIN
  ASSERT(S.Equal8(h.last.type^, "error")); error := h.last.item.First("jabber:client", "error");
  ASSERT((error # NIL) & (error.First("urn:ietf:params:xml:ns:xmpp-stanzas", condition) # NIL)); INC(checks)
END Condition;

PROCEDURE Serving;
  VAR c: C.Client; t: Fake; h: Hook; r: IQ.Router; query, identity, entry: Items.Item;
    sent, i, chunk: LONGINT; value, expected: T.String;
BEGIN
  c := New(t, h, r);
  Feed(c, t, '<iq id="ping" from="other@example.net/p" to="user@example.org/r" type="get"><p:ping xmlns:p="urn:xmpp:ping"/></iq>');
  ASSERT((h.sent = 1) & S.Equal8(h.last.type^, "result") & S.Equal8(h.last.id^, "ping"));
  ASSERT(S.Equal8(h.last.to^, "other@example.net/p") & S.Equal8(h.last.from^, "user@example.org/r"));
  ASSERT(h.last.item.content = NIL); INC(checks);
  Feed(c, t, '<iq id="version" from="other@example.net" type="get"><query xmlns="jabber:iq:version"/></iq>');
  query := h.last.item.First(Version.namespaceURI, "query"); ASSERT(query # NIL);
  expected := Items.UTF8("VOC Հայերեն😀"); entry := query.First(Version.namespaceURI, "name"); value := entry.Text(); ASSERT(S.Equal(value^, expected^));
  ASSERT(query.First(Version.namespaceURI, "os") = NIL); INC(checks);
  Feed(c, t, '<iq id="info" type="get"><query xmlns="http://jabber.org/protocol/disco#info"/></iq>');
  query := h.last.item.First(Disco.infoURI, "query"); ASSERT(query # NIL);
  identity := query.First(Disco.infoURI, "identity"); ASSERT(identity # NIL);
  value := identity.GetAttribute("", "category"); ASSERT(S.Equal8(value^, "client"));
  entry := query.First(Disco.infoURI, "feature"); ASSERT(entry # NIL); INC(checks);
  Feed(c, t, '<iq id="items" type="get"><query xmlns="http://jabber.org/protocol/disco#items"/></iq>');
  query := h.last.item.First(Disco.itemsURI, "query"); ASSERT(query # NIL); entry := query.First(Disco.itemsURI, "item");
  value := entry.GetAttribute("", "jid"); expected := Items.UTF8("ծոց.հայ"); ASSERT(S.Equal(value^, expected^)); INC(checks);
  Feed(c, t, '<iq id="node" type="get"><query node="unknown" xmlns="http://jabber.org/protocol/disco#info"/></iq>'); Condition(h, "item-not-found");
  Feed(c, t, '<iq id="unknown" type="get"><ping xmlns="urn:spoof"/></iq>'); Condition(h, "service-unavailable");
  Feed(c, t, '<iq id="bad" type="get"><ping xmlns="urn:xmpp:ping"/><ping xmlns="urn:xmpp:ping"/></iq>'); Condition(h, "bad-request");
  Feed(c, t, '<iq id="bad" type="get"><ping xmlns="urn:xmpp:ping"><x/></ping></iq>'); Condition(h, "bad-request");
  Feed(c, t, '<iq id="bad" type="set"><ping xmlns="urn:xmpp:ping"/></iq>'); Condition(h, "bad-request");
  Feed(c, t, '<iq id="bad" type="get">bad<ping xmlns="urn:xmpp:ping"/></iq>'); Condition(h, "bad-request");
  sent := h.sent;
  Feed(c, t, '<iq type="get"><ping xmlns="urn:xmpp:ping"/></iq>');
  Feed(c, t, '<iq id="unknown" type="error"><error/></iq>');
  Feed(c, t, '<iq id="unknown" type="result"/>');
  Feed(c, t, '<iq id="wrong" type="get" to="other@example.org"><ping xmlns="urn:xmpp:ping"/></iq>');
  Feed(c, t, '<iq id="wrong" type="get" to="user@example.org/other"><ping xmlns="urn:xmpp:ping"/></iq>');
  Feed(c, t, '<iq id="wrong" type="get" from="bad..example"><ping xmlns="urn:xmpp:ping"/></iq>');
  ASSERT(h.sent = sent); INC(checks);
  (* Every transport split size preserves dispatch and a single response. *)
  FOR chunk := 1 TO 110 DO
    t.chunk := chunk; sent := h.sent;
    Feed(c, t, '<iq id="split" type="get"><p:ping xmlns:p="urn:xmpp:ping"/></iq>');
    ASSERT(h.sent = sent+1); INC(checks)
  END;
  r.Stop; c.Abort; t.output.Close
END Serving;

PROCEDURE Correlation;
  VAR c: C.Client; t: Fake; h: Hook; r: IQ.Router; a: Action; request: IQ.Request; peer: T.String; error: Msg.Msg;
    requests: ARRAY IQ.maxPending OF IQ.Request; i, calls, sent: LONGINT;
BEGIN
  c := New(t, h, r); NEW(a); peer := Items.Latin1("other@example.net/r");
  request := Ping.Query(r, peer^, 100, a, error); ASSERT((error = NIL) & (request # NIL) & (r.count = 1));
  Reply(c, t, request, 'type="result" from="attacker@example.net/r"', "");
  Reply(c, t, request, 'type="result" from="other@example.net/other"', "");
  Reply(c, t, request, 'type="result" from="other@example.net/r" to="user@example.org/other"', "");
  Reply(c, t, request, 'type="result" from="other@example.net/r" to=""', "");
  Reply(c, t, request, 'type="result"', "");
  ASSERT((a.calls = 0) & (r.count = 1)); INC(checks);
  Reply(c, t, request, 'type="result" from="other@EXAMPLE.net/r" to="user@example.org/r"', "");
  ASSERT((a.calls = 1) & (r.count = 0) & IQ.EmptyResult(request)); INC(checks);
  Reply(c, t, request, 'type="result" from="other@example.net/r"', ""); ASSERT(a.calls = 1); INC(checks);
  peer := Items.UTF8("օբերոն@ծոց.հայ"); request := Ping.Query(r, peer^, 100, a, error); ASSERT(error = NIL);
  Reply(c, t, request, 'type="result" from="օբերոն@xn--cbbu1a.xn--y9a3aq/Հայերեն😀"', "");
  ASSERT((a.calls = 2) & IQ.EmptyResult(request)); INC(checks);
  peer := Items.Latin1(""); request := Ping.Query(r, peer^, 100, a, error); ASSERT(error = NIL);
  Reply(c, t, request, 'type="result" from="foreign.example"', ""); ASSERT(a.calls = 2);
  Reply(c, t, request, 'type="result"', ""); ASSERT((a.calls = 3) & IQ.EmptyResult(request)); INC(checks);
  peer := Items.Latin1("user@example.org"); request := Ping.Query(r, peer^, 100, a, error); ASSERT(error = NIL);
  Reply(c, t, request, 'type="result"', ""); ASSERT(IQ.EmptyResult(request)); INC(checks);
  peer := Items.Latin1("example.org"); request := Ping.Query(r, peer^, 100, a, error); ASSERT(error = NIL);
  calls := a.calls; Reply(c, t, request, 'type="result" from="example.org/resource"', ""); ASSERT(a.calls = calls);
  Reply(c, t, request, 'type="error" from="example.org"', '<error type="cancel"><service-unavailable xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/></error>');
  ASSERT((request.status = IQ.stanzaError) & (r.count = 0)); INC(checks);
  peer := Items.Latin1("remote.example"); request := Ping.Query(r, peer^, 100, a, error); ASSERT(error = NIL);
  calls := a.calls; Reply(c, t, request, 'type="result" from="remote.example/resource"', ""); ASSERT(a.calls = calls);
  Reply(c, t, request, 'type="result" from="remote.example"', ""); ASSERT(IQ.EmptyResult(request)); INC(checks);
  peer := Items.Latin1("example.org");
  request := Ping.Query(r, peer^, 100, a, error); Reply(c, t, request, 'type="error" from="example.org"', "");
  ASSERT(request.status = IQ.malformed); INC(checks);
  request := Ping.Query(r, peer^, 100, a, error); Reply(c, t, request, 'type="error" from="example.org"', '<error/>');
  ASSERT(request.status = IQ.malformed); INC(checks);
  request := Ping.Query(r, peer^, 100, a, error);
  Reply(c, t, request, 'type="error" from="example.org"', '<error type="cancel"><bad-request xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/><forbidden xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/></error>');
  ASSERT(request.status = IQ.malformed); INC(checks);
  request := Ping.Query(r, peer^, 100, a, error); Reply(c, t, request, 'type="result" from="example.org"', '<a/><b/>');
  ASSERT(request.status = IQ.malformed); INC(checks);
  request := Ping.Query(r, peer^, 10, a, error); calls := a.calls; r.Tick(9); ASSERT(a.calls = calls);
  a.chain := TRUE; r.Tick(1); ASSERT((request.status = IQ.timedOut) & (a.calls = calls+1));
  ASSERT((a.spawned.status = IQ.pending) & (r.count = 1)); r.Tick(10); ASSERT(a.spawned.status = IQ.timedOut); INC(checks);
  request := Ping.Query(r, peer^, 100, a, error); ASSERT(r.Cancel(request)); ASSERT(~r.Cancel(request));
  ASSERT(request.status = IQ.cancelled); INC(checks);
  calls := a.calls;
  FOR i := 0 TO IQ.maxPending-1 DO requests[i] := Ping.Query(r, peer^, 100, a, error); ASSERT(error = NIL) END;
  sent := h.sent; request := Ping.Query(r, peer^, 100, a, error);
  ASSERT((request = NIL) & (error.code = IQ.queueFull) & (r.count = IQ.maxPending) & (h.sent = sent));
  r.Stop; ASSERT((a.calls = calls+IQ.maxPending) & (r.count = 0));
  FOR i := 0 TO IQ.maxPending-1 DO ASSERT(requests[i].status = IQ.cancelled) END;
  request := Ping.Query(r, peer^, 100, a, error); ASSERT((request = NIL) & (error.code = IQ.offline));
  INC(checks); c.Abort; t.output.Close
END Correlation;

PROCEDURE ReadingAndLimits;
  VAR c: C.Client; t: Fake; h: Hook; r, fresh: IQ.Router; a: Action; request: IQ.Request; peer, node, name, version, os, text: T.String;
    error: Msg.Msg; handler: IQ.Handler; disco: Disco.Disco; ping: Ping.Pinger; i: LONGINT; route: ARRAY 64 OF CHAR;
BEGIN
  c := New(t, h, r); NEW(a); peer := Items.Latin1("example.org"); node := Items.Latin1("");
  request := Version.Query(r, peer^, 100, a, error);
  Reply(c, t, request, 'type="result" from="example.org"', '<query xmlns="jabber:iq:version"><name>Հայերեն😀</name><version>1</version></query>');
  ASSERT(Version.Read(request, name, version, os)); text := Items.UTF8("Հայերեն😀"); ASSERT(S.Equal(name^, text^) & (os[0] = 0)); INC(checks);
  request := Version.Query(r, peer^, 100, a, error);
  Reply(c, t, request, 'type="result" from="example.org"', '<query xmlns="jabber:iq:version"><name>A</name><name>B</name><version>1</version></query>');
  ASSERT(~Version.Read(request, name, version, os)); INC(checks);
  request := Disco.Query(r, peer^, node^, Disco.info, 100, a, error);
  Reply(c, t, request, 'type="result" from="example.org"', '<query xmlns="http://jabber.org/protocol/disco#info"><identity category="server" type="im"/><feature var="urn:xmpp:ping"/></query>');
  ASSERT(Disco.Read(request) # NIL); INC(checks);
  node := Items.Latin1("expected"); request := Disco.Query(r, peer^, node^, Disco.items, 100, a, error);
  Reply(c, t, request, 'type="result" from="example.org"', '<query xmlns="http://jabber.org/protocol/disco#items" node="wrong"/>');
  ASSERT(Disco.Read(request) = NIL); INC(checks);
  text := Items.Latin1("bad..example"); request := Ping.Query(r, text^, 100, a, error); ASSERT((request = NIL) & (error.code = IQ.invalidRequest));
  request := Ping.Query(r, peer^, 0, a, error); ASSERT((request = NIL) & (error.code = IQ.invalidRequest));
  request := Ping.Query(r, peer^, IQ.maxTimeoutMS+1, a, error); ASSERT((request = NIL) & (error.code = IQ.invalidRequest));
  handler := Ping.New(r); ASSERT(handler = NIL); INC(checks);
  request := Ping.Query(r, peer^, 100, a, error); t.script := Items.Copy8(""); t.position := 0;
  ASSERT(c.Step() = C.failed); ASSERT((request.status = IQ.sendFailed) & (r.count = 0) & (h.errors = 1)); t.output.Close; INC(checks);
  fresh := IQ.New(h); NEW(handler); ASSERT(fresh.Register(Disco.itemsURI, "query", handler));
  name := Items.Latin1("client"); version := Items.Latin1("console");
  disco := Disco.New(fresh, name^, version^, node^); ASSERT(disco = NIL);
  ASSERT(fresh.Register(Disco.infoURI, "query", handler)); ASSERT(fresh.Unregister(handler));
  FOR i := 0 TO IQ.maxHandlers-1 DO
    route := "urn:test:"; route[9] := CHR(ORD("a")+i); route[10] := 0X;
    ASSERT(fresh.Register(route, "query", handler))
  END;
  ASSERT(~fresh.Register("urn:overflow", "query", handler)); ASSERT(fresh.Unregister(handler)); INC(checks)
END ReadingAndLimits;

PROCEDURE ClosureAndWriteFailure;
  VAR c: C.Client; t: Fake; h: Hook; r: IQ.Router; a: Action; first, second: IQ.Request;
    peer: T.String; error: Msg.Msg;
BEGIN
  c := New(t, h, r); NEW(a); peer := Items.Latin1("example.org");
  first := Ping.Query(r, peer^, 100, a, error); ASSERT(error = NIL);
  Feed(c, t, '</s:stream>');
  ASSERT((c.state = C.closed) & (first.status = IQ.cancelled) & (a.calls = 1) & (h.closed = 1) & (r.count = 0));
  t.output.Close; INC(checks);
  c := New(t, h, r); NEW(a);
  first := Ping.Query(r, peer^, 100, a, error); ASSERT(error = NIL);
  t.failWrite := TRUE; second := Ping.Query(r, peer^, 100, a, error);
  ASSERT((error # NIL) & (second # NIL) & (first.status = IQ.sendFailed) & (second.status = IQ.sendFailed));
  ASSERT((a.calls = 2) & (r.count = 0) & (h.errors = 1) & (c.state = C.failed));
  r.Stop; ASSERT(a.calls = 2); t.output.Close; INC(checks)
END ClosureAndWriteFailure;

BEGIN
  checks := 0; Serving; Correlation; ReadingAndLimits; ClosureAndWriteFailure;
  Out.String("XMPP IQ, ping, version and discovery checks passed: "); Out.Int(checks, 0); Out.Ln
END TestXmppIQ.
