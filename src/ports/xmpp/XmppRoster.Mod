MODULE XmppRoster;

(* Bounded RFC 6121 roster snapshots, edits and authenticated server pushes. *)

IMPORT Msg, S := LongStrings, T := XmppTypes, Items := XmppItems,
  Core := XmppCore, IQ := XmppIQ, J := XmppStrings;

CONST
  namespaceURI* = "jabber:iq:roster";
  maxItems* = 256; maxGroups* = 16; maxValueUnits* = 1024;
  maxRosterUnits* = 262144;
  none* = 0; to* = 1; from* = 2; both* = 3; remove* = 4;

TYPE
  Entry* = POINTER TO EntryDesc;
  EntryDesc* = RECORD
    jid-, name-: T.String;
    subscription-: SHORTINT;
    pending-, approved-: BOOLEAN;
    groupCount-: LONGINT;
    groups-: ARRAY maxGroups OF T.String;
    units: LONGINT;
  END;
  Snapshot* = POINTER TO SnapshotDesc;
  SnapshotDesc* = RECORD
    count-: LONGINT;
    entries-: ARRAY maxItems OF Entry;
    units: LONGINT;
  END;
  Roster* = POINTER TO RosterDesc;
  Hook* = POINTER TO HookDesc;
  HookDesc* = RECORD END;
  FetchAction = POINTER TO FetchActionDesc;
  FetchActionDesc = RECORD (IQ.ActionDesc) owner: Roster; dirty: BOOLEAN END;
  RosterDesc* = RECORD (IQ.HandlerDesc)
    snapshot-: Snapshot;
    complete-: BOOLEAN;
    router: IQ.Router;
    hook: Hook;
    fetch: FetchAction;
  END;

PROCEDURE Bare(text: ARRAY OF T.CodeUnit): T.String;
  VAR jid: T.String; i: LONGINT;
BEGIN
  jid := IQ.CanonicalJID(text); IF jid = NIL THEN RETURN NIL END;
  FOR i := 0 TO S.Length(jid^)-1 DO IF jid[i] = ORD("/") THEN RETURN NIL END END;
  RETURN jid
END Bare;

PROCEDURE Scalar(item: Items.Item; VAR text: T.String): BOOLEAN;
  VAR content: Items.Content; units: LONGINT;
BEGIN
  units := 0; content := item.content;
  WHILE content # NIL DO
    IF content.element # NIL THEN RETURN FALSE END;
    INC(units, S.Length(content.text^)); IF units > maxValueUnits THEN RETURN FALSE END;
    content := content.next
  END;
  text := item.Text(); RETURN IQ.Value(text^, maxValueUnits)
END Scalar;

PROCEDURE White(text: T.String): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  FOR i := 0 TO S.Length(text^)-1 DO
    IF (text[i] # 32) & (text[i] # 9) & (text[i] # 10) & (text[i] # 13) THEN RETURN FALSE END
  END;
  RETURN TRUE
END White;

PROCEDURE ReadEntry*(item: Items.Item; removing: BOOLEAN): Entry;
  VAR e: Entry; value: T.String; content: Items.Content; i: LONGINT;
BEGIN
  IF ~IQ.Named(item, namespaceURI, "item") THEN RETURN NIL END;
  value := item.GetAttribute("", "jid"); IF value = NIL THEN RETURN NIL END;
  NEW(e); e.jid := Bare(value^); IF e.jid = NIL THEN RETURN NIL END;
  e.name := item.GetAttribute("", "name"); IF e.name = NIL THEN e.name := Items.Latin1("") END;
  IF ~IQ.Value(e.name^, maxValueUnits) THEN RETURN NIL END;
  e.units := S.Length(e.jid^)+S.Length(e.name^);
  value := item.GetAttribute("", "subscription");
  IF value # NIL THEN
    IF S.Equal8(value^, "none") THEN e.subscription := none
    ELSIF S.Equal8(value^, "to") THEN e.subscription := to
    ELSIF S.Equal8(value^, "from") THEN e.subscription := from
    ELSIF S.Equal8(value^, "both") THEN e.subscription := both
    ELSIF removing & S.Equal8(value^, "remove") THEN e.subscription := remove
    ELSE RETURN NIL
    END
  END;
  value := item.GetAttribute("", "ask");
  IF value # NIL THEN IF ~S.Equal8(value^, "subscribe") THEN RETURN NIL END; e.pending := TRUE END;
  value := item.GetAttribute("", "approved");
  IF value # NIL THEN
    IF S.Equal8(value^, "true") OR S.Equal8(value^, "1") THEN e.approved := TRUE
    ELSIF ~S.Equal8(value^, "false") & ~S.Equal8(value^, "0") THEN RETURN NIL
    END
  END;
  content := item.content;
  WHILE content # NIL DO
    IF content.element # NIL THEN
      IF IQ.Named(content.element, namespaceURI, "group") THEN
        IF (e.groupCount = maxGroups) OR ~Scalar(content.element, value) THEN RETURN NIL END;
        FOR i := 0 TO e.groupCount-1 DO IF S.Equal(e.groups[i]^, value^) THEN RETURN NIL END END;
        e.groups[e.groupCount] := value; INC(e.groupCount); INC(e.units, S.Length(value^))
      ELSIF content.element.namespaceURI^ = namespaceURI THEN RETURN NIL
      END
    ELSIF ~White(content.text) THEN RETURN NIL
    END;
    content := content.next
  END;
  RETURN e
END ReadEntry;

PROCEDURE Read*(request: IQ.Request): Snapshot;
  VAR query: Items.Item; content: Items.Content; snapshot: Snapshot; entry: Entry; i: LONGINT;
BEGIN
  IF (request = NIL) OR ~IQ.Named(request.payload, namespaceURI, "query") THEN RETURN NIL END;
  query := IQ.Payload(request, namespaceURI, "query"); IF query = NIL THEN RETURN NIL END;
  NEW(snapshot); content := query.content;
  WHILE content # NIL DO
    IF content.element # NIL THEN
      IF snapshot.count = maxItems THEN RETURN NIL END;
      entry := ReadEntry(content.element, FALSE); IF entry = NIL THEN RETURN NIL END;
      FOR i := 0 TO snapshot.count-1 DO
        IF S.Equal(snapshot.entries[i].jid^, entry.jid^) THEN RETURN NIL END
      END;
      INC(snapshot.units, entry.units); IF snapshot.units > maxRosterUnits THEN RETURN NIL END;
      snapshot.entries[snapshot.count] := entry; INC(snapshot.count)
    ELSIF ~White(content.text) THEN RETURN NIL
    END;
    content := content.next
  END;
  RETURN snapshot
END Read;

PROCEDURE BuildSet*(jid, name: ARRAY OF T.CodeUnit; groups: ARRAY OF T.String; removing: BOOLEAN): Items.Item;
  VAR canonical, value: T.String; query, item, group: Items.Item; i, j: LONGINT;
BEGIN
  canonical := Bare(jid);
  IF (canonical = NIL) OR ~IQ.Value(name, maxValueUnits) OR (LEN(groups) > maxGroups) THEN RETURN NIL END;
  FOR i := 0 TO LEN(groups)-1 DO
    IF (groups[i] = NIL) OR ~IQ.Value(groups[i]^, maxValueUnits) THEN RETURN NIL END;
    FOR j := 0 TO i-1 DO IF S.Equal(groups[i]^, groups[j]^) THEN RETURN NIL END END
  END;
  query := Items.New("query", namespaceURI); item := Items.New("item", namespaceURI);
  item.SetParam("jid", canonical^); query.AddChild(item);
  IF removing THEN value := Items.Latin1("remove"); item.SetParam("subscription", value^)
  ELSE
    IF name[0] # 0 THEN item.SetParam("name", name) END;
    FOR i := 0 TO LEN(groups)-1 DO
      group := Items.New("group", namespaceURI); group.AddText(groups[i]^, 0, S.Length(groups[i]^)); item.AddChild(group)
    END
  END;
  RETURN query
END BuildSet;

PROCEDURE Set*(router: IQ.Router; jid, name: ARRAY OF T.CodeUnit; groups: ARRAY OF T.String;
               removing: BOOLEAN; timeoutMS: LONGINT; action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
  VAR empty: T.String;
BEGIN
  empty := Items.Latin1("");
  RETURN router.Query(empty^, BuildSet(jid, name, groups, removing), TRUE, timeoutMS, action, error)
END Set;

PROCEDURE (h: Hook) Loaded*(roster: Roster; request: IQ.Request; accepted: BOOLEAN);
BEGIN END Loaded;
PROCEDURE (h: Hook) Changed*(roster: Roster; entry: Entry);
BEGIN END Changed;

PROCEDURE (a: FetchAction) Done(router: IQ.Router; request: IQ.Request);
  VAR snapshot: Snapshot; accepted: BOOLEAN;
BEGIN
  a.owner.fetch := NIL; snapshot := Read(request); accepted := (snapshot # NIL) & ~a.dirty;
  IF accepted THEN a.owner.snapshot := snapshot; a.owner.complete := TRUE END;
  a.owner.hook.Loaded(a.owner, request, accepted)
END Done;

PROCEDURE (r: Roster) Fetch*(timeoutMS: LONGINT; VAR error: Msg.Msg): IQ.Request;
  VAR a: FetchAction; request: IQ.Request; empty: T.String; query: Items.Item;
BEGIN
  empty := Items.Latin1("");
  IF r.fetch # NIL THEN RETURN r.router.Query(empty^, NIL, FALSE, timeoutMS, NIL, error) END;
  NEW(a); a.owner := r; r.fetch := a; query := Items.New("query", namespaceURI);
  request := r.router.Query(empty^, query, FALSE, timeoutMS, a, error);
  IF (request = NIL) & (r.fetch = a) THEN r.fetch := NIL END;
  RETURN request
END Fetch;

PROCEDURE (r: Roster) Find*(jid: ARRAY OF T.CodeUnit): Entry;
  VAR canonical: T.String; i: LONGINT;
BEGIN
  canonical := Bare(jid); IF canonical = NIL THEN RETURN NIL END;
  FOR i := 0 TO r.snapshot.count-1 DO
    IF S.Equal(r.snapshot.entries[i].jid^, canonical^) THEN RETURN r.snapshot.entries[i] END
  END;
  RETURN NIL
END Find;

PROCEDURE (r: Roster) Accept*(router: IQ.Router; request: Core.Stanza): BOOLEAN;
  VAR sender, own: T.String; bare: ARRAY IQ.maxJIDUnits+1 OF T.CodeUnit;
BEGIN
  IF request.from[0] = 0 THEN RETURN request.item.GetAttribute("", "from") = NIL END;
  sender := Bare(request.from^); IF sender = NIL THEN RETURN FALSE END;
  J.GetShortJidFromFullJid(router.client.jid^, bare);
  own := Bare(bare); RETURN (own # NIL) & S.Equal(sender^, own^)
END Accept;

PROCEDURE (r: Roster) Handle*(router: IQ.Router; request: Core.Stanza; payload: Items.Item): Core.Stanza;
  VAR entry: Entry; content: Items.Content; count, slot, i, units: LONGINT; next: Snapshot;
BEGIN
  IF ~r.Accept(router, request) THEN RETURN NIL END;
  IF ~S.Equal8(request.type^, "set") THEN RETURN IQ.ErrorReply(request, "modify", "bad-request") END;
  count := 0; content := payload.content; entry := NIL;
  WHILE content # NIL DO
    IF content.element # NIL THEN INC(count); entry := ReadEntry(content.element, TRUE)
    ELSIF ~White(content.text) THEN RETURN IQ.ErrorReply(request, "modify", "bad-request")
    END;
    content := content.next
  END;
  IF (count # 1) OR (entry = NIL) THEN RETURN IQ.ErrorReply(request, "modify", "bad-request") END;
  slot := 0;
  WHILE (slot < r.snapshot.count) & ~S.Equal(r.snapshot.entries[slot].jid^, entry.jid^) DO INC(slot) END;
  units := r.snapshot.units;
  IF slot < r.snapshot.count THEN DEC(units, r.snapshot.entries[slot].units) END;
  IF entry.subscription # remove THEN
    INC(units, entry.units);
    IF (units > maxRosterUnits) OR ((slot = r.snapshot.count) & (slot = maxItems)) THEN
      RETURN IQ.ErrorReply(request, "wait", "resource-constraint")
    END
  END;
  NEW(next); next.entries := r.snapshot.entries; next.count := r.snapshot.count; next.units := units;
  IF entry.subscription = remove THEN
    IF slot < next.count THEN
      DEC(next.count); FOR i := slot TO next.count-1 DO next.entries[i] := next.entries[i+1] END;
      next.entries[next.count] := NIL
    END
  ELSE
    next.entries[slot] := entry; IF slot = next.count THEN INC(next.count) END
  END;
  r.snapshot := next; IF r.fetch # NIL THEN r.fetch.dirty := TRUE END;
  r.hook.Changed(r, entry); RETURN IQ.Response(request, NIL)
END Handle;

PROCEDURE New*(router: IQ.Router; hook: Hook): Roster;
  VAR r: Roster;
BEGIN
  IF hook = NIL THEN RETURN NIL END;
  NEW(r); NEW(r.snapshot); r.router := router; r.hook := hook;
  IF ~router.Register(namespaceURI, "query", r) THEN RETURN NIL END;
  RETURN r
END New;

END XmppRoster.
