MODULE XmppDisco;

(* XEP-0030 discovery of a configured entity's identity, features and items. *)

IMPORT Msg, S := LongStrings, T := XmppTypes, Items := XmppItems, Core := XmppCore, IQ := XmppIQ;

CONST
  infoURI* = "http://jabber.org/protocol/disco#info";
  itemsURI* = "http://jabber.org/protocol/disco#items";
  info* = 1; items* = 2; maxEntries* = 64;
TYPE
  Entry = RECORD jid, node, name: T.String END;
  Disco* = POINTER TO DiscoDesc;
  DiscoDesc* = RECORD (IQ.HandlerDesc)
    category, type, name: T.String;
    features: ARRAY maxEntries OF T.String;
    entries: ARRAY maxEntries OF Entry;
    featureCount, itemCount: LONGINT;
  END;

PROCEDURE (d: Disco) AddFeature*(uri: ARRAY OF CHAR): BOOLEAN;
  VAR value: T.String; i: LONGINT;
BEGIN
  IF (d.featureCount = maxEntries) OR (S.Length8(uri) = 0) OR (S.Length8(uri) > 1024) THEN RETURN FALSE END;
  value := Items.UTF8(uri); IF value = NIL THEN RETURN FALSE END;
  FOR i := 0 TO d.featureCount-1 DO IF S.Equal(d.features[i]^, value^) THEN RETURN FALSE END END;
  d.features[d.featureCount] := value; INC(d.featureCount); RETURN TRUE
END AddFeature;

PROCEDURE (d: Disco) AddItem*(jid, node, name: ARRAY OF T.CodeUnit): BOOLEAN;
  VAR canonical: T.String; i: LONGINT;
BEGIN
  IF (d.itemCount = maxEntries) OR ~IQ.Value(node, 1024) OR ~IQ.Value(name, 1024) THEN RETURN FALSE END;
  canonical := IQ.CanonicalJID(jid); IF canonical = NIL THEN RETURN FALSE END;
  FOR i := 0 TO d.itemCount-1 DO
    IF S.Equal(d.entries[i].jid^, canonical^) & S.Equal(d.entries[i].node^, node) THEN RETURN FALSE END
  END;
  d.entries[d.itemCount].jid := canonical; d.entries[d.itemCount].node := Items.Copy16(node);
  d.entries[d.itemCount].name := Items.Copy16(name); INC(d.itemCount); RETURN TRUE
END AddItem;

PROCEDURE (d: Disco) Handle*(router: IQ.Router; request: Core.Stanza; payload: Items.Item): Core.Stanza;
  VAR query, entry: Items.Item; node: T.String; i: LONGINT;
BEGIN
  IF ~S.Equal8(request.type^, "get") OR ~IQ.Empty(payload) THEN RETURN IQ.ErrorReply(request, "modify", "bad-request") END;
  node := payload.GetAttribute("", "node");
  IF (node # NIL) & (node[0] # 0) THEN RETURN IQ.ErrorReply(request, "cancel", "item-not-found") END;
  IF payload.namespaceURI^ = infoURI THEN
    query := Items.New("query", infoURI); entry := Items.New("identity", infoURI);
    entry.SetParam("category", d.category^); entry.SetParam("type", d.type^);
    IF d.name[0] # 0 THEN entry.SetParam("name", d.name^) END;
    query.AddChild(entry);
    FOR i := 0 TO d.featureCount-1 DO
      entry := Items.New("feature", infoURI); entry.SetParam("var", d.features[i]^); query.AddChild(entry)
    END
  ELSE
    query := Items.New("query", itemsURI);
    FOR i := 0 TO d.itemCount-1 DO
      entry := Items.New("item", itemsURI); entry.SetParam("jid", d.entries[i].jid^);
      IF d.entries[i].node[0] # 0 THEN entry.SetParam("node", d.entries[i].node^) END;
      IF d.entries[i].name[0] # 0 THEN entry.SetParam("name", d.entries[i].name^) END;
      query.AddChild(entry)
    END
  END;
  IF node # NIL THEN query.SetParam("node", node^) END;
  RETURN IQ.Response(request, query)
END Handle;

PROCEDURE Query*(router: IQ.Router; to, node: ARRAY OF T.CodeUnit; kind: SHORTINT;
                  timeoutMS: LONGINT; action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
  VAR query: Items.Item;
BEGIN
  ASSERT((kind = info) OR (kind = items)); ASSERT(IQ.Value(node, 1024));
  IF kind = info THEN query := Items.New("query", infoURI) ELSE query := Items.New("query", itemsURI) END;
  IF node[0] # 0 THEN query.SetParam("node", node) END;
  RETURN router.Query(to, query, FALSE, timeoutMS, action, error)
END Query;

PROCEDURE Read*(request: IQ.Request): Items.Item;
  VAR query: Items.Item; node, expected: T.String;
BEGIN
  IF (request = NIL) OR (request.payload = NIL) THEN RETURN NIL END;
  query := IQ.Payload(request, request.payload.namespaceURI^, "query");
  IF (query = NIL) OR ((query.namespaceURI^ # infoURI) & (query.namespaceURI^ # itemsURI)) THEN RETURN NIL END;
  node := query.GetAttribute("", "node"); expected := request.payload.GetAttribute("", "node");
  IF expected = NIL THEN
    IF (node # NIL) & (node[0] # 0) THEN RETURN NIL END
  ELSIF (node = NIL) OR ~S.Equal(node^, expected^) THEN RETURN NIL
  END;
  RETURN query
END Read;

PROCEDURE New*(router: IQ.Router; category, type, name: ARRAY OF T.CodeUnit): Disco;
  VAR d: Disco; added: BOOLEAN;
BEGIN
  IF (category[0] = 0) OR (type[0] = 0) OR ~IQ.Value(category, 256) OR ~IQ.Value(type, 256) OR ~IQ.Value(name, 256) THEN RETURN NIL END;
  NEW(d); d.category := Items.Copy16(category); d.type := Items.Copy16(type); d.name := Items.Copy16(name);
  IF ~router.Register(infoURI, "query", d) OR ~router.Register(itemsURI, "query", d) THEN
    added := router.Unregister(d); RETURN NIL
  END;
  added := d.AddFeature(infoURI); added := d.AddFeature(itemsURI); RETURN d
END New;

END XmppDisco.
