MODULE XmppPresence;

(* RFC 6121 presence construction and bounded, namespace-aware decoding. *)

IMPORT S := LongStrings, IntStr, T := XmppTypes, Const := XmppConst,
  Items := XmppItems, Core := XmppCore, IQ := XmppIQ, J := XmppStrings;

CONST
  available* = 0; unavailable* = 1; subscribe* = 2; subscribed* = 3;
  unsubscribe* = 4; unsubscribed* = 5; probe* = 6; stanzaError* = 7;
  maxStatuses* = 8; maxStatusUnits* = 4096; maxTotalStatusUnits* = 8192;
  maxLanguageUnits* = 63;

TYPE
  Status* = RECORD language-, text-: T.String END;
  Event* = POINTER TO EventDesc;
  EventDesc* = RECORD
    kind-: SHORTINT;
    from-, bare-, to-, show-, status-: T.String;
    priority-, statusCount-: LONGINT;
    statuses-: ARRAY maxStatuses OF Status;
    error-: Items.Item;
  END;

PROCEDURE Bare*(jid: ARRAY OF T.CodeUnit): T.String;
  VAR canonical: T.String; text: ARRAY IQ.maxJIDUnits+1 OF T.CodeUnit;
BEGIN
  canonical := IQ.CanonicalJID(jid); IF canonical = NIL THEN RETURN NIL END;
  J.GetShortJidFromFullJid(canonical^, text); RETURN Items.Copy16(text)
END Bare;

PROCEDURE Show(text: ARRAY OF T.CodeUnit): BOOLEAN;
BEGIN
  RETURN S.Equal8(text, "away") OR S.Equal8(text, "chat") OR S.Equal8(text, "dnd") OR S.Equal8(text, "xa")
END Show;

PROCEDURE Text(parent: Items.Item; name: ARRAY OF CHAR; text: ARRAY OF T.CodeUnit);
  VAR child: Items.Item;
BEGIN child := Items.New(name, Const.jabberClient); child.AddText(text, 0, S.Length(text)); parent.AddChild(child) END Text;

PROCEDURE Base(to, status: ARRAY OF T.CodeUnit; type: ARRAY OF CHAR): Core.Stanza;
  VAR stanza: Core.Stanza; target, value: T.String;
BEGIN
  IF ~IQ.Value(status, maxStatusUnits) THEN RETURN NIL END;
  target := NIL;
  IF to[0] # 0 THEN target := IQ.CanonicalJID(to); IF target = NIL THEN RETURN NIL END END;
  stanza := Core.NewStanza(Const.presence);
  IF target # NIL THEN stanza.item.SetParam(Const.to, target^) END;
  IF type[0] # 0X THEN value := Items.Latin1(type); stanza.item.SetParam(Const.type, value^) END;
  IF status[0] # 0 THEN Text(stanza.item, "status", status) END;
  RETURN stanza
END Base;

PROCEDURE Available*(to, show, status: ARRAY OF T.CodeUnit; priority: LONGINT): Core.Stanza;
  VAR stanza: Core.Stanza; number: ARRAY 16 OF CHAR; value: T.String;
BEGIN
  IF ((show[0] # 0) & ~Show(show)) OR (priority < -128) OR (priority > 127) THEN RETURN NIL END;
  stanza := Base(to, status, ""); IF stanza = NIL THEN RETURN NIL END;
  IF show[0] # 0 THEN Text(stanza.item, "show", show) END;
  IntStr.IntToStr(priority, number); value := Items.Latin1(number); Text(stanza.item, "priority", value^);
  RETURN Core.Wrap(stanza.item, NIL)
END Available;

PROCEDURE Unavailable*(to, status: ARRAY OF T.CodeUnit): Core.Stanza;
  VAR stanza: Core.Stanza;
BEGIN stanza := Base(to, status, "unavailable"); IF stanza = NIL THEN RETURN NIL END; RETURN Core.Wrap(stanza.item, NIL) END Unavailable;

PROCEDURE Subscription*(to, status: ARRAY OF T.CodeUnit; kind: SHORTINT): Core.Stanza;
  VAR target, bare: T.String; type: ARRAY 16 OF CHAR; stanza: Core.Stanza;
BEGIN
  target := IQ.CanonicalJID(to); bare := Bare(to);
  IF (target = NIL) OR (bare = NIL) OR ~S.Equal(target^, bare^) THEN RETURN NIL END;
  CASE kind OF
  | subscribe: type := "subscribe"
  | subscribed: type := "subscribed"
  | unsubscribe: type := "unsubscribe"
  | unsubscribed: type := "unsubscribed"
  ELSE RETURN NIL
  END;
  stanza := Base(target^, status, type); IF stanza = NIL THEN RETURN NIL END;
  RETURN Core.Wrap(stanza.item, NIL)
END Subscription;

PROCEDURE Scalar(item: Items.Item; maximum: LONGINT): T.String;
  VAR content: Items.Content; length: LONGINT; text: T.String;
BEGIN
  content := item.content; length := 0;
  WHILE content # NIL DO
    IF content.element # NIL THEN RETURN NIL END;
    INC(length, S.Length(content.text^)); IF length > maximum THEN RETURN NIL END;
    content := content.next
  END;
  text := item.Text(); IF ~IQ.Value(text^, maximum) THEN RETURN NIL END; RETURN text
END Scalar;

PROCEDURE Language(text: ARRAY OF T.CodeUnit): T.String;
  VAR result: T.String; i: LONGINT; code: T.CodeUnit;
BEGIN
  IF S.Length(text) > maxLanguageUnits THEN RETURN NIL END;
  result := Items.Copy16(text);
  FOR i := 0 TO S.Length(text)-1 DO
    code := text[i]; IF (code >= ORD("A")) & (code <= ORD("Z")) THEN INC(code, ORD("a")-ORD("A")) END;
    IF ~(((code >= ORD("a")) & (code <= ORD("z"))) OR ((code >= ORD("0")) & (code <= ORD("9"))) OR (code = ORD("-"))) THEN RETURN NIL END;
    IF (code = ORD("-")) & ((i = 0) OR (i = S.Length(text)-1) OR (text[i-1] = ORD("-"))) THEN RETURN NIL END;
    result[i] := code
  END;
  RETURN result
END Language;

PROCEDURE Priority(text: ARRAY OF T.CodeUnit; VAR value: LONGINT): BOOLEAN;
  VAR i, end: LONGINT; negative: BOOLEAN;
BEGIN
  i := 0; end := S.Length(text); value := 0; negative := FALSE;
  WHILE (i < end) & ((text[i] = 32) OR (text[i] = 9) OR (text[i] = 10) OR (text[i] = 13)) DO INC(i) END;
  WHILE (end > i) & ((text[end-1] = 32) OR (text[end-1] = 9) OR (text[end-1] = 10) OR (text[end-1] = 13)) DO DEC(end) END;
  IF (i < end) & ((text[i] = ORD("-")) OR (text[i] = ORD("+"))) THEN negative := text[i] = ORD("-"); INC(i) END;
  IF i = end THEN RETURN FALSE END;
  WHILE i < end DO
    IF (text[i] < ORD("0")) OR (text[i] > ORD("9")) OR (value > 128) THEN RETURN FALSE END;
    value := 10*value+text[i]-ORD("0"); INC(i)
  END;
  IF negative THEN value := -value END;
  RETURN (value >= -128) & (value <= 127)
END Priority;

PROCEDURE White(text: T.String): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  FOR i := 0 TO S.Length(text^)-1 DO
    IF (text[i] # 32) & (text[i] # 9) & (text[i] # 10) & (text[i] # 13) THEN RETURN FALSE END
  END;
  RETURN TRUE
END White;

PROCEDURE ValidError(item: Items.Item): BOOLEAN;
  VAR type, text: T.String; content: Items.Content; conditions, texts: LONGINT;
BEGIN
  type := item.GetAttribute("", "type");
  IF (type = NIL) OR ~(S.Equal8(type^, "auth") OR S.Equal8(type^, "cancel") OR S.Equal8(type^, "continue") OR
     S.Equal8(type^, "modify") OR S.Equal8(type^, "wait")) THEN RETURN FALSE END;
  conditions := 0; texts := 0; content := item.content;
  WHILE content # NIL DO
    IF content.element # NIL THEN
      IF content.element.namespaceURI^ = Const.uriStanzas THEN
        IF S.Equal8(content.element.name^, "text") THEN
          INC(texts); text := Scalar(content.element, maxStatusUnits); IF text = NIL THEN RETURN FALSE END
        ELSE
          INC(conditions); IF ~IQ.Empty(content.element) THEN RETURN FALSE END
        END
      END
    ELSIF ~White(content.text) THEN RETURN FALSE
    END;
    content := content.next
  END;
  RETURN (conditions = 1) & (texts <= 1)
END ValidError;

PROCEDURE Read*(stanza: Core.Stanza): Event;
  VAR event: Event; content: Items.Content; item: Items.Item; text, lang: T.String;
    showCount, priorityCount, errors, total, i: LONGINT;
BEGIN
  IF (stanza = NIL) OR (stanza.kind # Core.presence) THEN RETURN NIL END;
  NEW(event); event.from := IQ.CanonicalJID(stanza.from^); IF event.from = NIL THEN RETURN NIL END;
  event.bare := Bare(event.from^); event.to := Items.Latin1("");
  IF stanza.item.GetAttribute("", "to") # NIL THEN
    event.to := IQ.CanonicalJID(stanza.to^); IF event.to = NIL THEN RETURN NIL END
  END;
  IF stanza.type[0] = 0 THEN
    IF stanza.item.GetAttribute("", "type") # NIL THEN RETURN NIL END;
    event.kind := available
  ELSIF S.Equal8(stanza.type^, "unavailable") THEN event.kind := unavailable
  ELSIF S.Equal8(stanza.type^, "subscribe") THEN event.kind := subscribe
  ELSIF S.Equal8(stanza.type^, "subscribed") THEN event.kind := subscribed
  ELSIF S.Equal8(stanza.type^, "unsubscribe") THEN event.kind := unsubscribe
  ELSIF S.Equal8(stanza.type^, "unsubscribed") THEN event.kind := unsubscribed
  ELSIF S.Equal8(stanza.type^, "probe") THEN event.kind := probe
  ELSIF S.Equal8(stanza.type^, "error") THEN event.kind := stanzaError
  ELSE RETURN NIL
  END;
  event.show := Items.Latin1(""); event.status := Items.Latin1("");
  showCount := 0; priorityCount := 0; errors := 0; total := 0; content := stanza.item.content;
  WHILE content # NIL DO
    item := content.element;
    IF item # NIL THEN
      IF IQ.Named(item, Const.jabberClient, "show") THEN
        INC(showCount); text := Scalar(item, 16);
        IF (text = NIL) OR ~Show(text^) THEN RETURN NIL END; event.show := text
      ELSIF IQ.Named(item, Const.jabberClient, "priority") THEN
        INC(priorityCount); text := Scalar(item, 32);
        IF (text = NIL) OR ~Priority(text^, event.priority) THEN RETURN NIL END
      ELSIF IQ.Named(item, Const.jabberClient, "status") THEN
        IF event.statusCount = maxStatuses THEN RETURN NIL END;
        text := Scalar(item, maxStatusUnits); IF text = NIL THEN RETURN NIL END;
        INC(total, S.Length(text^)); IF total > maxTotalStatusUnits THEN RETURN NIL END;
        lang := item.GetAttribute(Core.xmlURI, "lang"); IF lang = NIL THEN lang := stanza.lang END;
        lang := Language(lang^); IF lang = NIL THEN RETURN NIL END;
        FOR i := 0 TO event.statusCount-1 DO IF S.Equal(event.statuses[i].language^, lang^) THEN RETURN NIL END END;
        event.statuses[event.statusCount].language := lang; event.statuses[event.statusCount].text := text;
        IF event.statusCount = 0 THEN event.status := text END; INC(event.statusCount)
      ELSIF IQ.Named(item, Const.jabberClient, "error") THEN
        INC(errors); IF ~ValidError(item) THEN RETURN NIL END; event.error := item
      ELSIF item.namespaceURI^ = Const.jabberClient THEN RETURN NIL
      END
    ELSIF ~White(content.text) THEN RETURN NIL
    END;
    content := content.next
  END;
  IF (showCount > 1) OR (priorityCount > 1) OR
     ((event.kind = stanzaError) & (errors # 1)) OR ((event.kind # stanzaError) & (errors # 0)) THEN RETURN NIL END;
  RETURN event
END Read;

PROCEDURE NewPresence*(to, status: ARRAY OF T.CodeUnit): Core.Stanza;
  VAR stanza: Core.Stanza; child: Items.Item;
BEGIN
  stanza := Core.NewStanza(Const.presence);
  IF S.Length(to) > 0 THEN stanza.item.SetParam(Const.to, to) END;
  IF S.Length(status) > 0 THEN
    child := Items.New("status", Const.jabberClient); child.AddText(status, 0, S.Length(status)); stanza.item.AddChild(child)
  END;
  RETURN Core.Wrap(stanza.item, NIL)
END NewPresence;

END XmppPresence.
