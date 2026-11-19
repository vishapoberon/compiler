MODULE XmppPubSub;

(* XEP-0060 payloads, correlated results and XEP-0163 personal notifications. *)

IMPORT Msg, S := LongStrings, IntStr, T := XmppTypes, Items := XmppItems,
  Core := XmppCore, IQ := XmppIQ, XML := XmppXmlGen, RSM := XmppRSM;

CONST
  namespaceURI* = "http://jabber.org/protocol/pubsub";
  eventURI* = "http://jabber.org/protocol/pubsub#event";
  maxItems* = 64; maxNodeUnits* = 1024; maxIDUnits* = 1024;
  maxPayloadBytes* = 65536;
  published* = 1; retracted* = 2; purged* = 3; deleted* = 4;
  subscriptionNone* = 0; subscriptionPending* = 1;
  subscriptionUnconfigured* = 2; subscriptionSubscribed* = 3;

TYPE
  Update* = RECORD kind-: SHORTINT; id-: T.String; payload-: Items.Item END;
  Event* = POINTER TO EventDesc;
  EventDesc* = RECORD
    publisher-, node-: T.String;
    kind-: SHORTINT;
    count-: LONGINT;
    updates-: ARRAY maxItems OF Update;
  END;
  Subscription* = POINTER TO RECORD
    node*, jid*, id*: T.String;
    state*: SHORTINT;
    configurationRequired*: BOOLEAN;
  END;
  Page* = POINTER TO RECORD
    items*: Items.Item;
    size*: LONGINT;
    info*: RSM.Result;
  END;

PROCEDURE Value(text: ARRAY OF T.CodeUnit; maximum: LONGINT): BOOLEAN;
BEGIN RETURN (text[0] # 0) & IQ.Value(text, maximum) END Value;

PROCEDURE White(text: T.String): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  FOR i := 0 TO S.Length(text^)-1 DO
    IF (text[i] # 32) & (text[i] # 9) & (text[i] # 10) & (text[i] # 13) THEN RETURN FALSE END
  END;
  RETURN TRUE
END White;

PROCEDURE Single(parent: Items.Item; VAR child: Items.Item): BOOLEAN;
  VAR content: Items.Content; count: LONGINT;
BEGIN
  child := NIL; count := 0; content := parent.content;
  WHILE content # NIL DO
    IF content.element # NIL THEN INC(count); child := content.element
    ELSIF ~White(content.text) THEN RETURN FALSE
    END;
    content := content.next
  END;
  RETURN count = 1
END Single;

PROCEDURE Operation(name: ARRAY OF CHAR; node: ARRAY OF T.CodeUnit; VAR operation: Items.Item): Items.Item;
  VAR pubsub: Items.Item;
BEGIN
  pubsub := Items.New("pubsub", namespaceURI); operation := Items.New(name, namespaceURI);
  operation.SetParam("node", node); pubsub.AddChild(operation); RETURN pubsub
END Operation;

PROCEDURE BuildPublish*(node, id: ARRAY OF T.CodeUnit; payload: Items.Item): Items.Item;
  VAR pubsub, publish, item: Items.Item; bytes: Items.Bytes; length: LONGINT; error: Msg.Msg;
BEGIN
  IF ~Value(node, maxNodeUnits) OR ~Value(id, maxIDUnits) OR (payload = NIL) OR (payload.parent # NIL) THEN RETURN NIL END;
  XML.Encode(payload, maxPayloadBytes, bytes, length, error); IF error # NIL THEN RETURN NIL END;
  pubsub := Operation("publish", node, publish); item := Items.New("item", namespaceURI);
  item.SetParam("id", id); item.AddChild(payload); publish.AddChild(item); RETURN pubsub
END BuildPublish;

PROCEDURE BuildItems*(node, id: ARRAY OF T.CodeUnit; maximum: LONGINT): Items.Item;
  VAR pubsub, items, item: Items.Item; number: ARRAY 16 OF CHAR; value: T.String;
BEGIN
  IF ~Value(node, maxNodeUnits) OR ~IQ.Value(id, maxIDUnits) OR (maximum < 1) OR (maximum > maxItems) THEN RETURN NIL END;
  pubsub := Operation("items", node, items); IntStr.IntToStr(maximum, number);
  value := Items.Latin1(number); items.SetParam("max_items", value^);
  IF id[0] # 0 THEN item := Items.New("item", namespaceURI); item.SetParam("id", id); items.AddChild(item) END;
  RETURN pubsub
END BuildItems;

PROCEDURE BuildPage*(node, cursor: ARRAY OF T.CodeUnit; direction, maximum: LONGINT): Items.Item;
  VAR pubsub, items, set: Items.Item;
BEGIN
  IF ~Value(node, maxNodeUnits) OR (maximum < 0) OR (maximum > maxItems) THEN RETURN NIL END;
  set := RSM.Build(direction, maximum, cursor); IF set = NIL THEN RETURN NIL END;
  pubsub := Operation("items", node, items); pubsub.AddChild(set); RETURN pubsub
END BuildPage;

PROCEDURE BuildRetract*(node, id: ARRAY OF T.CodeUnit; notify: BOOLEAN): Items.Item;
  VAR pubsub, retract, item: Items.Item; value: T.String;
BEGIN
  IF ~Value(node, maxNodeUnits) OR ~Value(id, maxIDUnits) THEN RETURN NIL END;
  pubsub := Operation("retract", node, retract); item := Items.New("item", namespaceURI);
  item.SetParam("id", id); retract.AddChild(item);
  IF notify THEN value := Items.Latin1("1"); retract.SetParam("notify", value^) END;
  RETURN pubsub
END BuildRetract;

PROCEDURE BuildSubscribe*(node, jid: ARRAY OF T.CodeUnit): Items.Item;
  VAR pubsub, subscribe: Items.Item; canonical: T.String;
BEGIN
  IF ~Value(node, maxNodeUnits) THEN RETURN NIL END;
  canonical := IQ.CanonicalJID(jid); IF canonical = NIL THEN RETURN NIL END;
  pubsub := Operation("subscribe", node, subscribe);
  subscribe.SetParam("jid", canonical^); RETURN pubsub
END BuildSubscribe;

PROCEDURE BuildUnsubscribe*(node, jid, id: ARRAY OF T.CodeUnit): Items.Item;
  VAR pubsub, unsubscribe: Items.Item; canonical: T.String;
BEGIN
  IF ~Value(node, maxNodeUnits) OR ~IQ.Value(id, maxIDUnits) THEN RETURN NIL END;
  canonical := IQ.CanonicalJID(jid); IF canonical = NIL THEN RETURN NIL END;
  pubsub := Operation("unsubscribe", node, unsubscribe);
  unsubscribe.SetParam("jid", canonical^);
  IF id[0] # 0 THEN unsubscribe.SetParam("subid", id) END;
  RETURN pubsub
END BuildUnsubscribe;

PROCEDURE Publish*(router: IQ.Router; peer, node, id: ARRAY OF T.CodeUnit; payload: Items.Item;
                   timeoutMS: LONGINT; action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
BEGIN RETURN router.Query(peer, BuildPublish(node, id, payload), TRUE, timeoutMS, action, error) END Publish;

PROCEDURE Fetch*(router: IQ.Router; peer, node, id: ARRAY OF T.CodeUnit; maximum, timeoutMS: LONGINT;
                 action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
BEGIN RETURN router.Query(peer, BuildItems(node, id, maximum), FALSE, timeoutMS, action, error) END Fetch;

PROCEDURE FetchPage*(router: IQ.Router; peer, node, cursor: ARRAY OF T.CodeUnit;
                     direction, maximum, timeoutMS: LONGINT; action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
BEGIN RETURN router.Query(peer, BuildPage(node, cursor, direction, maximum), FALSE, timeoutMS, action, error) END FetchPage;

PROCEDURE Retract*(router: IQ.Router; peer, node, id: ARRAY OF T.CodeUnit; notify: BOOLEAN;
                   timeoutMS: LONGINT; action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
BEGIN RETURN router.Query(peer, BuildRetract(node, id, notify), TRUE, timeoutMS, action, error) END Retract;

PROCEDURE Subscribe*(router: IQ.Router; peer, node, jid: ARRAY OF T.CodeUnit;
                     timeoutMS: LONGINT; action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
BEGIN RETURN router.Query(peer, BuildSubscribe(node, jid), TRUE, timeoutMS, action, error) END Subscribe;

PROCEDURE Unsubscribe*(router: IQ.Router; peer, node, jid, id: ARRAY OF T.CodeUnit;
                       timeoutMS: LONGINT; action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
BEGIN RETURN router.Query(peer, BuildUnsubscribe(node, jid, id), TRUE, timeoutMS, action, error) END Unsubscribe;

PROCEDURE Expected(request: IQ.Request; name: ARRAY OF CHAR): Items.Item;
  VAR child: Items.Item;
BEGIN
  IF (request = NIL) OR ~IQ.Named(request.payload, namespaceURI, "pubsub") OR
     ~Single(request.payload, child) OR ~IQ.Named(child, namespaceURI, name) THEN RETURN NIL END;
  RETURN child
END Expected;

PROCEDURE SameNode(item, expected: Items.Item): BOOLEAN;
  VAR a, b: T.String;
BEGIN
  a := item.GetAttribute("", "node"); b := expected.GetAttribute("", "node");
  RETURN (a # NIL) & (b # NIL) & Value(a^, maxNodeUnits) & S.Equal(a^, b^)
END SameNode;

PROCEDURE Published*(request: IQ.Request): BOOLEAN;
  VAR expected, pubsub, publish, item, sent: Items.Item; id, sentID: T.String;
BEGIN
  expected := Expected(request, "publish"); IF expected = NIL THEN RETURN FALSE END;
  IF IQ.EmptyResult(request) THEN RETURN TRUE END;
  pubsub := IQ.Payload(request, namespaceURI, "pubsub");
  IF (pubsub = NIL) OR ~Single(pubsub, publish) OR ~IQ.Named(publish, namespaceURI, "publish") OR
     ~SameNode(publish, expected) OR ~Single(publish, item) OR ~IQ.Named(item, namespaceURI, "item") OR
     ~IQ.Empty(item) OR ~Single(expected, sent) THEN RETURN FALSE END;
  id := item.GetAttribute("", "id"); sentID := sent.GetAttribute("", "id");
  RETURN (id # NIL) & (sentID # NIL) & S.Equal(id^, sentID^)
END Published;

PROCEDURE Retracted*(request: IQ.Request): BOOLEAN;
BEGIN RETURN (Expected(request, "retract") # NIL) & IQ.EmptyResult(request) END Retracted;

PROCEDURE ReadSubscription*(request: IQ.Request): Subscription;
  VAR expected, pubsub, subscription, options, required: Items.Item;
    wanted, jid, value: T.String; result: Subscription;
BEGIN
  expected := Expected(request, "subscribe"); IF expected = NIL THEN RETURN NIL END;
  pubsub := IQ.Payload(request, namespaceURI, "pubsub");
  IF (pubsub = NIL) OR ~Single(pubsub, subscription) OR
     ~IQ.Named(subscription, namespaceURI, "subscription") OR ~SameNode(subscription, expected) THEN RETURN NIL END;
  wanted := expected.GetAttribute("", "jid"); value := subscription.GetAttribute("", "jid");
  IF (wanted = NIL) OR (value = NIL) THEN RETURN NIL END;
  wanted := IQ.CanonicalJID(wanted^); jid := IQ.CanonicalJID(value^);
  IF (wanted = NIL) OR (jid = NIL) OR ~S.Equal(wanted^, jid^) THEN RETURN NIL END;
  value := subscription.GetAttribute("", "subscription"); IF value = NIL THEN RETURN NIL END;
  NEW(result);
  IF S.Equal8(value^, "none") THEN result.state := subscriptionNone
  ELSIF S.Equal8(value^, "pending") THEN result.state := subscriptionPending
  ELSIF S.Equal8(value^, "unconfigured") THEN result.state := subscriptionUnconfigured
  ELSIF S.Equal8(value^, "subscribed") THEN result.state := subscriptionSubscribed
  ELSE RETURN NIL
  END;
  result.node := subscription.GetAttribute("", "node"); result.jid := jid;
  result.id := subscription.GetAttribute("", "subid");
  IF result.id = NIL THEN result.id := Items.Latin1("")
  ELSIF ~Value(result.id^, maxIDUnits) THEN RETURN NIL
  END;
  result.configurationRequired := result.state = subscriptionUnconfigured;
  IF ~IQ.Empty(subscription) THEN
    IF ~Single(subscription, options) OR ~IQ.Named(options, namespaceURI, "subscribe-options") OR
       ~Single(options, required) OR ~IQ.Named(required, namespaceURI, "required") OR
       ~IQ.Empty(required) THEN RETURN NIL END;
    result.configurationRequired := TRUE
  END;
  RETURN result
END ReadSubscription;

PROCEDURE Unsubscribed*(request: IQ.Request): BOOLEAN;
BEGIN RETURN (Expected(request, "unsubscribe") # NIL) & IQ.EmptyResult(request) END Unsubscribed;

PROCEDURE ValidItems(items: Items.Item; event: BOOLEAN; limit: LONGINT; expectedID: T.String; out: Event): BOOLEAN;
  VAR content: Items.Content; item, payload: Items.Item; id: T.String; kind: SHORTINT;
    count, i, length, total: LONGINT; ids: ARRAY maxItems OF T.String; bytes: Items.Bytes; error: Msg.Msg;
BEGIN
  count := 0; total := 0; content := items.content;
  WHILE content # NIL DO
    IF content.element # NIL THEN
      item := content.element;
      IF count = limit THEN RETURN FALSE END;
      IF event THEN
        IF IQ.Named(item, eventURI, "item") THEN kind := published
        ELSIF IQ.Named(item, eventURI, "retract") THEN kind := retracted
        ELSE RETURN FALSE
        END
      ELSE
        IF ~IQ.Named(item, namespaceURI, "item") THEN RETURN FALSE END;
        kind := published
      END;
      id := item.GetAttribute("", "id"); IF (id = NIL) OR ~Value(id^, maxIDUnits) THEN RETURN FALSE END;
      IF (expectedID # NIL) & (expectedID[0] # 0) & ~S.Equal(id^, expectedID^) THEN RETURN FALSE END;
      FOR i := 0 TO count-1 DO IF S.Equal(ids[i]^, id^) THEN RETURN FALSE END END;
      IF kind = published THEN
        payload := NIL;
        IF ~IQ.Empty(item) THEN
          IF ~Single(item, payload) THEN RETURN FALSE END;
          XML.Encode(payload, maxPayloadBytes, bytes, length, error);
          IF error # NIL THEN RETURN FALSE END;
          INC(total, length); IF total > maxPayloadBytes THEN RETURN FALSE END
        END
      ELSE
        IF ~IQ.Empty(item) THEN RETURN FALSE END; payload := NIL
      END;
      ids[count] := id;
      IF out # NIL THEN out.updates[count].kind := kind; out.updates[count].id := id; out.updates[count].payload := payload END;
      INC(count)
    ELSIF ~White(content.text) THEN RETURN FALSE
    END;
    content := content.next
  END;
  IF out # NIL THEN out.count := count END;
  RETURN TRUE
END ValidItems;

PROCEDURE ItemParts(pubsub: Items.Item; VAR items, set: Items.Item): BOOLEAN;
  VAR content: Items.Content; child: Items.Item;
BEGIN
  items := NIL; set := NIL;
  IF ~IQ.Named(pubsub, namespaceURI, "pubsub") THEN RETURN FALSE END;
  content := pubsub.content;
  WHILE content # NIL DO
    child := content.element;
    IF child # NIL THEN
      IF IQ.Named(child, namespaceURI, "items") THEN
        IF items # NIL THEN RETURN FALSE END; items := child
      ELSIF IQ.Named(child, RSM.namespaceURI, "set") THEN
        IF set # NIL THEN RETURN FALSE END; set := child
      ELSE RETURN FALSE
      END
    ELSIF ~White(content.text) THEN RETURN FALSE
    END;
    content := content.next
  END;
  RETURN TRUE
END ItemParts;

PROCEDURE PageData(items, set: Items.Item; limit: LONGINT): Page;
  VAR page: Page; content: Items.Content; first, last: T.String;
BEGIN
  IF (items = NIL) OR (set = NIL) OR ~ValidItems(items, FALSE, limit, NIL, NIL) THEN RETURN NIL END;
  NEW(page); IF ~RSM.ReadResult(set, page.info) THEN RETURN NIL END;
  page.items := items; page.size := 0; first := NIL; last := NIL; content := items.content;
  WHILE content # NIL DO
    IF content.element # NIL THEN
      last := content.element.GetAttribute("", "id"); IF first = NIL THEN first := last END;
      INC(page.size)
    END;
    content := content.next
  END;
  IF page.size = 0 THEN
    IF (page.info.first # NIL) OR (page.info.last # NIL) THEN RETURN NIL END
  ELSE
    IF (page.info.first = NIL) OR (page.info.last = NIL) OR
       ~S.Equal(page.info.first^, first^) OR ~S.Equal(page.info.last^, last^) THEN RETURN NIL END
  END;
  IF page.info.hasCount THEN
    IF page.size > page.info.count THEN RETURN NIL END;
    IF page.info.hasIndex & (page.size > page.info.count-page.info.index) THEN RETURN NIL END
  END;
  RETURN page
END PageData;

PROCEDURE ReadPage*(request: IQ.Request): Page;
  VAR expected, asked, pubsub, items, set: Items.Item; selection: RSM.Request;
    page: Page; content: Items.Content; id, node: T.String; limit: LONGINT;
BEGIN
  IF (request = NIL) OR ~ItemParts(request.payload, expected, asked) OR
     (expected = NIL) OR (asked = NIL) OR ~IQ.Empty(expected) OR
     ~RSM.ReadRequest(asked, selection) THEN RETURN NIL END;
  node := expected.GetAttribute("", "node"); IF (node = NIL) OR ~Value(node^, maxNodeUnits) THEN RETURN NIL END;
  limit := selection.maximum; IF limit = -1 THEN limit := maxItems END;
  IF (limit < 0) OR (limit > maxItems) THEN RETURN NIL END;
  pubsub := IQ.Payload(request, namespaceURI, "pubsub");
  IF ~ItemParts(pubsub, items, set) OR (set = NIL) THEN RETURN NIL END;
  IF items = NIL THEN
    items := Items.New("items", namespaceURI); items.SetParam("node", node^)
  ELSIF ~SameNode(items, expected) THEN RETURN NIL
  END;
  page := PageData(items, set, limit); IF page = NIL THEN RETURN NIL END;
  IF (selection.direction = RSM.indexedPage) & page.info.hasIndex &
     (selection.index # page.info.index) THEN RETURN NIL END;
  IF (selection.direction = RSM.afterPage) OR
     ((selection.direction = RSM.beforePage) & (selection.cursor[0] # 0)) THEN
    content := items.content;
    WHILE content # NIL DO
      IF content.element # NIL THEN
        id := content.element.GetAttribute("", "id");
        IF S.Equal(id^, selection.cursor^) THEN RETURN NIL END
      END;
      content := content.next
    END
  END;
  RETURN page
END ReadPage;

PROCEDURE ReadItems*(request: IQ.Request): Items.Item;
  VAR expected, pubsub, items, sent, set: Items.Item; id, number: T.String; limit, i: LONGINT; page: Page;
BEGIN
  expected := Expected(request, "items");
  IF expected = NIL THEN
    page := ReadPage(request); IF page # NIL THEN RETURN page.items END;
    RETURN NIL
  END;
  pubsub := IQ.Payload(request, namespaceURI, "pubsub");
  IF ~ItemParts(pubsub, items, set) OR (items = NIL) OR
     ~SameNode(items, expected) THEN RETURN NIL END;
  limit := maxItems; number := expected.GetAttribute("", "max_items");
  IF number # NIL THEN
    limit := 0;
    FOR i := 0 TO S.Length(number^)-1 DO
      IF (number[i] < ORD("0")) OR (number[i] > ORD("9")) OR (limit > maxItems) THEN RETURN NIL END;
      limit := 10*limit+number[i]-ORD("0")
    END;
    IF (limit < 1) OR (limit > maxItems) THEN RETURN NIL END
  END;
  id := NIL;
  IF Single(expected, sent) THEN id := sent.GetAttribute("", "id"); limit := 1 END;
  IF ~ValidItems(items, FALSE, limit, id, NIL) THEN RETURN NIL END;
  IF (set # NIL) & (PageData(items, set, limit) = NIL) THEN RETURN NIL END;
  RETURN items
END ReadItems;

PROCEDURE Bare(text: ARRAY OF T.CodeUnit): T.String;
  VAR jid: T.String; i: LONGINT;
BEGIN
  jid := IQ.CanonicalJID(text); IF jid = NIL THEN RETURN NIL END;
  FOR i := 0 TO S.Length(jid^)-1 DO IF jid[i] = ORD("/") THEN RETURN NIL END END;
  RETURN jid
END Bare;

PROCEDURE ReadEvent*(stanza: Core.Stanza; publisher, node: ARRAY OF T.CodeUnit): Event;
  VAR expected, sender, value: T.String; event, operation: Items.Item; content: Items.Content;
    count: LONGINT; result: Event;
BEGIN
  IF (stanza = NIL) OR (stanza.kind # Core.message) OR ~Value(node, maxNodeUnits) OR
     ~((stanza.type[0] = 0) OR S.Equal8(stanza.type^, "headline") OR S.Equal8(stanza.type^, "normal")) THEN RETURN NIL END;
  IF (stanza.type[0] = 0) & (stanza.item.GetAttribute("", "type") # NIL) THEN RETURN NIL END;
  expected := Bare(publisher); sender := Bare(stanza.from^);
  IF (expected = NIL) OR (sender = NIL) OR ~S.Equal(expected^, sender^) THEN RETURN NIL END;
  count := 0; event := NIL; content := stanza.item.content;
  WHILE content # NIL DO
    IF (content.element # NIL) & (content.element.namespaceURI^ = eventURI) THEN
      IF ~IQ.Named(content.element, eventURI, "event") THEN RETURN NIL END;
      INC(count); event := content.element
    END;
    content := content.next
  END;
  IF (count # 1) OR ~Single(event, operation) THEN RETURN NIL END;
  value := operation.GetAttribute("", "node"); IF (value = NIL) OR ~S.Equal(value^, node) THEN RETURN NIL END;
  NEW(result); result.publisher := sender; result.node := value;
  IF IQ.Named(operation, eventURI, "items") THEN
    result.kind := published;
    IF ~ValidItems(operation, TRUE, maxItems, NIL, result) OR (result.count = 0) THEN RETURN NIL END
  ELSIF IQ.Named(operation, eventURI, "purge") & IQ.Empty(operation) THEN result.kind := purged
  ELSIF IQ.Named(operation, eventURI, "delete") & IQ.Empty(operation) THEN result.kind := deleted
  ELSE RETURN NIL
  END;
  RETURN result
END ReadEvent;

END XmppPubSub.
