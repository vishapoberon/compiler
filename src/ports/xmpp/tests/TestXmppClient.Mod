MODULE TestXmppClient;

IMPORT SYSTEM, Out, Msg, Channel, S := LongStrings, Mem := IOMemory,
  T := XmppTypes, Items := XmppItems, Wire := XmppWire, Sasl := XmppSasl,
  C := XmppClient, Core := XmppCore, Messenger := XmppMessenger;

TYPE
  Fake = POINTER TO FakeDesc;
  FakeDesc = RECORD (Wire.TransportDesc)
    script, next: Items.Bytes;
    trustedDomain: Items.Bytes;
    output: Mem.Channel;
    writer: Channel.Writer;
    position, chunk, upgrades: LONGINT;
    secure, upgradeOK, ended: BOOLEAN;
  END;
  Hook = POINTER TO HookDesc;
  HookDesc = RECORD (C.HookDesc)
    ready, received, sent, errors, closed: LONGINT;
    last: Core.Stanza;
  END;

VAR checks: LONGINT;

PROCEDURE (t: Fake) AuthenticatedFor(domain: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN t.secure & ~t.ended & (domain = t.trustedDomain^) END AuthenticatedFor;

PROCEDURE (t: Fake) StartTLS(domain: ARRAY OF CHAR): BOOLEAN;
BEGIN
  ASSERT(~t.secure & (domain = "example.org")); INC(t.upgrades);
  IF ~t.upgradeOK THEN t.res := Wire.Error(); RETURN FALSE END;
  ASSERT(t.position = S.Length8(t.script^));
  t.secure := TRUE; t.script := t.next; t.position := 0; RETURN TRUE
END StartTLS;

PROCEDURE (t: Fake) Read(VAR bytes: ARRAY OF CHAR; VAR count: LONGINT): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  ASSERT(~t.ended); count := S.Length8(t.script^)-t.position;
  IF count > t.chunk THEN count := t.chunk END;
  IF count > LEN(bytes) THEN count := LEN(bytes) END;
  FOR i := 0 TO count-1 DO bytes[i] := t.script[t.position+i] END;
  INC(t.position, count); RETURN TRUE
END Read;

PROCEDURE (t: Fake) WriteBytes(VAR bytes: ARRAY OF SYSTEM.BYTE; start, count: LONGINT);
BEGIN
  ASSERT(~t.ended);
  t.writer.WriteBytes(bytes, start, count); t.bytesWritten := t.writer.bytesWritten;
  t.res := t.writer.res
END WriteBytes;

PROCEDURE (t: Fake) Close;
BEGIN t.ended := TRUE; t.secure := FALSE END Close;

PROCEDURE (h: Hook) Ready(client: C.Client; jid: T.String);
BEGIN INC(h.ready); ASSERT(client.state = C.online) END Ready;
PROCEDURE (h: Hook) Received(client: C.Client; stanza: Core.Stanza);
BEGIN INC(h.received); h.last := stanza END Received;
PROCEDURE (h: Hook) Sent(client: C.Client; stanza: Core.Stanza);
BEGIN INC(h.sent) END Sent;
PROCEDURE (h: Hook) Error(client: C.Client; error: Msg.Msg);
BEGIN INC(h.errors) END Error;
PROCEDURE (h: Hook) Closed(client: C.Client);
BEGIN INC(h.closed) END Closed;

PROCEDURE New(script, next: ARRAY OF CHAR; secure, allowPlain: BOOLEAN; chunk: LONGINT;
               VAR t: Fake; VAR h: Hook): C.Client;
  VAR c: C.Client; error: Msg.Msg; user, password, resource: T.String;
BEGIN
  NEW(t); NEW(h); t.script := Items.Copy8(script); t.next := Items.Copy8(next);
  t.trustedDomain := Items.Copy8("example.org");
  t.chunk := chunk; t.secure := secure; t.upgradeOK := TRUE;
  t.output := Mem.Tmp("", {Mem.read, Mem.write}, error); ASSERT(error = NIL);
  t.writer := t.output.NewWriter();
  user := Items.Latin1("user"); password := Items.Latin1("password"); resource := Items.UTF8("Հայերեն😀");
  c := C.New(t, h, "example.org", user^, password^, resource^, allowPlain, error);
  ASSERT((c # NIL) & (error = NIL)); RETURN c
END New;

PROCEDURE Run(c: C.Client);
  VAR state: SHORTINT; steps: LONGINT;
BEGIN
  ASSERT(c.Start()); steps := 0;
  REPEAT state := c.Step(); INC(steps); ASSERT(steps < 100000)
  UNTIL (state = C.online) OR (state = C.failed) OR (state = C.closed)
END Run;

PROCEDURE Contains(t: Fake; needle: ARRAY OF CHAR): BOOLEAN;
  VAR i, j, length: LONGINT;
BEGIN
  length := S.Length8(needle);
  FOR i := 0 TO t.output.Length()-length DO
    j := 0;
    WHILE (j < length) & (t.output.file.data[i+j] = needle[j]) DO INC(j) END;
    IF j = length THEN RETURN TRUE END
  END;
  RETURN FALSE
END Contains;

PROCEDURE SuccessChecks;
  VAR first: ARRAY 512 OF CHAR; next: ARRAY 2048 OF CHAR; chunk, n: LONGINT;
    c: C.Client; t: Fake; h: Hook; state: SHORTINT; error: Msg.Msg; stanza: Core.Stanza;
    to, text: T.String;
BEGIN
  first := '<s:stream xmlns:s="http://etherx.jabber.org/streams" version="1.0"><s:features><starttls xmlns="urn:ietf:params:xml:ns:xmpp-tls"><required/></starttls></s:features><proceed xmlns="urn:ietf:params:xml:ns:xmpp-tls"/>';
  next := '<t:stream xmlns:t="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><t:features><mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><mechanism>PLAIN</mechanism></mechanisms></t:features><success xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/><q:stream xmlns:q="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0" xml:lang="hy"><q:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></q:features><iq id="voc-bind-1" type="result"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>user@example.org/Հայերեն😀</jid></bind></iq><message><body>Բարեւ 😀</body></message></q:stream>';
  n := S.Length8(next);
  FOR chunk := 1 TO n DO
    c := New(first, next, FALSE, TRUE, chunk, t, h); Run(c);
    ASSERT((c.state = C.online) & c.authenticated & (h.ready = 1) & (h.errors = 0));
    text := Items.UTF8("user@example.org/Հայերեն😀"); ASSERT(S.Equal(c.jid^, text^));
    ASSERT((t.upgrades = 1) & Contains(t, "<starttls") & Contains(t, "AHVzZXIAcGFzc3dvcmQ="));
    ASSERT(~Contains(t, "password") & (h.sent = 0));
    to := Items.Latin1("other@example.org"); text := Items.UTF8("Բարեւ 😀");
    stanza := Messenger.NewMessage(to^, text^); c.Send(stanza, error); ASSERT((error = NIL) & (h.sent = 1));
    REPEAT state := c.Step() UNTIL h.received > 0;
    ASSERT(state = C.online); ASSERT(S.Equal8(h.last.lang^, "hy"));
    text := Messenger.Body(h.last); to := Items.UTF8("Բարեւ 😀"); ASSERT(S.Equal(text^, to^));
    c.Close(error); ASSERT(error = NIL);
    REPEAT state := c.Step() UNTIL (state = C.closed) OR (state = C.failed);
    ASSERT((state = C.closed) & (h.closed = 1) & t.ended); t.output.Close; INC(checks)
  END;
  (* Direct TLS uses the same SASL and bind sequence without a plaintext stream. *)
  c := New(next, "", TRUE, TRUE, 8192, t, h); Run(c);
  ASSERT((c.state = C.online) & (t.upgrades = 0) & (h.sent = 0)); c.Abort; t.output.Close; INC(checks);
  (* A peer-initiated close receives the client's closing tag before TLS shutdown. *)
  c := New(next, "", TRUE, TRUE, 8192, t, h); Run(c);
  REPEAT state := c.Step() UNTIL (state = C.closed) OR (state = C.failed);
  ASSERT((state = C.closed) & (h.received = 1) & (h.closed = 1) & Contains(t, "</stream:stream>"));
  t.output.Close; INC(checks);
  (* Already buffered application stanzas can arrive during orderly shutdown. *)
  c := New(next, "", TRUE, TRUE, 8192, t, h); Run(c); c.Close(error); ASSERT(error = NIL);
  REPEAT state := c.Step() UNTIL (state = C.closed) OR (state = C.failed);
  ASSERT((state = C.closed) & (h.received = 1) & (h.closed = 1)); t.output.Close; INC(checks)
END SuccessChecks;

PROCEDURE Reject(script: ARRAY OF CHAR; secure, allowPlain: BOOLEAN; code: SHORTINT);
  VAR c: C.Client; t: Fake; h: Hook;
BEGIN
  c := New(script, "", secure, allowPlain, 8192, t, h); Run(c);
  ASSERT((c.state = C.failed) & (c.error # NIL) & (h.ready = 0) & (h.errors = 1) & t.ended);
  IF code # 0 THEN ASSERT(c.error.code = code) END;
  ASSERT(c.Step() = C.failed); ASSERT(h.errors = 1); t.output.Close; INC(checks)
END Reject;

PROCEDURE RejectBinding(tail: ARRAY OF CHAR);
  VAR script: ARRAY 2048 OF CHAR; i, offset: LONGINT;
BEGIN
  script := '<s:stream xmlns:s="http://etherx.jabber.org/streams" version="1.0"><s:features><mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><mechanism>PLAIN</mechanism></mechanisms></s:features><success xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/><q:stream xmlns:q="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0">';
  offset := S.Length8(script); ASSERT(offset+S.Length8(tail) < LEN(script));
  FOR i := 0 TO S.Length8(tail) DO script[offset+i] := tail[i] END;
  Reject(script, TRUE, TRUE, C.bindingFailed)
END RejectBinding;

PROCEDURE RejectionChecks;
  VAR c: C.Client; t: Fake; h: Hook; state: SHORTINT; script: Items.Bytes; i, length: LONGINT;
    user, password, resource: T.String; error: Msg.Msg;
BEGIN
  Reject('<s:stream xmlns:s="http://etherx.jabber.org/streams" version="1.0"><s:features/>', FALSE, TRUE, C.tlsRequired);
  Reject('<s:stream xmlns:s="http://etherx.jabber.org/streams" version="1.0"><s:features><starttls xmlns="urn:spoof"/></s:features>', FALSE, TRUE, C.tlsRequired);
  Reject('<s:stream xmlns:s="http://etherx.jabber.org/streams"><s:features/>', TRUE, TRUE, C.protocolError);
  Reject('<s:stream xmlns:s="http://etherx.jabber.org/streams" version="1.0"><message xmlns="jabber:client"/>', TRUE, TRUE, C.protocolError);
  Reject('<s:stream xmlns:s="http://etherx.jabber.org/streams" version="1.0"><s:features><mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><mechanism>PLAIN</mechanism></mechanisms></s:features>', TRUE, FALSE, C.mechanismRequired);
  Reject('<s:stream xmlns:s="http://etherx.jabber.org/streams" version="1.0"><s:features><mechanisms xmlns="urn:spoof"><mechanism>PLAIN</mechanism></mechanisms></s:features>', TRUE, TRUE, C.mechanismRequired);
  Reject('<s:stream xmlns:s="http://etherx.jabber.org/streams" version="1.0"><s:features><mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><mechanism>SCRAM-SHA-256</mechanism></mechanisms></s:features>', TRUE, TRUE, C.mechanismRequired);
  Reject('<s:stream xmlns:s="http://etherx.jabber.org/streams" version="1.0"><s:features><mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><mechanism>PLAIN</mechanism></mechanisms></s:features><failure xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><not-authorized/></failure>', TRUE, TRUE, C.authenticationFailed);
  Reject('<s:stream xmlns:s="http://etherx.jabber.org/streams" version="1.0"><s:features><starttls xmlns="urn:ietf:params:xml:ns:xmpp-tls"/></s:features><proceed xmlns="urn:ietf:params:xml:ns:xmpp-tls"/>injected', FALSE, TRUE, C.protocolError);
  Reject('<s:stream xmlns:s="http://etherx.jabber.org/streams" version="1.0"><s:error/></s:stream>', TRUE, TRUE, C.protocolError);
  Reject('<s:stream xmlns:s="http://etherx.jabber.org/streams" version="1.0">', TRUE, TRUE, C.transportError);
  Reject('<s:stream xmlns:s="http://etherx.jabber.org/streams" version="1.0" from="wrong.example">', TRUE, TRUE, C.protocolError);
  RejectBinding('<q:features/>');
  RejectBinding('<q:features><bind xmlns="urn:spoof"/></q:features>');
  RejectBinding('<q:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></q:features>');
  RejectBinding('<q:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></q:features><iq id="wrong" type="result"/>');
  RejectBinding('<q:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></q:features><iq id="voc-bind-1" type="error"/>');
  RejectBinding('<q:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></q:features><iq id="voc-bind-1" type="result"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>user@wrong.example/resource</jid></bind></iq>');
  RejectBinding('<q:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></q:features><iq id="voc-bind-1" type="result"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>user@example.org</jid></bind></iq>');
  RejectBinding('<q:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></q:features><iq id="voc-bind-1" type="result"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>user@example.org/r</jid><jid>user@example.org/s</jid></bind></iq>');
  RejectBinding('<q:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></q:features><iq id="voc-bind-1" type="result"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid><x/>user@example.org/r</jid></bind></iq>');
  c := New('<s:stream xmlns:s="http://etherx.jabber.org/streams" version="1.0"><s:features><starttls xmlns="urn:ietf:params:xml:ns:xmpp-tls"/></s:features><proceed xmlns="urn:ietf:params:xml:ns:xmpp-tls"/>', "", FALSE, TRUE, 8192, t, h);
  t.upgradeOK := FALSE; Run(c); ASSERT((c.state = C.failed) & (c.error = t.res));
  ASSERT(~Contains(t, "<auth") & (t.upgrades = 1)); t.output.Close; INC(checks);
  c := New('<s:stream xmlns:s="http://etherx.jabber.org/streams" version="1.0"><s:features/>', "", TRUE, TRUE, 8192, t, h);
  t.trustedDomain := Items.Copy8("other.example"); Run(c);
  ASSERT((c.state = C.failed) & (c.error.code = C.tlsRequired) & ~Contains(t, "<auth")); t.output.Close; INC(checks);
  c := New('<s:stream xmlns:s="http://etherx.jabber.org/streams" version="1.0">', "", TRUE, TRUE, 8192, t, h);
  length := S.Length8(t.script^); NEW(script, C.maxNegotiationBytes+1024);
  FOR i := 0 TO length-1 DO script[i] := t.script[i] END;
  FOR i := length TO LEN(script^)-2 DO script[i] := " " END; script[LEN(script^)-1] := 0X;
  t.script := script; Run(c); ASSERT((c.state = C.failed) & (c.error.code = C.negotiationLimit));
  ASSERT(~Contains(t, "<auth") & (t.position = C.maxNegotiationBytes)); t.output.Close; INC(checks);
  user := Items.Latin1("user"); password := Items.Latin1("password"); resource := Items.Latin1("");
  c := C.New(t, h, "bad@domain", user^, password^, resource^, TRUE, error); ASSERT((c = NIL) & (error # NIL)); INC(checks)
END RejectionChecks;

PROCEDURE SaslChecks;
  VAR user, password, response: T.String; error: Msg.Msg;
BEGIN
  user := Items.Latin1("user"); password := Items.Latin1("password");
  Sasl.Plain(user^, password^, TRUE, response, error);
  ASSERT((error = NIL) & S.Equal8(response^, "AHVzZXIAcGFzc3dvcmQ="));
  Sasl.Plain(user^, password^, FALSE, response, error); ASSERT((error # NIL) & (response = NIL));
  user := Items.Latin1("a"); password := Items.Latin1("b");
  Sasl.Plain(user^, password^, TRUE, response, error); ASSERT((error = NIL) & S.Equal8(response^, "AGEAYg=="));
  user[0] := 0D800H; Sasl.Plain(user^, password^, TRUE, response, error); ASSERT((error # NIL) & (response = NIL));
  Sasl.Wipe(password); ASSERT(password[0] = 0); INC(checks, 5)
END SaslChecks;

BEGIN
  checks := 0; SuccessChecks; RejectionChecks; SaslChecks;
  Out.String("XMPP TLS/SASL/bind negotiation checks passed: "); Out.Int(checks, 0); Out.Ln
END TestXmppClient.
