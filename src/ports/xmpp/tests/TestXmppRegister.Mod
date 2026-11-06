MODULE TestXmppRegister;

IMPORT SYSTEM, Out, Msg, Channel, S := LongStrings, Strings := oocStrings, Mem := IOMemory,
  T := XmppTypes, Items := XmppItems, Wire := XmppWire, C := XmppClient, Core := XmppCore,
  IQ := XmppIQ, Reg := XmppRegister, Ping := XmppPing, P := XmppPresenceTracker, M := XmppMucTracker;

TYPE
  Fake = POINTER TO FakeDesc;
  FakeDesc = RECORD (Wire.TransportDesc)
    script, post, identity: Items.Bytes; position, chunk, upgrades: LONGINT;
    trusted, ended, failWrite: BOOLEAN; output: Mem.Channel; writer: Channel.Writer
  END;
  Hook = POINTER TO HookDesc;
  HookDesc = RECORD (C.HookDesc)
    ready, registrationReady, received, sent, errors, closed: LONGINT; last: Core.Stanza
  END;
  Action = POINTER TO ActionDesc;
  ActionDesc = RECORD (IQ.ActionDesc) calls: LONGINT; last: IQ.Request END;

VAR checks: LONGINT;

PROCEDURE Check(ok: BOOLEAN; name: ARRAY OF CHAR);
BEGIN
  IF ~ok THEN Out.String("registration check failed: "); Out.String(name); Out.Ln; HALT(1) END;
  INC(checks)
END Check;

PROCEDURE (t: Fake) AuthenticatedFor(domain: ARRAY OF CHAR): BOOLEAN;
BEGIN
  IF t.identity # NIL THEN RETURN t.trusted & ~t.ended & (domain = t.identity^) END;
  RETURN t.trusted & ~t.ended & (domain = "example.org")
END AuthenticatedFor;
PROCEDURE (t: Fake) StartTLS(domain: ARRAY OF CHAR): BOOLEAN;
BEGIN
  IF (domain # "example.org") OR (t.post = NIL) THEN RETURN FALSE END;
  t.trusted := TRUE; INC(t.upgrades); t.script := t.post; t.position := 0; RETURN TRUE
END StartTLS;
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
PROCEDURE (h: Hook) RegistrationReady(client: C.Client);
BEGIN ASSERT((client.state = C.registering) & ~client.authenticated & (client.jid = NIL)); INC(h.registrationReady) END RegistrationReady;
PROCEDURE (h: Hook) Received(client: C.Client; stanza: Core.Stanza);
BEGIN INC(h.received) END Received;
PROCEDURE (h: Hook) Sent(client: C.Client; stanza: Core.Stanza);
BEGIN INC(h.sent); h.last := stanza END Sent;
PROCEDURE (h: Hook) Error(client: C.Client; error: Msg.Msg);
BEGIN INC(h.errors) END Error;
PROCEDURE (h: Hook) Closed(client: C.Client);
BEGIN INC(h.closed) END Closed;
PROCEDURE (a: Action) Done(router: IQ.Router; request: IQ.Request);
BEGIN INC(a.calls); a.last := request END Done;

PROCEDURE Header(features: ARRAY OF CHAR): Items.Bytes;
  VAR text: Items.Bytes;
BEGIN
  NEW(text, S.Length8(features)+256);
  COPY('<s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features>', text^);
  Strings.Append(features, text^); Strings.Append('</s:features>', text^); RETURN text
END Header;

PROCEDURE Open(VAR t: Fake; VAR h: Hook; VAR router: IQ.Router; VAR contacts: P.Tracker; VAR rooms: M.Tracker;
               features: ARRAY OF CHAR; trusted, registration: BOOLEAN): C.Client;
  VAR c: C.Client; p: P.Hook; m: M.Hook; ping: Ping.Pinger;
    user, password, resource: T.String; error: Msg.Msg; state: SHORTINT;
BEGIN
  NEW(t); NEW(h); NEW(p); NEW(m); t.chunk := 8192; t.trusted := trusted;
  rooms := M.New(h, m); contacts := P.New(rooms, p); router := IQ.New(contacts);
  ping := Ping.New(router); ASSERT(ping # NIL);
  t.output := Mem.Tmp("", {Mem.read, Mem.write}, error); ASSERT(error = NIL); t.writer := t.output.NewWriter();
  IF registration THEN
    IF trusted THEN t.script := Header(features)
    ELSE
      t.script := Header('<starttls xmlns="urn:ietf:params:xml:ns:xmpp-tls"/><register xmlns="http://jabber.org/features/iq-register"/>');
      NEW(t.post, S.Length8(t.script^)+128); COPY(t.script^, t.post^);
      Strings.Append('<proceed xmlns="urn:ietf:params:xml:ns:xmpp-tls"/>', t.post^);
      t.script := t.post; t.post := Header(features)
    END;
    c := C.NewRegistration(t, router, "example.org", error)
  ELSE
    t.script := Items.Copy8('<s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features><mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><mechanism>PLAIN</mechanism></mechanisms></s:features><success xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/><s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></s:features><iq id="voc-bind-1" type="result"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>user@example.org/r</jid></bind></iq>');
    user := Items.Latin1("user"); password := Items.Latin1("password"); resource := Items.Latin1("r");
    c := C.New(t, router, "example.org", user^, password^, resource^, TRUE, error)
  END;
  ASSERT((c # NIL) & (error = NIL) & c.Start());
  REPEAT state := c.Step() UNTIL (state = C.online) OR (state = C.registering) OR (state = C.failed);
  RETURN c
END Open;

PROCEDURE New(VAR t: Fake; VAR h: Hook; VAR router: IQ.Router): C.Client;
  VAR c: C.Client; contacts: P.Tracker; rooms: M.Tracker;
BEGIN
  c := Open(t, h, router, contacts, rooms, '<register xmlns="http://jabber.org/features/iq-register"/>', TRUE, TRUE);
  Check((c.state = C.registering) & (h.ready = 0) & (h.registrationReady = 1) & ~contacts.active & ~rooms.active,
    "keeping registration separate from authenticated presence"); RETURN c
END New;

PROCEDURE Dispose(c: C.Client; t: Fake; router: IQ.Router);
BEGIN router.Stop; c.Abort; t.output.Close END Dispose;

PROCEDURE Feed(c: C.Client; t: Fake; text: ARRAY OF CHAR);
  VAR state: SHORTINT; steps: LONGINT;
BEGIN
  t.script := Items.Copy8(text); t.position := 0; steps := 0;
  REPEAT state := c.Step(); INC(steps); ASSERT(steps < 100000)
  UNTIL (t.position = S.Length8(t.script^)) OR (state = C.failed);
  ASSERT(state # C.failed)
END Feed;

PROCEDURE Reply(c: C.Client; t: Fake; request: IQ.Request; attributes, content: ARRAY OF CHAR);
  VAR xml: Items.Bytes; id: Items.Bytes;
BEGIN
  id := Items.UTF8Bytes(request.id^); NEW(xml, S.Length8(content)+S.Length8(attributes)+S.Length8(id^)+64);
  COPY('<iq id="', xml^); Strings.Append(id^, xml^); Strings.Append('" ', xml^); Strings.Append(attributes, xml^);
  Strings.Append('>', xml^); Strings.Append(content, xml^); Strings.Append('</iq>', xml^); Feed(c, t, xml^)
END Reply;

PROCEDURE Fetch(c: C.Client; t: Fake; router: IQ.Router; a: Action; xml: ARRAY OF CHAR): Reg.Form;
  VAR request: IQ.Request; empty: T.String; error: Msg.Msg;
BEGIN
  empty := Items.Latin1(""); request := Reg.Query(router, empty^, 100, a, error); ASSERT((request # NIL) & (error = NIL));
  Reply(c, t, request, 'type="result" from="example.org"', xml); RETURN Reg.Read(request)
END Fetch;

PROCEDURE Negotiation;
  VAR c: C.Client; t: Fake; h: Hook; router: IQ.Router; contacts: P.Tracker; rooms: M.Tracker;
    features: Items.Bytes;
BEGIN
  c := Open(t, h, router, contacts, rooms, '<register xmlns="http://jabber.org/features/iq-register"/>', FALSE, TRUE);
  Check((c.state = C.registering) & (t.upgrades = 1) & (h.registrationReady = 1) & (h.ready = 0) & ~c.authenticated,
    "reaching registration only after STARTTLS"); Dispose(c, t, router);
  c := Open(t, h, router, contacts, rooms, "", TRUE, TRUE);
  Check((c.state = C.failed) & (c.error.code = C.registrationUnavailable) & (h.registrationReady = 0), "requiring advertised registration");
  Dispose(c, t, router);
  c := Open(t, h, router, contacts, rooms, "", FALSE, TRUE);
  Check((c.state = C.failed) & (t.upgrades = 1) & (c.error.code = C.registrationUnavailable), "discarding pre-TLS capability advertisements");
  Dispose(c, t, router);
  c := Open(t, h, router, contacts, rooms, '<register xmlns="urn:wrong"/>', TRUE, TRUE);
  Check((c.state = C.failed) & (h.registrationReady = 0), "rejecting registration namespace lookalikes"); Dispose(c, t, router);
  c := Open(t, h, router, contacts, rooms, '<register xmlns="http://jabber.org/features/iq-register"/><register xmlns="http://jabber.org/features/iq-register"/>', TRUE, TRUE);
  Check(c.state = C.failed, "rejecting duplicate registration advertisements"); Dispose(c, t, router);
  c := Open(t, h, router, contacts, rooms, '<register xmlns="http://jabber.org/features/iq-register"><nested/></register>', TRUE, TRUE);
  Check(c.state = C.failed, "rejecting malformed registration advertisements"); Dispose(c, t, router);
  c := New(t, h, router); t.script := Items.Copy8('<message><body>anonymous</body></message>'); t.position := 0;
  Check((c.Step() = C.failed) & (c.error.code = C.protocolError) & (h.received = 0), "not delivering anonymous messages to login hooks");
  Dispose(c, t, router)
END Negotiation;

PROCEDURE Exchange;
  VAR c: C.Client; t: Fake; h: Hook; router: IQ.Router; a: Action; request, submission: IQ.Request; form: Reg.Form;
    empty, user, password, value, held: T.String; query, field: Items.Item; error: Msg.Msg; calls, sent, i: LONGINT;
BEGIN
  c := New(t, h, router); NEW(a); empty := Items.Latin1("");
  request := Reg.Query(router, empty^, 100, a, error);
  Check((request # NIL) & (error = NIL) & (request.client = c) & S.Equal8(request.peer^, "example.org"), "querying the verified server");
  calls := a.calls;
  Reply(c, t, request, 'type="result" from="attacker.example"', "");
  Reply(c, t, request, 'type="result" from="example.org/resource"', "");
  Reply(c, t, request, 'type="result" from="example.org" to="user@example.org/r"', "");
  Check((a.calls = calls) & (request.status = IQ.pending), "rejecting spoofed registration replies");
  Reply(c, t, request, 'type="result"', '<query xmlns="jabber:iq:register"><instructions>Լրացրու 😀</instructions><username/><password/><email/><key>token</key></query>');
  form := Reg.Read(request); value := Items.UTF8("Լրացրու 😀");
  Check((form # NIL) & form.legacy & (form.count = 4) & S.Equal(form.instructions^, value^), "reading legacy registration fields");
  value := form.Get("key"); Check(S.Equal8(value^, "token"), "preserving the server key");
  user := Items.UTF8("Անի😀"); password := Items.UTF8('գաղտնի<&"😀');
  Check(form.Set("username", user^) & form.Set("password", password^), "filling credentials explicitly");
  Check(form.Set("password", form.fields[1].value^), "replacing a value through its existing alias");
  value := form.Get("password"); Check(S.Equal(value^, password^), "retaining an alias-safe replacement");
  value := Items.Latin1("ani@example.net"); Check(form.Set("email", value^), "filling an advertised optional field");
  Check(~form.Set("remove", empty^) & ~form.Set("unadvertised", empty^), "refusing non-field submission entries");
  submission := Reg.Submit(router, form, 100, a, error); Check((submission # NIL) & (error = NIL), "submitting selected registration fields");
  query := submission.payload; field := query.First(Reg.namespaceURI, "password");
  Check(field.content.text[0] = 0, "wiping the retained outgoing password");
  value := form.Get("password"); Check(S.Equal(value^, password^), "not consuming the editable answer form");
  Reply(c, t, submission, 'type="result" from="example.org"', "");
  Check(IQ.EmptyResult(submission) & (c.state = C.registering) & ~c.authenticated & (h.ready = 0), "not logging in after successful registration");
  held := form.fields[1].value; field := request.reply.item.First(Reg.namespaceURI, "query"); field := field.First(Reg.namespaceURI, "key");
  value := field.content.text; form.Clear;
  Check((held[0] = 0) & (value[0] = 0) & (form.Get("password") = NIL), "clearing form values and parsed response aliases");
  sent := h.sent; Check(Reg.Submit(router, form, 100, a, error) = NIL, "rejecting cleared forms");
  Check(Reg.Remove(router, empty^, 100, a, error) = NIL, "requiring authentication for removal");
  Check((h.sent = sent) & (error.code = Reg.authenticationRequired), "not sending anonymous account removal");
  request := Reg.Query(router, empty^, 1, a, error); router.Tick(1); Check(request.status = IQ.timedOut, "expiring registration IQs");
  request := Reg.Query(router, empty^, 100, a, error); Check(router.Cancel(request) & (request.status = IQ.cancelled), "cancelling registration IQs");
  request := Reg.Query(router, empty^, 100, a, error);
  Reply(c, t, request, 'type="error" from="example.org"', '<error type="cancel"><conflict xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/></error>');
  Check((request.status = IQ.stanzaError) & (Reg.Read(request) = NIL), "exposing registration conflicts without retrying");
  c.Close(error); ASSERT(error = NIL); Feed(c, t, '</s:stream>');
  Check((c.state = C.closed) & (h.closed = 1) & (router.count = 0), "closing a registration-only stream"); t.output.Close
END Exchange;

PROCEDURE FormsAndLimits;
  VAR c: C.Client; t: Fake; h: Hook; router: IQ.Router; a: Action; form: Reg.Form; request: IQ.Request;
    empty, value: T.String; error: Msg.Msg; i, j, k: LONGINT; xml: ARRAY 32768 OF CHAR; name: ARRAY 32 OF CHAR;
BEGIN
  c := New(t, h, router); NEW(a); empty := Items.Latin1("");
  FOR i := 1 TO 128 DO
    t.chunk := i;
    form := Fetch(c, t, router, a, '<query xmlns="jabber:iq:register"><username>Անի😀</username><password/><registered/></query>');
    value := Items.UTF8("Անի😀");
    Check((form # NIL) & form.registered & form.legacy & S.Equal(form.fields[0].value^, value^), "fragmented Unicode fields")
  END;
  Check(Fetch(c, t, router, a, '<query xmlns="jabber:iq:register"><username/><username/></query>') = NIL, "duplicate fields");
  Check(Fetch(c, t, router, a, '<query xmlns="jabber:iq:register"><instructions>A</instructions><instructions>B</instructions></query>') = NIL, "duplicate instructions");
  Check(Fetch(c, t, router, a, '<query xmlns="jabber:iq:register"><username/><registered/><registered/></query>') = NIL, "duplicate registered flags");
  Check(Fetch(c, t, router, a, '<query xmlns="jabber:iq:register"><username><nested/></username></query>') = NIL, "nested legacy field values");
  Check(Fetch(c, t, router, a, '<query xmlns="jabber:iq:register"><username/>text</query>') = NIL, "non-structural query text");
  form := Fetch(c, t, router, a, '<query xmlns="jabber:iq:register"><username/><password/><x xmlns="jabber:x:data" type="form"/></query>');
  Check((form # NIL) & form.dataForm & ~form.legacy & (Reg.Submit(router, form, 100, a, error) = NIL), "not downgrading data forms to legacy fields");
  form := Fetch(c, t, router, a, '<query xmlns="jabber:iq:register"><x xmlns="jabber:x:oob"><url>https://example.org/register</url></x></query>');
  Check((form # NIL) & form.outOfBand & ~form.legacy, "reporting out-of-band registration without fetching");
  form := Fetch(c, t, router, a, '<query xmlns="jabber:iq:register"><username/><future/></query>');
  Check((form # NIL) & ~form.legacy, "not silently dropping unknown registration requirements");
  form := Fetch(c, t, router, a, '<query xmlns="jabber:iq:register"><registered/></query>');
  Check((form # NIL) & form.registered & ~form.legacy, "reading an already-registered response without fields");
  form := Fetch(c, t, router, a, '<query xmlns="jabber:iq:register"><username/><password/></query>');
  NEW(value, Reg.maxFieldUnits+2); FOR i := 0 TO Reg.maxFieldUnits DO value[i] := ORD("a") END; value[Reg.maxFieldUnits+1] := 0;
  Check(~form.Set("username", value^), "bounding submitted field text"); value[Reg.maxFieldUnits] := 0;
  Check(form.Set("username", value^), "accepting a field at its limit");
  value[0] := 0D800H; value[1] := 0; Check(~form.Set("password", value^), "rejecting unpaired surrogates");
  COPY('<query xmlns="jabber:iq:register">', xml);
  FOR i := 0 TO 3 DO
    CASE i OF 0: name := "username" | 1: name := "password" | 2: name := "email" | 3: name := "key" ELSE HALT(1) END;
    Strings.Append('<', xml); Strings.Append(name, xml); Strings.Append('>', xml);
    j := S.Length8(xml); FOR k := 0 TO Reg.maxFieldUnits-1 DO xml[j+k] := "a" END; xml[j+Reg.maxFieldUnits] := 0X;
    Strings.Append('</', xml); Strings.Append(name, xml); Strings.Append('>', xml)
  END;
  Strings.Append('</query>', xml); form := Fetch(c, t, router, a, xml);
  Check((form # NIL) & form.legacy, "accepting the total legacy field budget");
  i := S.Length8(xml)-S.Length8('</query>'); xml[i] := 0X;
  Strings.Append('<instructions>x</instructions></query>', xml);
  Check(Fetch(c, t, router, a, xml) = NIL, "rejecting total field budget overflow");
  COPY('<query xmlns="jabber:iq:register"><username>', xml); j := S.Length8(xml);
  FOR k := 0 TO Reg.maxFieldUnits DO xml[j+k] := "a" END; xml[j+Reg.maxFieldUnits+1] := 0X;
  Strings.Append('</username></query>', xml);
  Check(Fetch(c, t, router, a, xml) = NIL, "bounding received scalar values");
  Dispose(c, t, router)
END FormsAndLimits;

PROCEDURE RestrictionsAndRemoval;
  VAR c, other: C.Client; t, second: Fake; h, otherHook: Hook; router, otherRouter: IQ.Router;
    contacts: P.Tracker; rooms: M.Tracker; a: Action; request: IQ.Request; form: Reg.Form;
    empty, peer, id, type: T.String; error: Msg.Msg; stanza: Core.Stanza; query: Items.Item; sent: LONGINT;
BEGIN
  c := New(t, h, router); NEW(a); empty := Items.Latin1(""); peer := Items.Latin1("other.example");
  Feed(c, t, '<iq type="get" from="example.org" id="anonymous-ping"><ping xmlns="urn:xmpp:ping"/></iq>');
  Check((h.received = 1) & (h.sent = 0), "not serving authenticated IQ handlers before login");
  Check(Reg.Query(router, peer^, 100, a, error) = NIL, "not registering with an unverified pre-login peer");
  Check(router.Query(empty^, Items.New("ping", "urn:xmpp:ping"), FALSE, 100, a, error) = NIL, "restricting anonymous IQ queries");
  sent := h.sent; stanza := Core.NewStanza("message"); c.Send(stanza, error);
  Check((error # NIL) & (h.sent = sent) & (c.state = C.registering), "not sending anonymous chat messages");
  stanza := Core.NewStanza("iq"); id := Items.Latin1("raw"); type := Items.Latin1("get");
  stanza.item.SetParam("id", id^); stanza.item.SetParam("type", type^); stanza.item.SetParam("to", peer^);
  stanza.item.AddChild(Items.New("query", Reg.namespaceURI)); c.Send(Core.Wrap(stanza.item, NIL), error);
  Check((error # NIL) & (h.sent = sent), "checking raw registration destinations");
  stanza.item.SetParam("to", empty^); c.Send(Core.Wrap(stanza.item, NIL), error);
  Check((error # NIL) & (h.sent = sent), "rejecting explicit empty registration destinations");
  peer := Items.Latin1("example.org"); stanza.item.SetParam("to", peer^); stanza.item.AddText(id^, 0, S.Length(id^));
  c.Send(Core.Wrap(stanza.item, NIL), error); Check((error # NIL) & (h.sent = sent), "rejecting raw query root text");
  form := Fetch(c, t, router, a, '<query xmlns="jabber:iq:register"><username/><password/></query>');
  other := New(second, otherHook, otherRouter);
  Check(Reg.Submit(otherRouter, form, 100, a, error) = NIL, "binding registration fields to their original connection");
  Dispose(other, second, otherRouter); Dispose(c, t, router);
  c := Open(t, h, router, contacts, rooms, "", TRUE, FALSE);
  Check((c.state = C.online) & c.authenticated & contacts.active & rooms.active & (h.ready = 1) & (h.registrationReady = 0), "preserving authenticated login");
  request := router.Query(empty^, Items.New("query", Reg.namespaceURI), FALSE, 100, a, error);
  Reply(c, t, request, 'type="result" from="user@example.org/r"', '<query xmlns="jabber:iq:register"><username/><password/></query>');
  Check(Reg.Read(request) = NIL, "not accepting a local resource as the registration service");
  peer := Items.Latin1("gateway.example"); request := router.Query(peer^, Items.New("query", Reg.namespaceURI), FALSE, 100, a, error);
  Reply(c, t, request, 'type="result" from="gateway.example"', '<query xmlns="jabber:iq:register"><username/><password/></query>');
  Check(Reg.Read(request) # NIL, "accepting an explicitly selected registration service");
  form := Fetch(c, t, router, a, '<query xmlns="jabber:iq:register"><registered/><username>user</username><password/></query>');
  Check((form # NIL) & form.registered & form.legacy, "reading authenticated account-change fields");
  peer := Items.UTF8("նոր գաղտնի😀"); Check(form.Set("password", peer^), "selecting a new password explicitly");
  request := Reg.Submit(router, form, 100, a, error); Check((request # NIL) & (error = NIL), "submitting authenticated account changes");
  Reply(c, t, request, 'type="result" from="example.org"', "");
  Check(IQ.EmptyResult(request) & c.authenticated, "completing an authenticated password change"); form.Clear;
  request := Reg.Remove(router, empty^, 100, a, error);
  Check((request # NIL) & (error = NIL) & (request.payload.First(Reg.namespaceURI, "remove") # NIL), "requesting removal only after authentication");
  Reply(c, t, request, 'type="result" from="example.org"', "");
  Check(IQ.EmptyResult(request) & (c.state = C.online), "leaving post-removal connection policy to the caller");
  contacts.Stop; rooms.Stop; Dispose(c, t, router)
END RestrictionsAndRemoval;

PROCEDURE PreparedDomain;
  VAR c: C.Client; t: Fake; h: Hook; router: IQ.Router; a: Action; request: IQ.Request;
    empty, expected: T.String; error: Msg.Msg; form: Reg.Form; state: SHORTINT;
BEGIN
  NEW(t); NEW(h); NEW(a); t.trusted := TRUE; t.chunk := 8192; t.identity := Items.Copy8("xn--bcher-kva.example");
  t.script := Header('<register xmlns="http://jabber.org/features/iq-register"/>');
  t.output := Mem.Tmp("", {Mem.read, Mem.write}, error); ASSERT(error = NIL); t.writer := t.output.NewWriter();
  router := IQ.New(h); c := C.NewRegistration(t, router, t.identity^, error); ASSERT((c # NIL) & (error = NIL) & c.Start());
  REPEAT state := c.Step() UNTIL (state = C.registering) OR (state = C.failed);
  Check(state = C.registering, "accepting a prepared ASCII transport identity");
  empty := Items.Latin1(""); request := Reg.Query(router, empty^, 100, a, error);
  expected := Items.UTF8("bücher.example");
  Check((request # NIL) & (error = NIL) & S.Equal(request.peer^, expected^) &
    (h.last.item.GetAttribute("", "to") = NIL), "using the implicit verified service with a canonical reply identity");
  Reply(c, t, request, 'type="result" from="xn--bcher-kva.example"', '<query xmlns="jabber:iq:register"><username/><password/></query>');
  form := Reg.Read(request); Check((form # NIL) & form.legacy, "matching prepared-domain registration replies");
  form.Clear; Dispose(c, t, router)
END PreparedDomain;

BEGIN
  checks := 0; Negotiation; Exchange; FormsAndLimits; RestrictionsAndRemoval; PreparedDomain;
  Out.String("XMPP registration checks passed: "); Out.Int(checks, 0); Out.Ln
END TestXmppRegister.
