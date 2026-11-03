MODULE TestXmppMuc;

IMPORT Out, Msg, IntStr, S := LongStrings, Strings := oocStrings, T := XmppTypes,
  Items := XmppItems, Core := XmppCore, XML := XmppXmlStream, Gen := XmppXmlGen,
  P := XmppPresence, M := XmppMuc;

VAR checks: LONGINT; room, nick, empty: T.String;

PROCEDURE Check(ok: BOOLEAN; name: ARRAY OF CHAR);
BEGIN
  IF ~ok THEN Out.String("MUC check failed: "); Out.String(name); Out.Ln; HALT(1) END;
  INC(checks)
END Check;

PROCEDURE Feed(stream: XML.Stream; text: ARRAY OF CHAR; chunk: LONGINT): Items.Item;
  VAR bytes: Items.Bytes; position, count, consumed: LONGINT; event: SHORTINT; item: Items.Item;
BEGIN
  bytes := Items.Copy8(text); position := 0; item := NIL;
  WHILE position < S.Length8(bytes^) DO
    count := S.Length8(bytes^)-position; IF count > chunk THEN count := chunk END;
    event := stream.Feed(bytes^, position, count, consumed);
    ASSERT((event # XML.failed) & (consumed > 0)); INC(position, consumed);
    IF event = XML.stanza THEN ASSERT(item = NIL); item := stream.item END
  END;
  RETURN item
END Feed;

PROCEDURE Parse(text: ARRAY OF CHAR; chunk: LONGINT): Core.Stanza;
  VAR stream: XML.Stream; item: Items.Item;
BEGIN
  stream := XML.New(); item := Feed(stream,
    '<s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" xml:lang="hy">', chunk);
  item := Feed(stream, text, chunk); ASSERT(item # NIL);
  RETURN Core.Wrap(item, stream.header)
END Parse;

PROCEDURE Presence(attributes, body: ARRAY OF CHAR): Core.Stanza;
  VAR xml: Items.Bytes;
BEGIN
  NEW(xml, S.Length8(attributes)+S.Length8(body)+128); COPY('<presence ', xml^);
  Strings.Append(attributes, xml^); Strings.Append('>', xml^); Strings.Append(body, xml^);
  Strings.Append('</presence>', xml^); RETURN Parse(xml^, 8192)
END Presence;

PROCEDURE BadPresence(attributes, body: ARRAY OF CHAR);
BEGIN Check(M.ReadPresence(Presence(attributes, body), room^) = NIL, "rejecting malformed room presence") END BadPresence;

PROCEDURE BadUser(body: ARRAY OF CHAR);
  VAR xml: Items.Bytes;
BEGIN
  NEW(xml, S.Length8(body)+256); COPY('<x xmlns="http://jabber.org/protocol/muc#user">', xml^);
  Strings.Append(body, xml^); Strings.Append('</x>', xml^);
  BadPresence('from="room@conference.example.org/Nick"', xml^)
END BadUser;

PROCEDURE RoundTrip(stanza: Core.Stanza): Core.Stanza;
  VAR bytes: Items.Bytes; length: LONGINT; error: Msg.Msg;
BEGIN
  Gen.Encode(stanza.item, 65536, bytes, length, error); ASSERT((error = NIL) & (length > 0));
  RETURN Parse(bytes^, 1)
END RoundTrip;

PROCEDURE Builders;
  VAR stanza: Core.Stanza; x, item: Items.Item; value, password, body, target, unicode, bad: T.String; i: LONGINT;
BEGIN
  password := Items.UTF8('գաղտնի<&"😀'); body := Items.UTF8('Բարեւ <աշխարհ> & 😀');
  stanza := M.Join(room^, nick^, password^, 0); Check(stanza # NIL, "joining a room");
  stanza := RoundTrip(stanza); target := Items.UTF8("room@conference.example.org/Անի😀");
  Check(S.Equal(stanza.to^, target^) & (stanza.type[0] = 0), "Unicode occupant target");
  x := stanza.item.First(M.mucURI, "x"); ASSERT(x # NIL);
  item := x.First(M.mucURI, "password"); value := item.Text(); Check(S.Equal(value^, password^), "escaped password round trip");
  item := x.First(M.mucURI, "history"); value := item.GetAttribute("", "maxstanzas"); Check(S.Equal8(value^, "0"), "disabling history");
  stanza := M.Join(room^, nick^, empty^, -1); x := stanza.item.First(M.mucURI, "x");
  Check((x.First(M.mucURI, "password") = NIL) & (x.First(M.mucURI, "history") = NIL), "server-default history");
  Check(M.Join(room^, nick^, empty^, M.maxHistoryStanzas) # NIL, "bounded history request");
  Check((M.Join(room^, nick^, empty^, -2) = NIL) &
    (M.Join(room^, nick^, empty^, M.maxHistoryStanzas+1) = NIL), "invalid history request");
  stanza := RoundTrip(M.Leave(room^, nick^, body^));
  Check(S.Equal8(stanza.type^, "unavailable") & S.Equal(stanza.to^, target^), "leaving a room");
  stanza := RoundTrip(M.GroupMessage(room^, body^)); item := stanza.item.First("jabber:client", "body"); value := item.Text();
  Check(S.Equal(stanza.to^, room^) & S.Equal8(stanza.type^, "groupchat") & S.Equal(value^, body^), "group message round trip");
  stanza := RoundTrip(M.Subject(room^, empty^)); item := stanza.item.First("jabber:client", "subject");
  Check((item # NIL) & (stanza.item.First("jabber:client", "body") = NIL), "clearing the subject");
  target := Items.UTF8("սրահ@xn--bcher-kva.example"); unicode := Items.UTF8("սրահ@bücher.example");
  value := M.Room(target^); Check((value # NIL) & S.Equal(value^, unicode^), "Unicode room domain");
  target := Items.Latin1("conference.example.org"); Check(M.Room(target^) = NIL, "requiring a room localpart");
  target := Items.Latin1("room@conference.example.org/nick"); Check(M.Room(target^) = NIL, "rejecting a full room address");
  Check((M.Room(empty^) = NIL) & (M.OccupantJID(room^, empty^) = NIL), "empty room or nickname");
  target := Items.Latin1("Room@conference.example.org"); value := M.Room(target^);
  Check(S.Equal(value^, target^), "preserving room localpart case");
  target := Items.UTF8("nick/name@device"); value := M.OccupantJID(room^, target^);
  Check(value # NIL, "resourcepart punctuation");
  NEW(bad, 2); bad[0] := 0D800H; bad[1] := 0;
  Check((M.Join(room^, nick^, bad^, 0) = NIL) & (M.GroupMessage(room^, bad^) = NIL), "rejecting unpaired surrogates");
  bad[0] := 1; Check((M.Subject(room^, bad^) = NIL) & (M.Leave(room^, nick^, bad^) = NIL), "rejecting XML controls");
  NEW(bad, M.maxPasswordUnits+2);
  FOR i := 0 TO M.maxPasswordUnits DO bad[i] := ORD("a") END; bad[M.maxPasswordUnits+1] := 0;
  Check(M.Join(room^, nick^, bad^, 0) = NIL, "password overflow"); bad[M.maxPasswordUnits] := 0;
  Check(M.Join(room^, nick^, bad^, 0) # NIL, "password limit");
  NEW(bad, 1025); FOR i := 0 TO 1023 DO bad[i] := ORD("a") END; bad[1024] := 0;
  Check(M.OccupantJID(room^, bad^) = NIL, "nickname overflow"); bad[1023] := 0;
  Check(M.OccupantJID(room^, bad^) # NIL, "nickname byte limit");
  FOR i := 0 TO 511 DO bad[i] := 531H END; bad[512] := 0;
  Check(M.OccupantJID(room^, bad^) = NIL, "nickname UTF-8 byte overflow"); bad[511] := 0;
  Check(M.OccupantJID(room^, bad^) # NIL, "nickname UTF-8 byte bound")
END Builders;

PROCEDURE Occupants;
  VAR event: M.Occupant; stanza: Core.Stanza; expected: T.String; i: LONGINT;
BEGIN
  stanza := Presence('from="room@CONFERENCE.example.org/Անի😀"',
    '<show>away</show><status>Բարեւ 😀</status><m:x xmlns:m="http://jabber.org/protocol/muc#user"><m:item affiliation="member" role="participant" jid="person@xn--bcher-kva.example/device"/><m:status code="110"/><m:status code="210"/></m:x>');
  event := M.ReadPresence(stanza, room^); Check(event # NIL, "reading occupant presence");
  Check(S.Equal(event.nick^, nick^) & S.Equal(event.room^, room^) & (event.presence.kind = P.available), "canonical occupant identity");
  expected := Items.UTF8("person@bücher.example/device"); Check(S.Equal(event.jid^, expected^), "canonical disclosed JID");
  Check(event.HasStatus(110) & event.HasStatus(210) & ~event.HasStatus(201) & (event.codeCount = 2), "self-presence status codes");
  Check(S.Equal8(event.role^, "participant") & S.Equal8(event.affiliation^, "member"), "occupant role and affiliation");
  Check(S.Equal8(event.presence.show^, "away") & (event.presence.statusCount = 1), "base presence fields");
  FOR i := 1 TO 160 DO
    stanza := Parse('<presence from="room@CONFERENCE.example.org/Անի😀"><show>away</show><status>Բարեւ 😀</status><x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="participant" jid="person@xn--bcher-kva.example/device"/><status code="110"/><status code="210"/></x></presence>', i);
    event := M.ReadPresence(stanza, room^);
    Check((event # NIL) & S.Equal(event.nick^, nick^) & S.Equal(event.jid^, expected^) &
      S.Equal8(event.role^, "participant") & S.Equal8(event.presence.show^, "away") &
      event.HasStatus(110) & event.HasStatus(210), "fragmented Unicode occupant presence")
  END;
  stanza := Presence('from="room@conference.example.org/Nick"',
    '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="none" role="visitor"/></x>');
  event := M.ReadPresence(stanza, room^); Check((event # NIL) & (event.jid[0] = 0) & ~event.HasStatus(110), "anonymous occupant");
  stanza := Presence('from="room@conference.example.org/Old" type="unavailable"',
    '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="participant" nick="New"/><status code="303"/></x>');
  event := M.ReadPresence(stanza, room^); Check((event # NIL) & event.HasStatus(303) & S.Equal8(event.newNick^, "New"), "nickname change");
  stanza := Presence('from="room@conference.example.org/Nick" type="unavailable"',
    '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="outcast" role="none"><actor nick="Moderator" jid="mod@example.org"/><reason>Policy</reason></item><status code="301"/><status code="110"/></x>');
  event := M.ReadPresence(stanza, room^);
  Check((event # NIL) & event.HasStatus(301) & S.Equal8(event.actorNick^, "Moderator") & S.Equal8(event.reason^, "Policy"), "removal actor and reason");
  stanza := Presence('from="room@conference.example.org/Nick" type="unavailable"',
    '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="none" role="none"/><destroy jid="other@conference.example.org"><reason>Closed</reason></destroy></x>');
  event := M.ReadPresence(stanza, room^);
  Check((event # NIL) & event.destroyed & S.Equal8(event.destroyReason^, "Closed") & S.Equal8(event.alternateRoom^, "other@conference.example.org"), "room destruction");
  stanza := Presence('from="room@conference.example.org/Nick" type="error"',
    '<x xmlns="http://jabber.org/protocol/muc"/><error type="cancel"><conflict xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/></error>');
  event := M.ReadPresence(stanza, room^); Check((event # NIL) & (event.presence.kind = P.stanzaError), "join error");
  stanza := Presence('from="room@conference.example.org" type="error"',
    '<error type="auth"><forbidden xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/></error>');
  Check(M.ReadPresence(stanza, room^) # NIL, "room-level error");
  BadPresence('from="room@other.example.org/Nick"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="none" role="visitor"/></x>');
  BadPresence('from="Room@conference.example.org/Nick"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="none" role="visitor"/></x>');
  BadPresence('from="room@conference.example.org"', '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="none" role="visitor"/></x>');
  BadPresence('', ''); BadPresence('from="room@conference.example.org/Nick"', '');
  BadPresence('from="room@conference.example.org/Nick"', '<x xmlns="urn:wrong"><item affiliation="none" role="visitor"/></x>');
  BadPresence('from="room@conference.example.org/Nick"', '<x xmlns="http://jabber.org/protocol/muc#user"/><x xmlns="http://jabber.org/protocol/muc#user"/>');
  BadPresence('from="room@conference.example.org/Nick" type="subscribe"', '<x xmlns="http://jabber.org/protocol/muc#user"/>');
  BadUser('<item role="participant"/>'); BadUser('<item affiliation="member"/>');
  BadUser('<item affiliation="root" role="participant"/>'); BadUser('<item affiliation="member" role="admin"/>');
  BadUser('<item affiliation="member" role="participant" jid=""/>');
  BadUser('<item affiliation="member" role="participant" jid="bad..example"/>');
  BadUser('<item affiliation="member" role="participant" nick=""/>');
  BadUser('<item xmlns="urn:wrong" affiliation="member" role="participant"/>');
  BadUser('<item affiliation="member" role="participant"/><item affiliation="member" role="participant"/>');
  BadUser('<item affiliation="member" role="participant"><actor/></item>');
  BadUser('<item affiliation="member" role="participant"><actor nick="Mod"><nested/></actor></item>');
  BadUser('<item affiliation="member" role="participant"><actor nick="A"/><actor nick="B"/></item>');
  BadUser('<item affiliation="member" role="participant"><reason>A</reason><reason>B</reason></item>');
  BadUser('<item affiliation="member" role="participant"><reason><nested/></reason></item>');
  BadUser('<item affiliation="member" role="participant"/>text');
  BadUser('<item affiliation="member" role="participant"/><status code="110"/><status code="110"/>');
  BadUser('<item affiliation="member" role="participant"/><status code="11"/>');
  BadUser('<item affiliation="member" role="participant"/><status code="0110"/>');
  BadUser('<item affiliation="member" role="participant"/><status code="099"/>');
  BadUser('<item affiliation="member" role="participant"/><status code="1x0"/>');
  BadUser('<item affiliation="member" role="participant"/><status/>');
  BadUser('<item affiliation="member" role="participant"/><status code="110">text</status>');
  BadUser('<item affiliation="member" role="participant"/><status code="303"/>');
  BadUser('<item affiliation="member" role="participant" nick="New"/><status code="303"/>');
  BadUser('<item affiliation="member" role="participant"/><destroy/>');
  BadPresence('from="room@conference.example.org/Nick" type="unavailable"',
    '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="none" role="none"/><destroy jid="example.org"/></x>');
  Check(M.ReadPresence(NIL, room^) = NIL, "nil presence")
END Occupants;

PROCEDURE Messages;
  VAR event: M.Message; stanza: Core.Stanza; expected: T.String; i: LONGINT;
BEGIN
  FOR i := 1 TO 160 DO
    stanza := Parse('<message from="room@conference.example.org/Անի😀" type="groupchat"><body>Բարեւ 😀</body><body xml:lang="EN">Hello</body><subject>Թեմա</subject><delay xmlns="urn:xmpp:delay" stamp="2026-01-01T00:00:00Z"/></message>', i);
    event := M.ReadMessage(stanza, room^); ASSERT(event # NIL); expected := Items.UTF8("Բարեւ 😀");
    Check(S.Equal(event.body^, expected^) & (event.bodyCount = 2) & (event.subjectCount = 1) &
      S.Equal8(event.bodies[0].language^, "hy") & S.Equal8(event.bodies[1].language^, "en"), "fragmented multilingual group message")
  END;
  stanza := Parse('<message from="room@conference.example.org" type="groupchat"><subject/></message>', 1);
  event := M.ReadMessage(stanza, room^);
  Check((event # NIL) & (event.nick[0] = 0) & (event.subjectCount = 1) & (event.subject[0] = 0) & (event.bodyCount = 0), "empty subject from room");
  stanza := Parse('<message from="room@elsewhere.example/Nick" type="groupchat"><body>Spoof</body></message>', 1);
  Check(M.ReadMessage(stanza, room^) = NIL, "wrong message room");
  stanza := Parse('<message from="room@conference.example.org/Nick" type="chat"><body>Private</body></message>', 1);
  Check(M.ReadMessage(stanza, room^) = NIL, "private messages remain separate");
  stanza := Parse('<message from="room@conference.example.org/Nick" type="groupchat"><body>A</body><body xml:lang="HY">B</body></message>', 1);
  Check(M.ReadMessage(stanza, room^) = NIL, "duplicate message language");
  stanza := Parse('<message from="room@conference.example.org/Nick" type="groupchat"><body xml:lang="-en">A</body></message>', 1);
  Check(M.ReadMessage(stanza, room^) = NIL, "invalid message language");
  stanza := Parse('<message from="room@conference.example.org/Nick" type="groupchat"><body><nested/></body></message>', 1);
  Check(M.ReadMessage(stanza, room^) = NIL, "nested body");
  stanza := Parse('<message from="room@conference.example.org/Nick" type="groupchat"><body xmlns="urn:wrong">Spoof</body></message>', 1);
  Check(M.ReadMessage(stanza, room^) = NIL, "wrong body namespace");
  stanza := Parse('<message from="room@conference.example.org/Nick" type="groupchat"><body>A</body>text</message>', 1);
  Check(M.ReadMessage(stanza, room^) = NIL, "non-whitespace message content");
  Check(M.ReadMessage(NIL, room^) = NIL, "nil message")
END Messages;

PROCEDURE BadInvitation(body: ARRAY OF CHAR);
  VAR xml: Items.Bytes;
BEGIN
  NEW(xml, S.Length8(body)+256);
  COPY('<message from="room@conference.example.org"><x xmlns="http://jabber.org/protocol/muc#user">', xml^);
  Strings.Append(body, xml^); Strings.Append('</x></message>', xml^);
  Check(M.ReadInvitation(Parse(xml^, 1), room^) = NIL, "rejecting malformed invitation")
END BadInvitation;

PROCEDURE Invitations;
  VAR stanza: Core.Stanza; event: M.Invitation; value, peer, reason, text: T.String;
    x, child, item: Items.Item; i: LONGINT;
BEGIN
  peer := Items.UTF8("Անի@bücher.example/device"); reason := Items.UTF8("Միացիր <😀>&");
  stanza := RoundTrip(M.Invite(room^, peer^, reason^)); x := stanza.item.First(M.userURI, "x");
  child := x.First(M.userURI, "invite"); value := child.GetAttribute("", "to");
  Check(S.Equal(stanza.to^, room^) & S.Equal(value^, peer^), "mediated invitation target");
  item := child.First(M.userURI, "reason"); value := item.Text();
  Check(S.Equal(value^, reason^), "escaped invitation reason");
  stanza := RoundTrip(M.Decline(room^, peer^, empty^)); x := stanza.item.First(M.userURI, "x");
  child := x.First(M.userURI, "decline");
  Check((child # NIL) & (child.First(M.userURI, "reason") = NIL), "declining without a reason");
  stanza := RoundTrip(M.ChangeNick(room^, nick^));
  Check((stanza.kind = Core.presence) & (stanza.type[0] = 0) &
    (stanza.item.First(M.mucURI, "x") = NIL), "nickname change is not a fresh join");
  Check((M.Invite(empty^, peer^, empty^) = NIL) & (M.Invite(room^, empty^, empty^) = NIL), "invalid invitation addresses");
  Check(M.ChangeNick(room^, empty^) = NIL, "empty replacement nickname");
  FOR i := 1 TO 160 DO
    stanza := Parse('<message from="room@CONFERENCE.example.org"><x xmlns="http://jabber.org/protocol/muc#user"><invite from="Անի@xn--bcher-kva.example/device"><reason>Միացիր &lt;😀&gt;&amp;</reason></invite><password>գաղտնի😀</password></x></message>', i);
    event := M.ReadInvitation(stanza, room^);
    value := Items.UTF8("Միացիր <😀>&"); text := Items.UTF8("գաղտնի😀");
    Check((event # NIL) & ~event.declined & S.Equal(event.peer^, peer^) &
      S.Equal(event.reason^, value^) & S.Equal(event.password^, text^), "fragmented Unicode invitation")
  END;
  stanza := Parse('<message from="room@conference.example.org" type="normal"><x xmlns="http://jabber.org/protocol/muc#user"><decline from="person@example.org"><reason>Later</reason></decline></x></message>', 1);
  event := M.ReadInvitation(stanza, room^);
  Check((event # NIL) & event.declined & S.Equal8(event.peer^, "person@example.org") &
    S.Equal8(event.reason^, "Later") & (event.password[0] = 0), "reading a declined invitation");
  stanza := Parse('<message from="room@conference.example.org"><x xmlns="http://jabber.org/protocol/muc#user"><invite from="person@example.org"><continue thread="conversation"/></invite></x></message>', 1);
  event := M.ReadInvitation(stanza, room^);
  Check((event # NIL) & event.continued & S.Equal8(event.thread^, "conversation"), "continued conversation invitation");
  stanza := Parse('<message from="room@conference.example.org"><x xmlns="http://jabber.org/protocol/muc#user"><invite from="person@example.org"><continue/></invite></x></message>', 1);
  event := M.ReadInvitation(stanza, room^);
  Check((event # NIL) & event.continued & (event.thread[0] = 0), "continuation without a thread");
  stanza := Parse('<message from="other@conference.example.org"><x xmlns="http://jabber.org/protocol/muc#user"><invite from="person@example.org"/></x></message>', 1);
  Check(M.ReadInvitation(stanza, room^) = NIL, "rejecting an invitation from another room");
  stanza := Parse('<message from="room@conference.example.org/Nick"><x xmlns="http://jabber.org/protocol/muc#user"><invite from="person@example.org"/></x></message>', 1);
  Check(M.ReadInvitation(stanza, room^) = NIL, "occupants cannot impersonate mediated invitations");
  stanza := Parse('<message from="room@conference.example.org" type="groupchat"><x xmlns="http://jabber.org/protocol/muc#user"><invite from="person@example.org"/></x></message>', 1);
  Check(M.ReadInvitation(stanza, room^) = NIL, "invitations are not group messages");
  stanza := Parse('<message from="room@conference.example.org"><x xmlns="http://jabber.org/protocol/muc#user"><invite from="person@example.org"/></x><x xmlns="http://jabber.org/protocol/muc#user"/></message>', 1);
  Check(M.ReadInvitation(stanza, room^) = NIL, "duplicate invitation extensions");
  BadInvitation('<invite/>'); BadInvitation('<invite from=""/>');
  BadInvitation('<invite from="bad..example"/>'); BadInvitation('<invite to="person@example.org"/>');
  BadInvitation('<invite from="person@example.org" to="other@example.org"/>');
  BadInvitation('<invite from="person@example.org"/><invite from="other@example.org"/>');
  BadInvitation('<invite from="person@example.org"/><decline from="person@example.org"/>');
  BadInvitation('<invite xmlns="urn:wrong" from="person@example.org"/>');
  BadInvitation('<invite from="person@example.org"><reason>A</reason><reason>B</reason></invite>');
  BadInvitation('<invite from="person@example.org"><reason><nested/></reason></invite>');
  BadInvitation('<invite from="person@example.org"/>text');
  BadInvitation('<invite from="person@example.org"/><password>A</password><password>B</password>');
  BadInvitation('<invite from="person@example.org"/><password><nested/></password>');
  BadInvitation('<decline from="person@example.org"/><password>secret</password>');
  BadInvitation('<decline from="person@example.org"><continue/></decline>');
  BadInvitation('<invite from="person@example.org"><continue/><continue/></invite>');
  BadInvitation('<invite from="person@example.org"><continue><nested/></continue></invite>');
  Check(M.ReadInvitation(NIL, room^) = NIL, "nil invitation");
  NEW(text, M.maxTextUnits+2); FOR i := 0 TO M.maxTextUnits DO text[i] := ORD("a") END; text[M.maxTextUnits+1] := 0;
  Check((M.Invite(room^, peer^, text^) = NIL) & (M.Decline(room^, peer^, text^) = NIL), "invitation reason overflow");
  text[M.maxTextUnits] := 0;
  Check(M.Invite(room^, peer^, text^) # NIL, "invitation reason limit");
  stanza := Parse('<message from="room@conference.example.org"><x xmlns="http://jabber.org/protocol/muc#user"><invite from="person@example.org"/></x></message>', 1);
  x := stanza.item.First(M.userURI, "x"); child := Items.New("password", M.userURI);
  child.AddText(text^, 0, M.maxPasswordUnits); x.AddChild(child);
  Check(M.ReadInvitation(stanza, room^) # NIL, "received password limit");
  child.AddText(text^, 0, 1);
  Check(M.ReadInvitation(stanza, room^) = NIL, "received password overflow")
END Invitations;

PROCEDURE Limits;
  VAR stanza: Core.Stanza; event: M.Occupant; item, x, child: Items.Item;
    text, value, from: T.String; i: LONGINT; number: ARRAY 16 OF CHAR;
BEGIN
  NEW(text, M.maxTextUnits+2); FOR i := 0 TO M.maxTextUnits DO text[i] := ORD("a") END; text[M.maxTextUnits+1] := 0;
  Check((M.GroupMessage(room^, text^) = NIL) & (M.Subject(room^, text^) = NIL), "message text overflow");
  text[M.maxTextUnits] := 0; stanza := M.GroupMessage(room^, text^); from := Items.Latin1("room@conference.example.org/Nick");
  stanza.item.SetParam("from", from^); stanza := Core.Wrap(stanza.item, NIL);
  Check(M.ReadMessage(stanza, room^) # NIL, "message text limit");
  child := Items.New("subject", "jabber:client"); child.AddText(text^, 0, M.maxTextUnits); stanza.item.AddChild(child);
  Check(M.ReadMessage(stanza, room^) # NIL, "combined text limit");
  child := Items.New("subject", "jabber:client"); value := Items.Latin1("lang");
  child.SetAttribute(value^, Core.xmlURI, value^); child.AddText(text^, 0, 1); stanza.item.AddChild(child);
  Check(M.ReadMessage(stanza, room^) = NIL, "combined text overflow");
  stanza := Core.NewStanza("message"); stanza.item.SetParam("from", from^); value := Items.Latin1("groupchat"); stanza.item.SetParam("type", value^);
  value := Items.Latin1("lang");
  FOR i := 0 TO M.maxTexts DO
    child := Items.New("body", "jabber:client"); text[0] := ORD("a")+i; text[1] := 0;
    child.SetAttribute(value^, Core.xmlURI, text^); stanza.item.AddChild(child);
    IF i = M.maxTexts-1 THEN Check(M.ReadMessage(Core.Wrap(stanza.item, NIL), room^) # NIL, "language count limit") END
  END;
  Check(M.ReadMessage(Core.Wrap(stanza.item, NIL), room^) = NIL, "language count overflow");
  stanza := Presence('from="room@conference.example.org/Nick"',
    '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="participant"/></x>');
  x := stanza.item.First(M.userURI, "x");
  FOR i := 0 TO M.maxCodes DO
    child := Items.New("status", M.userURI); IntStr.IntToStr(400+i, number); value := Items.Latin1(number); child.SetParam("code", value^); x.AddChild(child);
    IF i = M.maxCodes-1 THEN event := M.ReadPresence(stanza, room^); Check((event # NIL) & event.HasStatus(431), "status code count limit") END
  END;
  Check(M.ReadPresence(stanza, room^) = NIL, "status code count overflow");
  stanza := Presence('from="room@conference.example.org/Nick"',
    '<x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="member" role="participant"/></x>');
  FOR i := 1 TO M.maxParts DO
    child := Items.New("extension", "urn:test"); stanza.item.AddChild(child);
    IF i = M.maxParts-1 THEN Check(M.ReadPresence(stanza, room^) # NIL, "root part limit") END
  END;
  Check(M.ReadPresence(stanza, room^) = NIL, "root part overflow");
  stanza := M.GroupMessage(room^, empty^); stanza.item.SetParam("from", from^); stanza := Core.Wrap(stanza.item, NIL);
  item := stanza.item.First("jabber:client", "body"); value := Items.Latin1("a");
  FOR i := 1 TO M.maxParts DO item.AddText(value^, 0, 1) END;
  Check(M.ReadMessage(stanza, room^) # NIL, "scalar part limit"); item.AddText(value^, 0, 1);
  Check(M.ReadMessage(stanza, room^) = NIL, "scalar part overflow")
END Limits;

BEGIN
  room := Items.Latin1("room@conference.example.org"); nick := Items.UTF8("Անի😀"); empty := Items.Latin1("");
  checks := 0; Builders; Occupants; Messages; Invitations; Limits;
  Out.String("XMPP multi-user-chat checks passed: "); Out.Int(checks, 0); Out.Ln
END TestXmppMuc.
