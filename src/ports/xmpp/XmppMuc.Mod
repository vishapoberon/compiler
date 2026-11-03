MODULE XmppMuc;

(* XEP-0045 stanza construction and bounded decoding for an explicit room. *)

IMPORT Msg, S := LongStrings, IntStr, T := XmppTypes, Items := XmppItems,
  Core := XmppCore, IQ := XmppIQ, P := XmppPresence, J := XmppStrings;

CONST
  mucURI* = "http://jabber.org/protocol/muc";
  userURI* = "http://jabber.org/protocol/muc#user";
  ownerURI* = "http://jabber.org/protocol/muc#owner";
  adminURI* = "http://jabber.org/protocol/muc#admin";
  formURI* = "jabber:x:data";
  configURI* = "http://jabber.org/protocol/muc#roomconfig";
  maxTextUnits* = 4096; maxPasswordUnits* = 1024;
  maxCodes* = 32; maxTexts* = 8; maxTotalTextUnits* = 8192;
  maxParts* = 128; maxHistoryStanzas* = 1000;
  maxFormNodes* = 256; maxFormUnits* = 16384; maxFormFields* = 64;
  maxMembers* = 64;
  invalidRequest* = 1;

TYPE
  Occupant* = POINTER TO OccupantDesc;
  OccupantDesc* = RECORD
    presence-: P.Event;
    room-, nick-, jid-, role-, affiliation-, newNick-: T.String;
    actorJID-, actorNick-, reason-: T.String;
    destroyed-: BOOLEAN;
    alternateRoom-, destroyReason-: T.String;
    codeCount-: LONGINT;
    codes-: ARRAY maxCodes OF LONGINT;
  END;
  Text* = RECORD language-, text-: T.String END;
  Message* = POINTER TO MessageDesc;
  MessageDesc* = RECORD
    from-, room-, nick-, body-, subject-: T.String;
    bodyCount-, subjectCount-: LONGINT;
    bodies-, subjects-: ARRAY maxTexts OF Text;
  END;
  Invitation* = POINTER TO InvitationDesc;
  InvitationDesc* = RECORD
    room-, peer-, reason-, password-, thread-: T.String;
    declined-, continued-: BOOLEAN
  END;
  Member* = RECORD
    nick-, jid-, role-, affiliation-, actorJID-, actorNick-, reason-: T.String
  END;
  MemberList* = POINTER TO MemberListDesc;
  MemberListDesc* = RECORD count-: LONGINT; entries-: ARRAY maxMembers OF Member END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR text: Msg.LString);
BEGIN S.Long("Invalid bounded XMPP room request", text) END GetTemplate;

PROCEDURE Invalid(VAR error: Msg.Msg): IQ.Request;
BEGIN error := Msg.New(context, invalidRequest); RETURN NIL END Invalid;

PROCEDURE Room*(jid: ARRAY OF T.CodeUnit): T.String;
  VAR canonical, bare: T.String; username: ARRAY IQ.maxJIDUnits+1 OF T.CodeUnit; result: LONGINT;
BEGIN
  canonical := IQ.CanonicalJID(jid); IF canonical = NIL THEN RETURN NIL END;
  bare := P.Bare(canonical^); IF (bare = NIL) OR ~S.Equal(bare^, canonical^) THEN RETURN NIL END;
  J.UsernameFromJid(canonical^, username, result);
  IF (result # 0) OR (username[0] = 0) THEN RETURN NIL END;
  RETURN canonical
END Room;

PROCEDURE OccupantJID*(room, nick: ARRAY OF T.CodeUnit): T.String;
  VAR bare: T.String; text: ARRAY IQ.maxJIDUnits+1 OF T.CodeUnit;
BEGIN
  bare := Room(room);
  IF (bare = NIL) OR (S.Length(nick) = 0) OR ~IQ.Value(nick, 1023) OR
     (S.Length(bare^)+S.Length(nick)+1 > IQ.maxJIDUnits) THEN RETURN NIL END;
  S.Assign(bare^, text); S.Append8("/", text); S.Append(nick, text);
  RETURN IQ.CanonicalJID(text)
END OccupantJID;

PROCEDURE AddText(parent: Items.Item; uri, name: ARRAY OF CHAR; value: ARRAY OF T.CodeUnit);
  VAR child: Items.Item;
BEGIN
  child := Items.New(name, uri); child.AddText(value, 0, S.Length(value)); parent.AddChild(child)
END AddText;

PROCEDURE Join*(room, nick, password: ARRAY OF T.CodeUnit; historyStanzas: LONGINT): Core.Stanza;
  VAR target, empty, value: T.String; stanza: Core.Stanza; x, history: Items.Item;
    number: ARRAY 16 OF CHAR;
BEGIN
  IF ~IQ.Value(password, maxPasswordUnits) OR (historyStanzas < -1) OR
     (historyStanzas > maxHistoryStanzas) THEN RETURN NIL END;
  target := OccupantJID(room, nick); IF target = NIL THEN RETURN NIL END;
  empty := Items.Latin1(""); stanza := P.Available(target^, empty^, empty^, 0);
  IF stanza = NIL THEN RETURN NIL END;
  x := Items.New("x", mucURI);
  IF password[0] # 0 THEN AddText(x, mucURI, "password", password) END;
  IF historyStanzas >= 0 THEN
    history := Items.New("history", mucURI); IntStr.IntToStr(historyStanzas, number);
    value := Items.Latin1(number); history.SetParam("maxstanzas", value^); x.AddChild(history)
  END;
  stanza.item.AddChild(x); RETURN Core.Wrap(stanza.item, NIL)
END Join;

PROCEDURE Leave*(room, nick, status: ARRAY OF T.CodeUnit): Core.Stanza;
  VAR target: T.String;
BEGIN
  target := OccupantJID(room, nick); IF target = NIL THEN RETURN NIL END;
  RETURN P.Unavailable(target^, status)
END Leave;

PROCEDURE GroupText(room, text: ARRAY OF T.CodeUnit; name: ARRAY OF CHAR): Core.Stanza;
  VAR target, type: T.String; stanza: Core.Stanza;
BEGIN
  target := Room(room); IF (target = NIL) OR ~IQ.Value(text, maxTextUnits) THEN RETURN NIL END;
  stanza := Core.NewStanza("message"); stanza.item.SetParam("to", target^);
  type := Items.Latin1("groupchat"); stanza.item.SetParam("type", type^);
  AddText(stanza.item, "jabber:client", name, text); RETURN Core.Wrap(stanza.item, NIL)
END GroupText;

PROCEDURE GroupMessage*(room, body: ARRAY OF T.CodeUnit): Core.Stanza;
BEGIN RETURN GroupText(room, body, "body") END GroupMessage;

PROCEDURE Subject*(room, subject: ARRAY OF T.CodeUnit): Core.Stanza;
BEGIN RETURN GroupText(room, subject, "subject") END Subject;

PROCEDURE ChangeNick*(room, nick: ARRAY OF T.CodeUnit): Core.Stanza;
  VAR target, empty: T.String;
BEGIN
  target := OccupantJID(room, nick); IF target = NIL THEN RETURN NIL END;
  empty := Items.Latin1(""); RETURN P.Available(target^, empty^, empty^, 0)
END ChangeNick;

PROCEDURE InvitationStanza(room, peer, reason: ARRAY OF T.CodeUnit; decline: BOOLEAN): Core.Stanza;
  VAR target, recipient: T.String; stanza: Core.Stanza; x, child: Items.Item;
BEGIN
  target := Room(room); recipient := IQ.CanonicalJID(peer);
  IF (target = NIL) OR (recipient = NIL) OR ~IQ.Value(reason, maxTextUnits) THEN RETURN NIL END;
  stanza := Core.NewStanza("message"); stanza.item.SetParam("to", target^);
  x := Items.New("x", userURI);
  IF decline THEN child := Items.New("decline", userURI) ELSE child := Items.New("invite", userURI) END;
  child.SetParam("to", recipient^);
  IF reason[0] # 0 THEN AddText(child, userURI, "reason", reason) END;
  x.AddChild(child); stanza.item.AddChild(x); RETURN Core.Wrap(stanza.item, NIL)
END InvitationStanza;

PROCEDURE Invite*(room, peer, reason: ARRAY OF T.CodeUnit): Core.Stanza;
BEGIN RETURN InvitationStanza(room, peer, reason, FALSE) END Invite;

PROCEDURE Decline*(room, inviter, reason: ARRAY OF T.CodeUnit): Core.Stanza;
BEGIN RETURN InvitationStanza(room, inviter, reason, TRUE) END Decline;

PROCEDURE White(text: T.String): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  IF S.Length(text^) > maxTotalTextUnits THEN RETURN FALSE END;
  FOR i := 0 TO S.Length(text^)-1 DO
    IF (text[i] # 32) & (text[i] # 9) & (text[i] # 10) & (text[i] # 13) THEN RETURN FALSE END
  END;
  RETURN TRUE
END White;

PROCEDURE Layout(item: Items.Item): BOOLEAN;
  VAR content: Items.Content; attribute: Items.Attribute; count: LONGINT;
BEGIN
  count := 0; attribute := item.attributes;
  WHILE attribute # NIL DO
    INC(count); IF count > maxParts THEN RETURN FALSE END; attribute := attribute.next
  END;
  content := item.content; count := 0;
  WHILE content # NIL DO
    INC(count); IF count > maxParts THEN RETURN FALSE END;
    IF (content.element = NIL) & ~White(content.text) THEN RETURN FALSE END;
    content := content.next
  END;
  RETURN TRUE
END Layout;

PROCEDURE Scalar(item: Items.Item; maximum: LONGINT): T.String;
  VAR content: Items.Content; count, length, size: LONGINT; text: T.String;
BEGIN
  content := item.content; count := 0; length := 0;
  WHILE content # NIL DO
    INC(count); IF (count > maxParts) OR (content.element # NIL) THEN RETURN NIL END;
    size := S.Length(content.text^); IF size > maximum-length THEN RETURN NIL END;
    INC(length, size); content := content.next
  END;
  text := item.Text(); IF ~IQ.Value(text^, maximum) THEN RETURN NIL END; RETURN text
END Scalar;

PROCEDURE Origin(stanza: Core.Stanza; room: ARRAY OF T.CodeUnit; VAR bare, nick: T.String): T.String;
  VAR expected, from, actual: T.String; text: ARRAY IQ.maxJIDUnits+1 OF T.CodeUnit;
BEGIN
  expected := Room(room); IF (expected = NIL) OR (stanza = NIL) THEN RETURN NIL END;
  from := IQ.CanonicalJID(stanza.from^); IF from = NIL THEN RETURN NIL END;
  actual := P.Bare(from^); IF (actual = NIL) OR ~S.Equal(actual^, expected^) THEN RETURN NIL END;
  bare := actual; J.ResourceFromJid(from^, text); nick := Items.Copy16(text); RETURN from
END Origin;

PROCEDURE Attribute(item: Items.Item; name: ARRAY OF CHAR; maximum: LONGINT): T.String;
  VAR text: T.String;
BEGIN
  text := item.GetAttribute("", name); IF text = NIL THEN RETURN Items.Latin1("") END;
  IF ~IQ.Value(text^, maximum) THEN RETURN NIL END; RETURN Items.Copy16(text^)
END Attribute;

PROCEDURE JIDAttribute(item: Items.Item; name: ARRAY OF CHAR): T.String;
  VAR text: T.String;
BEGIN
  text := item.GetAttribute("", name); IF text = NIL THEN RETURN Items.Latin1("") END;
  RETURN IQ.CanonicalJID(text^)
END JIDAttribute;

PROCEDURE NickAttribute(item: Items.Item; room: T.String): T.String;
  VAR text, jid: T.String;
BEGIN
  text := item.GetAttribute("", "nick"); IF text = NIL THEN RETURN Items.Latin1("") END;
  jid := OccupantJID(room^, text^); IF jid = NIL THEN RETURN NIL END;
  RETURN Items.Copy16(text^)
END NickAttribute;

PROCEDURE RoleValue(role: ARRAY OF T.CodeUnit): BOOLEAN;
BEGIN
  RETURN S.Equal8(role, "moderator") OR S.Equal8(role, "participant") OR
    S.Equal8(role, "visitor") OR S.Equal8(role, "none")
END RoleValue;

PROCEDURE AffiliationValue(affiliation: ARRAY OF T.CodeUnit): BOOLEAN;
BEGIN
  RETURN S.Equal8(affiliation, "owner") OR S.Equal8(affiliation, "admin") OR
    S.Equal8(affiliation, "member") OR S.Equal8(affiliation, "outcast") OR S.Equal8(affiliation, "none")
END AffiliationValue;

PROCEDURE ReadItem(item: Items.Item; event: Occupant; partial: BOOLEAN; uri: ARRAY OF CHAR): BOOLEAN;
  VAR child: Items.Item; content: Items.Content; actors, reasons: LONGINT;
BEGIN
  IF ~Layout(item) THEN RETURN FALSE END;
  event.jid := JIDAttribute(item, "jid"); event.newNick := NickAttribute(item, event.room);
  event.role := Attribute(item, "role", 16); event.affiliation := Attribute(item, "affiliation", 16);
  IF (event.jid = NIL) OR (event.newNick = NIL) OR (event.role = NIL) OR (event.affiliation = NIL) THEN RETURN FALSE END;
   IF ~((partial & (event.role[0] = 0)) OR RoleValue(event.role^)) OR
      ~((partial & (event.affiliation[0] = 0)) OR AffiliationValue(event.affiliation^)) THEN RETURN FALSE END;
   IF partial & (((event.role[0] = 0) & (item.GetAttribute("", "role") # NIL)) OR
      ((event.affiliation[0] = 0) & (item.GetAttribute("", "affiliation") # NIL))) THEN RETURN FALSE END;
  actors := 0; reasons := 0; content := item.content;
  WHILE content # NIL DO
    child := content.element;
    IF IQ.Named(child, uri, "actor") THEN
      INC(actors); IF (actors > 1) OR ~Layout(child) OR ~IQ.Empty(child) THEN RETURN FALSE END;
      event.actorJID := JIDAttribute(child, "jid"); event.actorNick := NickAttribute(child, event.room);
      IF (event.actorJID = NIL) OR (event.actorNick = NIL) OR
         ((event.actorJID[0] = 0) & (event.actorNick[0] = 0)) THEN RETURN FALSE END
    ELSIF IQ.Named(child, uri, "reason") THEN
      INC(reasons); IF reasons > 1 THEN RETURN FALSE END;
      event.reason := Scalar(child, maxTextUnits); IF event.reason = NIL THEN RETURN FALSE END
    ELSIF (child # NIL) & (child.namespaceURI^ = uri) THEN RETURN FALSE
    END;
    content := content.next
  END;
  RETURN TRUE
END ReadItem;

PROCEDURE ReadDestroy(item: Items.Item; event: Occupant): BOOLEAN;
  VAR value: T.String; content: Items.Content; child: Items.Item; reasons: LONGINT;
BEGIN
  IF ~Layout(item) THEN RETURN FALSE END;
  value := item.GetAttribute("", "jid");
  IF value # NIL THEN event.alternateRoom := Room(value^); IF event.alternateRoom = NIL THEN RETURN FALSE END END;
  reasons := 0; content := item.content;
  WHILE content # NIL DO
    child := content.element;
    IF IQ.Named(child, userURI, "reason") THEN
      INC(reasons); IF reasons > 1 THEN RETURN FALSE END;
      event.destroyReason := Scalar(child, maxTextUnits); IF event.destroyReason = NIL THEN RETURN FALSE END
    ELSIF (child # NIL) & (child.namespaceURI^ = userURI) THEN RETURN FALSE
    END;
    content := content.next
  END;
  event.destroyed := TRUE; RETURN TRUE
END ReadDestroy;

PROCEDURE (event: Occupant) HasStatus*(code: LONGINT): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  FOR i := 0 TO event.codeCount-1 DO IF event.codes[i] = code THEN RETURN TRUE END END;
  RETURN FALSE
END HasStatus;

PROCEDURE ReadPresence*(stanza: Core.Stanza; room: ARRAY OF T.CodeUnit): Occupant;
  VAR event: Occupant; from, text: T.String; extension, child: Items.Item;
    content: Items.Content; extensions, items, destroys, code, i: LONGINT;
BEGIN
  IF (stanza = NIL) OR (stanza.kind # Core.presence) OR ~Layout(stanza.item) THEN RETURN NIL END;
  NEW(event); from := Origin(stanza, room, event.room, event.nick); IF from = NIL THEN RETURN NIL END;
  event.presence := P.Read(stanza); IF event.presence = NIL THEN RETURN NIL END;
  IF (event.presence.kind # P.available) & (event.presence.kind # P.unavailable) &
     (event.presence.kind # P.stanzaError) THEN RETURN NIL END;
  event.jid := Items.Latin1(""); event.role := Items.Latin1(""); event.affiliation := Items.Latin1("");
  event.newNick := Items.Latin1(""); event.actorJID := Items.Latin1(""); event.actorNick := Items.Latin1("");
  event.reason := Items.Latin1(""); event.alternateRoom := Items.Latin1(""); event.destroyReason := Items.Latin1("");
  extension := NIL; extensions := 0; content := stanza.item.content;
  WHILE content # NIL DO
    IF IQ.Named(content.element, userURI, "x") THEN INC(extensions); extension := content.element END;
    content := content.next
  END;
  IF event.presence.kind = P.stanzaError THEN
    IF extensions # 0 THEN RETURN NIL END;
    RETURN event
  END;
  IF (event.nick[0] = 0) OR (extensions # 1) OR ~Layout(extension) THEN RETURN NIL END;
  items := 0; destroys := 0; content := extension.content;
  WHILE content # NIL DO
    child := content.element;
    IF IQ.Named(child, userURI, "item") THEN
      INC(items); IF (items > 1) OR ~ReadItem(child, event, FALSE, userURI) THEN RETURN NIL END
    ELSIF IQ.Named(child, userURI, "status") THEN
      IF (event.codeCount = maxCodes) OR ~Layout(child) OR ~IQ.Empty(child) THEN RETURN NIL END;
      text := child.GetAttribute("", "code");
      IF (text = NIL) OR (S.Length(text^) # 3) THEN RETURN NIL END;
      code := 0;
      FOR i := 0 TO 2 DO
        IF (text[i] < ORD("0")) OR (text[i] > ORD("9")) THEN RETURN NIL END;
        code := 10*code+text[i]-ORD("0")
      END;
      IF (code < 100) OR event.HasStatus(code) THEN RETURN NIL END;
      event.codes[event.codeCount] := code; INC(event.codeCount)
    ELSIF IQ.Named(child, userURI, "destroy") THEN
      INC(destroys); IF (destroys > 1) OR ~ReadDestroy(child, event) THEN RETURN NIL END
    ELSIF (child # NIL) & (child.namespaceURI^ = userURI) THEN RETURN NIL
    END;
    content := content.next
  END;
  IF (items # 1) OR (event.destroyed & (event.presence.kind # P.unavailable)) OR
     (event.HasStatus(303) & ((event.presence.kind # P.unavailable) OR (event.newNick[0] = 0))) THEN RETURN NIL END;
  RETURN event
END ReadPresence;

PROCEDURE Language(text: ARRAY OF T.CodeUnit): T.String;
  VAR result: T.String; i, length: LONGINT; code: T.CodeUnit;
BEGIN
  length := S.Length(text); IF length > P.maxLanguageUnits THEN RETURN NIL END;
  result := Items.Copy16(text);
  FOR i := 0 TO length-1 DO
    code := text[i]; IF (code >= ORD("A")) & (code <= ORD("Z")) THEN INC(code, ORD("a")-ORD("A")) END;
    IF ~(((code >= ORD("a")) & (code <= ORD("z"))) OR ((code >= ORD("0")) & (code <= ORD("9"))) OR (code = ORD("-"))) THEN RETURN NIL END;
    IF (code = ORD("-")) & ((i = 0) OR (i = length-1) OR (text[i-1] = ORD("-"))) THEN RETURN NIL END;
    result[i] := code
  END;
  RETURN result
END Language;

PROCEDURE ReadText(item: Items.Item; stanza: Core.Stanza; VAR texts: ARRAY OF Text;
                   VAR count, total: LONGINT): BOOLEAN;
  VAR value, language: T.String; i, length: LONGINT;
BEGIN
  IF count = maxTexts THEN RETURN FALSE END;
  value := Scalar(item, maxTextUnits); IF value = NIL THEN RETURN FALSE END;
  length := S.Length(value^); IF length > maxTotalTextUnits-total THEN RETURN FALSE END;
  language := item.GetAttribute(Core.xmlURI, "lang"); IF language = NIL THEN language := stanza.lang END;
  language := Language(language^); IF language = NIL THEN RETURN FALSE END;
  FOR i := 0 TO count-1 DO IF S.Equal(texts[i].language^, language^) THEN RETURN FALSE END END;
  texts[count].language := language; texts[count].text := value; INC(count); INC(total, length); RETURN TRUE
END ReadText;

PROCEDURE ReadMessage*(stanza: Core.Stanza; room: ARRAY OF T.CodeUnit): Message;
  VAR event: Message; content: Items.Content; child: Items.Item; total: LONGINT;
BEGIN
  IF (stanza = NIL) OR (stanza.kind # Core.message) OR ~S.Equal8(stanza.type^, "groupchat") OR
     ~Layout(stanza.item) THEN RETURN NIL END;
  NEW(event); event.from := Origin(stanza, room, event.room, event.nick); IF event.from = NIL THEN RETURN NIL END;
  event.body := Items.Latin1(""); event.subject := Items.Latin1(""); total := 0; content := stanza.item.content;
  WHILE content # NIL DO
    child := content.element;
    IF IQ.Named(child, "jabber:client", "body") THEN
      IF ~ReadText(child, stanza, event.bodies, event.bodyCount, total) THEN RETURN NIL END
    ELSIF IQ.Named(child, "jabber:client", "subject") THEN
      IF ~ReadText(child, stanza, event.subjects, event.subjectCount, total) THEN RETURN NIL END
    ELSIF IQ.Named(child, "jabber:client", "error") THEN RETURN NIL
    END;
    content := content.next
  END;
  IF (event.bodyCount = 0) & (event.subjectCount = 0) THEN RETURN NIL END;
  IF event.bodyCount > 0 THEN event.body := event.bodies[0].text END;
  IF event.subjectCount > 0 THEN event.subject := event.subjects[0].text END;
  RETURN event
END ReadMessage;

PROCEDURE ReadInvitation*(stanza: Core.Stanza; room: ARRAY OF T.CodeUnit): Invitation;
  VAR event: Invitation; nick, from, value: T.String; extension, child, invitation: Items.Item;
    content: Items.Content; extensions, invitations, passwords, reasons, continues: LONGINT;
BEGIN
  IF (stanza = NIL) OR (stanza.kind # Core.message) OR
     ~((stanza.type[0] = 0) OR S.Equal8(stanza.type^, "normal")) OR ~Layout(stanza.item) THEN RETURN NIL END;
  NEW(event); from := Origin(stanza, room, event.room, nick);
  IF (from = NIL) OR (nick[0] # 0) THEN RETURN NIL END;
  extensions := 0; extension := NIL; content := stanza.item.content;
  WHILE content # NIL DO
    child := content.element;
    IF IQ.Named(child, userURI, "x") THEN INC(extensions); extension := child
    ELSIF IQ.Named(child, "jabber:client", "error") THEN RETURN NIL
    END;
    content := content.next
  END;
  IF (extensions # 1) OR ~Layout(extension) THEN RETURN NIL END;
  invitations := 0; passwords := 0; invitation := NIL;
  event.reason := Items.Latin1(""); event.password := Items.Latin1("");
  event.thread := Items.Latin1(""); content := extension.content;
  WHILE content # NIL DO
    child := content.element;
    IF IQ.Named(child, userURI, "invite") OR IQ.Named(child, userURI, "decline") THEN
      INC(invitations); invitation := child; event.declined := IQ.Named(child, userURI, "decline")
    ELSIF IQ.Named(child, userURI, "password") THEN
      INC(passwords); IF passwords > 1 THEN RETURN NIL END;
      event.password := Scalar(child, maxPasswordUnits); IF event.password = NIL THEN RETURN NIL END
    ELSIF (child # NIL) & (child.namespaceURI^ = userURI) THEN RETURN NIL
    END;
    content := content.next
  END;
  IF (invitations # 1) OR ~Layout(invitation) OR (event.declined & (passwords # 0)) THEN RETURN NIL END;
  event.peer := JIDAttribute(invitation, "from");
  IF (event.peer = NIL) OR (event.peer[0] = 0) OR (invitation.GetAttribute("", "to") # NIL) THEN RETURN NIL END;
  reasons := 0; continues := 0; content := invitation.content;
  WHILE content # NIL DO
    child := content.element;
    IF IQ.Named(child, userURI, "reason") THEN
      INC(reasons); IF reasons > 1 THEN RETURN NIL END;
      value := Scalar(child, maxTextUnits); IF value = NIL THEN RETURN NIL END; event.reason := value
    ELSIF IQ.Named(child, userURI, "continue") THEN
      INC(continues);
      IF event.declined OR (continues > 1) OR ~Layout(child) OR ~IQ.Empty(child) THEN RETURN NIL END;
      event.thread := Attribute(child, "thread", 1024); IF event.thread = NIL THEN RETURN NIL END;
      event.continued := TRUE
    ELSIF (child # NIL) & (child.namespaceURI^ = userURI) THEN RETURN NIL
    END;
    content := content.next
  END;
  RETURN event
END ReadInvitation;

PROCEDURE RoomQuery(router: IQ.Router; room: ARRAY OF T.CodeUnit; query: Items.Item;
                    set: BOOLEAN; timeoutMS: LONGINT; action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
  VAR target: T.String;
BEGIN
  target := Room(room);
  IF (router = NIL) OR (target = NIL) THEN RETURN Invalid(error) END;
  RETURN router.QueryExact(target^, query, set, timeoutMS, action, error)
END RoomQuery;

PROCEDURE RequestConfiguration*(router: IQ.Router; room: ARRAY OF T.CodeUnit;
                               timeoutMS: LONGINT; action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
BEGIN
  RETURN RoomQuery(router, room, Items.New("query", ownerURI), FALSE, timeoutMS, action, error)
END RequestConfiguration;

PROCEDURE FormTree(item: Items.Item; depth: LONGINT; VAR nodes, units: LONGINT): BOOLEAN;
  VAR content: Items.Content; attribute: Items.Attribute; count, length: LONGINT;
BEGIN
  INC(nodes);
  IF (nodes > maxFormNodes) OR (depth > 16) OR (item.namespaceURI^ # formURI) THEN RETURN FALSE END;
  count := 0; attribute := item.attributes;
  WHILE attribute # NIL DO
    INC(count); IF count > maxParts THEN RETURN FALSE END;
    length := S.Length(attribute.value^);
    IF ~IQ.Value(attribute.value^, maxFormUnits-units) THEN RETURN FALSE END;
    INC(units, length); attribute := attribute.next
  END;
  content := item.content; count := 0;
  WHILE content # NIL DO
    INC(count); IF count > maxParts THEN RETURN FALSE END;
    IF content.element # NIL THEN
      IF ~FormTree(content.element, depth+1, nodes, units) THEN RETURN FALSE END
    ELSE
      length := S.Length(content.text^);
      IF ~IQ.Value(content.text^, maxFormUnits-units) THEN RETURN FALSE END;
      INC(units, length)
    END;
    content := content.next
  END;
  RETURN TRUE
END FormTree;

PROCEDURE ReadConfiguration*(request: IQ.Request): Items.Item;
  VAR query, form: Items.Item; content: Items.Content; type: T.String; count, nodes, units: LONGINT;
BEGIN
  IF (request = NIL) OR ~IQ.Named(request.payload, ownerURI, "query") OR
     ~IQ.Empty(request.payload) THEN RETURN NIL END;
  query := IQ.Payload(request, ownerURI, "query"); IF (query = NIL) OR ~Layout(query) THEN RETURN NIL END;
  form := NIL; count := 0; content := query.content;
  WHILE content # NIL DO
    IF content.element # NIL THEN
      IF ~IQ.Named(content.element, formURI, "x") THEN RETURN NIL END;
      INC(count); form := content.element
    END;
    content := content.next
  END;
  IF count # 1 THEN RETURN NIL END;
  type := form.GetAttribute("", "type");
  IF (type = NIL) OR ~S.Equal8(type^, "form") THEN RETURN NIL END;
  nodes := 0; units := 0;
  IF ~FormTree(form, 0, nodes, units) THEN RETURN NIL END;
  RETURN form
END ReadConfiguration;

PROCEDURE Submission(form: Items.Item): BOOLEAN;
  VAR type, name, value: T.String; content, values: Items.Content; field: Items.Item;
    names: ARRAY maxFormFields OF T.String; count, i, nodes, units, typeFields, typeValues: LONGINT;
BEGIN
  IF ~IQ.Named(form, formURI, "x") OR (form.parent # NIL) OR ~Layout(form) THEN RETURN FALSE END;
  type := form.GetAttribute("", "type"); IF (type = NIL) OR ~S.Equal8(type^, "submit") THEN RETURN FALSE END;
  nodes := 0; units := 0; IF ~FormTree(form, 0, nodes, units) THEN RETURN FALSE END;
  count := 0; typeFields := 0; content := form.content;
  WHILE content # NIL DO
    field := content.element;
    IF field # NIL THEN
      IF (count = maxFormFields) OR ~IQ.Named(field, formURI, "field") OR ~Layout(field) THEN RETURN FALSE END;
      name := field.GetAttribute("", "var");
      IF (name = NIL) OR (name[0] = 0) OR ~IQ.Value(name^, 256) THEN RETURN FALSE END;
      FOR i := 0 TO count-1 DO IF S.Equal(names[i]^, name^) THEN RETURN FALSE END END;
      names[count] := name; INC(count); values := field.content; typeValues := 0;
      WHILE values # NIL DO
        IF values.element # NIL THEN
          IF ~IQ.Named(values.element, formURI, "value") THEN RETURN FALSE END;
          value := Scalar(values.element, maxTextUnits); IF value = NIL THEN RETURN FALSE END;
          IF S.Equal8(name^, "FORM_TYPE") THEN
            INC(typeValues); IF ~S.Equal8(value^, configURI) THEN RETURN FALSE END
          END
        END;
        values := values.next
      END;
      IF S.Equal8(name^, "FORM_TYPE") THEN
        IF typeValues # 1 THEN RETURN FALSE END; INC(typeFields)
      END
    END;
    content := content.next
  END;
  RETURN typeFields = 1
END Submission;

PROCEDURE SubmitConfiguration*(router: IQ.Router; room: ARRAY OF T.CodeUnit; form: Items.Item;
                              timeoutMS: LONGINT; action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
  VAR query: Items.Item; target: T.String;
BEGIN
  target := Room(room);
  IF (router = NIL) OR (target = NIL) OR (action = NIL) OR
     (timeoutMS <= 0) OR (timeoutMS > IQ.maxTimeoutMS) OR ~Submission(form) THEN RETURN Invalid(error) END;
  query := Items.New("query", ownerURI); query.AddChild(form);
  RETURN router.QueryExact(target^, query, TRUE, timeoutMS, action, error)
END SubmitConfiguration;

PROCEDURE ConfigureDefault*(router: IQ.Router; room: ARRAY OF T.CodeUnit; cancel: BOOLEAN;
                           timeoutMS: LONGINT; action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
  VAR query, form: Items.Item; type: T.String;
BEGIN
  query := Items.New("query", ownerURI); form := Items.New("x", formURI);
  IF cancel THEN type := Items.Latin1("cancel") ELSE type := Items.Latin1("submit") END;
  form.SetParam("type", type^); query.AddChild(form);
  RETURN RoomQuery(router, room, query, TRUE, timeoutMS, action, error)
END ConfigureDefault;

PROCEDURE Destroy*(router: IQ.Router; room, alternate, reason: ARRAY OF T.CodeUnit;
                   timeoutMS: LONGINT; action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
  VAR query, destroy: Items.Item; target: T.String;
BEGIN
  IF ~IQ.Value(reason, maxTextUnits) THEN RETURN Invalid(error) END;
  target := NIL;
  IF alternate[0] # 0 THEN target := Room(alternate); IF target = NIL THEN RETURN Invalid(error) END END;
  query := Items.New("query", ownerURI); destroy := Items.New("destroy", ownerURI);
  IF target # NIL THEN destroy.SetParam("jid", target^) END;
  IF reason[0] # 0 THEN AddText(destroy, ownerURI, "reason", reason) END;
  query.AddChild(destroy); RETURN RoomQuery(router, room, query, TRUE, timeoutMS, action, error)
END Destroy;

PROCEDURE SetRole*(router: IQ.Router; room, nick, role, reason: ARRAY OF T.CodeUnit;
                   timeoutMS: LONGINT; action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
  VAR query, item: Items.Item; target: T.String;
BEGIN
  target := OccupantJID(room, nick);
  IF (target = NIL) OR ~RoleValue(role) OR ~IQ.Value(reason, maxTextUnits) THEN RETURN Invalid(error) END;
  query := Items.New("query", adminURI); item := Items.New("item", adminURI);
  item.SetParam("nick", nick); item.SetParam("role", role);
  IF reason[0] # 0 THEN AddText(item, adminURI, "reason", reason) END;
  query.AddChild(item); RETURN RoomQuery(router, room, query, TRUE, timeoutMS, action, error)
END SetRole;

PROCEDURE SetAffiliation*(router: IQ.Router; room, jid, affiliation, reason: ARRAY OF T.CodeUnit;
                          timeoutMS: LONGINT; action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
  VAR query, item: Items.Item; target, bare: T.String;
BEGIN
  target := IQ.CanonicalJID(jid);
  IF (target = NIL) OR ~AffiliationValue(affiliation) OR ~IQ.Value(reason, maxTextUnits) THEN RETURN Invalid(error) END;
  bare := P.Bare(target^); IF ~S.Equal(bare^, target^) THEN RETURN Invalid(error) END;
  query := Items.New("query", adminURI); item := Items.New("item", adminURI);
  item.SetParam("jid", target^); item.SetParam("affiliation", affiliation);
  IF reason[0] # 0 THEN AddText(item, adminURI, "reason", reason) END;
  query.AddChild(item); RETURN RoomQuery(router, room, query, TRUE, timeoutMS, action, error)
END SetAffiliation;

PROCEDURE RequestRoleList*(router: IQ.Router; room, role: ARRAY OF T.CodeUnit;
                          timeoutMS: LONGINT; action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
  VAR query, item: Items.Item;
BEGIN
  IF ~RoleValue(role) OR S.Equal8(role, "none") THEN RETURN Invalid(error) END;
  query := Items.New("query", adminURI); item := Items.New("item", adminURI); item.SetParam("role", role);
  query.AddChild(item); RETURN RoomQuery(router, room, query, FALSE, timeoutMS, action, error)
END RequestRoleList;

PROCEDURE RequestAffiliationList*(router: IQ.Router; room, affiliation: ARRAY OF T.CodeUnit;
                                 timeoutMS: LONGINT; action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
  VAR query, item: Items.Item;
BEGIN
  IF ~AffiliationValue(affiliation) OR S.Equal8(affiliation, "none") THEN RETURN Invalid(error) END;
  query := Items.New("query", adminURI); item := Items.New("item", adminURI); item.SetParam("affiliation", affiliation);
  query.AddChild(item); RETURN RoomQuery(router, room, query, FALSE, timeoutMS, action, error)
END RequestAffiliationList;

PROCEDURE ReadMembers*(request: IQ.Request): MemberList;
  VAR list: MemberList; query, filter, item: Items.Item; content: Items.Content;
    role, affiliation, room, bare: T.String; event: Occupant; i: LONGINT;
BEGIN
  IF (request = NIL) OR ~IQ.Named(request.payload, adminURI, "query") THEN RETURN NIL END;
  filter := request.payload.First(adminURI, "item"); IF filter = NIL THEN RETURN NIL END;
  (* List requests have a filter, not an occupant mutation. *)
  IF (filter.GetAttribute("", "nick") # NIL) OR (filter.GetAttribute("", "jid") # NIL) THEN RETURN NIL END;
  role := filter.GetAttribute("", "role"); affiliation := filter.GetAttribute("", "affiliation");
  IF (role = NIL) = (affiliation = NIL) THEN RETURN NIL END;
  query := IQ.Payload(request, adminURI, "query"); room := Room(request.peer^);
  IF (query = NIL) OR (room = NIL) OR ~Layout(query) THEN RETURN NIL END;
  NEW(list); content := query.content;
  WHILE content # NIL DO
    item := content.element;
    IF item # NIL THEN
      IF (list.count = maxMembers) OR ~IQ.Named(item, adminURI, "item") THEN RETURN NIL END;
      NEW(event); event.room := room;
      event.actorJID := Items.Latin1(""); event.actorNick := Items.Latin1(""); event.reason := Items.Latin1("");
      IF ~ReadItem(item, event, TRUE, adminURI) THEN RETURN NIL END;
      IF role # NIL THEN
        IF (event.newNick[0] = 0) OR ~S.Equal(role^, event.role^) THEN RETURN NIL END
      ELSE
        IF (event.jid[0] = 0) OR ~S.Equal(affiliation^, event.affiliation^) THEN RETURN NIL END;
        bare := P.Bare(event.jid^); IF ~S.Equal(bare^, event.jid^) THEN RETURN NIL END
      END;
      FOR i := 0 TO list.count-1 DO
        IF ((role # NIL) & S.Equal(list.entries[i].nick^, event.newNick^)) OR
           ((affiliation # NIL) & S.Equal(list.entries[i].jid^, event.jid^)) THEN RETURN NIL END
      END;
      list.entries[list.count].nick := event.newNick; list.entries[list.count].jid := event.jid;
      list.entries[list.count].role := event.role; list.entries[list.count].affiliation := event.affiliation;
      list.entries[list.count].actorJID := event.actorJID; list.entries[list.count].actorNick := event.actorNick;
      list.entries[list.count].reason := event.reason; INC(list.count)
    END;
    content := content.next
  END;
  RETURN list
END ReadMembers;

BEGIN NEW(context); Msg.InitContext(context, "XmppMuc")
END XmppMuc.
