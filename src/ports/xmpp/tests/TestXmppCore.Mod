MODULE TestXmppCore;

IMPORT Out, Msg, S := LongStrings, Mem := IOMemory, T := XmppTypes,
  Items := XmppItems, XML := XmppXmlStream, Core := XmppCore,
  Messenger := XmppMessenger, Presence := XmppPresence, J := XmppStrings;

TYPE
  Hook = POINTER TO HookDesc;
  HookDesc = RECORD (Core.HookDesc)
    opened, received, sent, other, closed, errors: LONGINT;
    last: Core.Stanza;
    restarted, restartOnClose: BOOLEAN;
  END;

PROCEDURE (h: Hook) Opened(session: Core.Session; header: Items.Item);
BEGIN INC(h.opened) END Opened;

PROCEDURE (h: Hook) In(session: Core.Session; stanza: Core.Stanza);
BEGIN INC(h.received); h.last := stanza END In;

PROCEDURE (h: Hook) Out(session: Core.Session; stanza: Core.Stanza);
BEGIN INC(h.sent) END Out;

PROCEDURE (h: Hook) Other(session: Core.Session; item: Items.Item);
BEGIN
  INC(h.other);
  IF (item.namespaceURI^ = "urn:ietf:params:xml:ns:xmpp-sasl") & S.Equal8(item.name^, "success") THEN
    h.restarted := session.Restart()
  END
END Other;

PROCEDURE (h: Hook) Closed(session: Core.Session);
BEGIN
  INC(h.closed);
  IF h.restartOnClose & (h.closed = 1) THEN ASSERT(session.Restart()) END
END Closed;

PROCEDURE (h: Hook) Error(session: Core.Session; error: Msg.Msg);
BEGIN INC(h.errors) END Error;

PROCEDURE Deliver(session: Core.Session; text: ARRAY OF CHAR);
  VAR pos, length, consumed: LONGINT; event: SHORTINT;
BEGIN
  length := S.Length8(text); pos := 0;
  WHILE pos < length DO
    event := session.Feed(text, pos, length-pos, consumed);
    ASSERT((event # XML.failed) & (consumed > 0)); INC(pos, consumed)
  END
END Deliver;

PROCEDURE SessionChecks;
  VAR hook: Hook; session: Core.Session; ch: Mem.Channel; error: Msg.Msg;
    stanza: Core.Stanza; to, text, value: T.String;
BEGIN
  NEW(hook); ch := Mem.Tmp("", {Mem.read, Mem.write}, error); ASSERT(error = NIL);
  session := Core.NewSession(hook, ch.NewWriter());
  Deliver(session, '<s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" xml:lang="hy"><s:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></s:features>');
  ASSERT((hook.opened = 1) & (hook.other = 1));
  ASSERT(session.HasFeature("urn:ietf:params:xml:ns:xmpp-bind", "bind"));
  ASSERT(~session.HasFeature("urn:wrong", "bind"));
  Deliver(session, '<message from="person@example.org/Հայերեն" id="one" type="chat"><body>Հայերեն 😀</body></message>');
  stanza := hook.last; ASSERT((stanza.kind = Core.message) & S.Equal8(stanza.lang^, "hy"));
  ASSERT(S.Equal8(stanza.id^, "one") & S.Equal8(stanza.type^, "chat"));
  text := Messenger.Body(stanza); value := Items.UTF8("Հայերեն 😀"); ASSERT(S.Equal(text^, value^));
  Deliver(session, '<message xmlns="urn:extension"/>'); ASSERT((hook.received = 1) & (hook.other = 2));
  Deliver(session, '<presence/><iq id="i" type="result"/>');
  ASSERT((hook.received = 3) & (hook.last.kind = Core.iq));
  to := Items.UTF8("person@example.org/Հայերեն");
  stanza := Messenger.NewMessage(to^, text^); session.Send(stanza, error); ASSERT(error = NIL);
  stanza := Presence.NewPresence(to^, text^); session.Send(stanza, error); ASSERT(error = NIL);
  ASSERT((hook.sent = 2) & (ch.Length() > 0));
  Deliver(session, '<success xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/><t:stream xmlns:t="http://etherx.jabber.org/streams" xmlns="jabber:client"><presence xml:lang="en"/></t:stream>');
  ASSERT(hook.restarted & (hook.opened = 2) & (hook.closed = 1));
  ASSERT((session.features = NIL) & S.Equal8(hook.last.lang^, "en"));
  ASSERT(session.connection.Finish()); ASSERT(hook.errors = 0); ch.Close
END SessionChecks;

PROCEDURE CloseRestartChecks;
  VAR hook: Hook; session: Core.Session;
BEGIN
  NEW(hook); hook.restartOnClose := TRUE; session := Core.NewSession(hook, NIL);
  Deliver(session, '<s:stream xmlns:s="http://etherx.jabber.org/streams"></s:stream><s:stream xmlns:s="http://etherx.jabber.org/streams"></s:stream>');
  ASSERT((hook.opened = 2) & (hook.closed = 2) & (hook.errors = 0)); ASSERT(session.connection.Finish())
END CloseRestartChecks;

PROCEDURE JidChecks;
  VAR jid, expected, user, domain, resource: T.String;
    buffer, short: ARRAY 256 OF T.CodeUnit; small: ARRAY 2 OF T.CodeUnit; res: LONGINT;
BEGIN
  jid := Items.UTF8("մարդ@example.org/Հայերեն/😀@device");
  user := Items.UTF8("մարդ"); domain := Items.Latin1("example.org"); resource := Items.UTF8("Հայերեն/😀@device");
  ASSERT(J.JidCorrect(jid^));
  J.UsernameFromJid(jid^, buffer, res); ASSERT((res = 0) & S.Equal(buffer, user^));
  J.ServerFromJid(jid^, buffer, res); ASSERT((res = 0) & S.Equal(buffer, domain^));
  J.ResourceFromJid(jid^, buffer); ASSERT(S.Equal(buffer, resource^));
  ASSERT(J.Jid(user^, domain^, resource^, buffer)); ASSERT(S.Equal(buffer, jid^));
  J.GetShortJidFromFullJid(jid^, short); expected := Items.UTF8("մարդ@example.org"); ASSERT(S.Equal(short, expected^));
  J.ServerFromJid(jid^, small, res); ASSERT((res # 0) & (small[0] = 0));
  jid := Items.Latin1("example.org"); ASSERT(J.JidCorrect(jid^));
  J.ServerFromJid(jid^, buffer, res); ASSERT((res = 0) & S.Equal8(buffer, "example.org"));
  J.UsernameFromJid(jid^, buffer, res); ASSERT((res # 0) & (buffer[0] = 0));
  jid := Items.Latin1("a@b@c"); ASSERT(~J.JidCorrect(jid^));
  jid := Items.Latin1("@example.org"); ASSERT(~J.JidCorrect(jid^));
  jid := Items.Latin1("a@example.org/"); ASSERT(~J.JidCorrect(jid^));
  jid := Items.Latin1("a@b c"); ASSERT(~J.JidCorrect(jid^));
  jid := Items.Latin1("a@example.org/space allowed"); ASSERT(J.JidCorrect(jid^));
  jid[0] := 0D800H; ASSERT(~J.JidCorrect(jid^));
  jid := Items.Latin1("a@example.org"); jid[0] := 10000H; ASSERT(~J.JidCorrect(jid^));
  user := Items.Latin1("a@b"); ASSERT(~J.Jid(user^, domain^, resource^, buffer)); ASSERT(buffer[0] = 0)
END JidChecks;

BEGIN
  ASSERT((SIZE(T.Float32) = 4) & (SIZE(T.Float64) = 8) & (SIZE(T.BitSet32) = 4));
  SessionChecks; CloseRestartChecks; JidChecks;
  Out.String("XMPP session, stanza, JID and real-width checks passed"); Out.Ln
END TestXmppCore.
