MODULE XmppIQ;

(* Bounded IQ routing and request correlation for an authenticated client.
   A router is the client's hook and forwards unhandled events to its owner. *)

IMPORT Msg, S := LongStrings, IntStr, IDNA, T := XmppTypes, Items := XmppItems,
  Core := XmppCore, Client := XmppClient, J := XmppStrings, Const := XmppConst;

CONST
  maxPending* = 32; maxHandlers* = 16; maxIDUnits* = 128;
  maxJIDUnits* = 3071; maxTimeoutMS* = 3600000;
  pending* = 0; result* = 1; stanzaError* = 2; timedOut* = 3;
  cancelled* = 4; sendFailed* = 5; malformed* = 6;
  invalidRequest* = 1; queueFull* = 2; offline* = 3;

TYPE
  Router* = POINTER TO RouterDesc;
  Request* = POINTER TO RequestDesc;
  Action* = POINTER TO ActionDesc;
  Handler* = POINTER TO HandlerDesc;
  ActionDesc* = RECORD END;
  HandlerDesc* = RECORD END;
  RequestDesc* = RECORD
    id-, peer-: T.String;
    status-: SHORTINT;
    reply-: Core.Stanza;
    payload-: Items.Item;
    remaining: LONGINT;
    action: Action;
  END;
  Route = RECORD uri, name: Items.Bytes; handler: Handler END;
  RouterDesc* = RECORD (Client.HookDesc)
    client-: Client.Client;
    count-: LONGINT;
    hook: Client.Hook;
    active: BOOLEAN;
    full, bare, domain: T.String;
    serial, routes: LONGINT;
    handlers: ARRAY maxHandlers OF Route;
    requests: ARRAY maxPending OF Request;
  END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR text: Msg.LString);
BEGIN
  CASE message.code OF
  | invalidRequest: S.Long("Invalid bounded XMPP IQ request", text)
  | queueFull: S.Long("XMPP IQ pending-request limit exceeded", text)
  ELSE S.Long("XMPP IQ router is not online", text)
  END
END GetTemplate;

PROCEDURE Named*(item: Items.Item; uri, name: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN (item # NIL) & (item.namespaceURI^ = uri) & S.Equal8(item.name^, name) END Named;

PROCEDURE Value*(text: ARRAY OF T.CodeUnit; maximum: LONGINT): BOOLEAN;
  VAR bytes: Items.Bytes; i: LONGINT;
BEGIN
  IF S.Length(text) > maximum THEN RETURN FALSE END;
  FOR i := 0 TO S.Length(text)-1 DO
    IF ((text[i] < 32) & (text[i] # 9) & (text[i] # 10) & (text[i] # 13)) OR
       (text[i] = 0FFFEH) OR (text[i] = 0FFFFH) THEN RETURN FALSE END
  END;
  bytes := Items.UTF8Bytes(text); RETURN bytes # NIL
END Value;

PROCEDURE CanonicalJID*(text: ARRAY OF T.CodeUnit): T.String;
  VAR user, domain, resource, joined: ARRAY maxJIDUnits+1 OF T.CodeUnit;
    bytes: Items.Bytes; unicode, ascii: IDNA.String; units: T.String; status: LONGINT;
BEGIN
  IF (S.Length(text) > maxJIDUnits) OR ~J.JidCorrect(text) THEN RETURN NIL END;
  user[0] := 0; J.UsernameFromJid(text, user, status);
  J.ServerFromJid(text, domain, status); IF status # 0 THEN RETURN NIL END;
  J.ResourceFromJid(text, resource);
  bytes := Items.UTF8Bytes(user); IF (bytes = NIL) OR (S.Length8(bytes^) > 1023) THEN RETURN NIL END;
  bytes := Items.UTF8Bytes(resource); IF (bytes = NIL) OR (S.Length8(bytes^) > 1023) THEN RETURN NIL END;
  bytes := Items.UTF8Bytes(domain); IF bytes = NIL THEN RETURN NIL END;
  IDNA.Names(bytes^, unicode, ascii, status); IF status # 0 THEN RETURN NIL END;
  units := Items.UTF8(unicode^);
  IF (units = NIL) OR ~J.Jid(user, units^, resource, joined) THEN RETURN NIL END;
  RETURN Items.Copy16(joined)
END CanonicalJID;

PROCEDURE Bare(jid: T.String): T.String;
  VAR text: ARRAY maxJIDUnits+1 OF T.CodeUnit;
BEGIN J.GetShortJidFromFullJid(jid^, text); RETURN Items.Copy16(text) END Bare;

PROCEDURE Empty*(item: Items.Item): BOOLEAN;
  VAR content: Items.Content; i: LONGINT;
BEGIN
  content := item.content;
  WHILE content # NIL DO
    IF content.element # NIL THEN RETURN FALSE END;
    FOR i := 0 TO S.Length(content.text^)-1 DO
      IF (content.text[i] # 32) & (content.text[i] # 9) & (content.text[i] # 10) & (content.text[i] # 13) THEN RETURN FALSE END
    END;
    content := content.next
  END;
  RETURN TRUE
END Empty;

PROCEDURE Children(stanza: Core.Stanza; VAR payload: Items.Item; VAR errors: LONGINT): LONGINT;
  VAR content: Items.Content; count, i: LONGINT;
BEGIN
  count := 0; errors := 0; payload := NIL; content := stanza.item.content;
  WHILE content # NIL DO
    IF content.element # NIL THEN
      IF Named(content.element, Const.jabberClient, "error") THEN INC(errors)
      ELSE INC(count); payload := content.element
      END
    ELSE
      FOR i := 0 TO S.Length(content.text^)-1 DO
        IF (content.text[i] # 32) & (content.text[i] # 9) & (content.text[i] # 10) & (content.text[i] # 13) THEN RETURN -1 END
      END
    END;
    content := content.next
  END;
  RETURN count
END Children;

PROCEDURE ValidError(stanza: Core.Stanza): BOOLEAN;
  VAR item: Items.Item; content: Items.Content; type: T.String; conditions, texts: LONGINT;
BEGIN
  item := stanza.item.First(Const.jabberClient, "error");
  IF item = NIL THEN RETURN FALSE END;
  type := item.GetAttribute("", "type");
  IF (type = NIL) OR ~(S.Equal8(type^, "auth") OR S.Equal8(type^, "cancel") OR
     S.Equal8(type^, "continue") OR S.Equal8(type^, "modify") OR S.Equal8(type^, "wait")) THEN RETURN FALSE END;
  content := item.content; conditions := 0; texts := 0;
  WHILE content # NIL DO
    IF content.element # NIL THEN
      IF content.element.namespaceURI^ = Const.uriStanzas THEN
        IF S.Equal8(content.element.name^, "text") THEN INC(texts)
        ELSE INC(conditions); IF ~Empty(content.element) THEN RETURN FALSE END
        END
      END
    END;
    content := content.next
  END;
  RETURN (conditions = 1) & (texts <= 1)
END ValidError;

PROCEDURE Payload*(request: Request; uri, name: ARRAY OF CHAR): Items.Item;
  VAR payload: Items.Item; count, errors: LONGINT;
BEGIN
  IF (request = NIL) OR (request.status # result) OR (request.reply = NIL) THEN RETURN NIL END;
  count := Children(request.reply, payload, errors);
  IF (count = 1) & (errors = 0) & Named(payload, uri, name) THEN RETURN payload END;
  RETURN NIL
END Payload;

PROCEDURE EmptyResult*(request: Request): BOOLEAN;
  VAR payload: Items.Item; count, errors: LONGINT;
BEGIN
  IF (request = NIL) OR (request.status # result) OR (request.reply = NIL) THEN RETURN FALSE END;
  count := Children(request.reply, payload, errors); RETURN (count = 0) & (errors = 0)
END EmptyResult;

PROCEDURE Response*(request: Core.Stanza; payload: Items.Item): Core.Stanza;
  VAR item: Items.Item; text: T.String;
BEGIN
  item := Items.New("iq", Const.jabberClient); text := Items.Latin1("result"); item.SetParam("type", text^);
  item.SetParam("id", request.id^);
  IF request.from[0] # 0 THEN item.SetParam("to", request.from^) END;
  IF request.to[0] # 0 THEN item.SetParam("from", request.to^) END;
  IF payload # NIL THEN item.AddChild(payload) END;
  RETURN Core.Wrap(item, NIL)
END Response;

PROCEDURE ErrorReply*(request: Core.Stanza; type, condition: ARRAY OF CHAR): Core.Stanza;
  VAR response: Core.Stanza; item: Items.Item; text: T.String;
BEGIN
  response := Response(request, NIL); text := Items.Latin1("error"); response.item.SetParam("type", text^);
  item := Items.New("error", Const.jabberClient); text := Items.Latin1(type); item.SetParam("type", text^);
  item.AddChild(Items.New(condition, Const.uriStanzas)); response.item.AddChild(item);
  RETURN Core.Wrap(response.item, NIL)
END ErrorReply;

PROCEDURE (a: Action) Done*(router: Router; request: Request);
BEGIN END Done;

PROCEDURE (h: Handler) Handle*(router: Router; request: Core.Stanza; payload: Items.Item): Core.Stanza;
BEGIN RETURN ErrorReply(request, "cancel", "service-unavailable") END Handle;

PROCEDURE Finish(router: Router; slot: LONGINT; status: SHORTINT; reply: Core.Stanza);
  VAR request: Request;
BEGIN
  request := router.requests[slot]; router.requests[slot] := NIL; DEC(router.count);
  request.status := status; request.reply := reply; request.action.Done(router, request)
END Finish;

PROCEDURE Stop(router: Router; status: SHORTINT);
  VAR requests: ARRAY maxPending OF Request; i: LONGINT;
BEGIN
  router.active := FALSE; requests := router.requests; router.count := 0;
  FOR i := 0 TO maxPending-1 DO
    router.requests[i] := NIL;
    IF requests[i] # NIL THEN requests[i].status := status END
  END;
  FOR i := 0 TO maxPending-1 DO
    IF requests[i] # NIL THEN requests[i].action.Done(router, requests[i]) END
  END
END Stop;

PROCEDURE (router: Router) Stop*;
BEGIN Stop(router, cancelled) END Stop;

PROCEDURE (router: Router) Cancel*(request: Request): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  FOR i := 0 TO maxPending-1 DO
    IF (request # NIL) & (router.requests[i] = request) THEN Finish(router, i, cancelled, NIL); RETURN TRUE END
  END;
  RETURN FALSE
END Cancel;

PROCEDURE (router: Router) Tick*(elapsedMS: LONGINT);
  VAR requests: ARRAY maxPending OF Request; i: LONGINT; request: Request;
BEGIN
  ASSERT(elapsedMS >= 0); requests := router.requests;
  FOR i := 0 TO maxPending-1 DO
    request := requests[i];
    IF (request # NIL) & (router.requests[i] = request) THEN
      IF elapsedMS >= request.remaining THEN Finish(router, i, timedOut, NIL)
      ELSE DEC(request.remaining, elapsedMS)
      END
    END
  END
END Tick;

PROCEDURE (router: Router) Register*(uri, name: ARRAY OF CHAR; handler: Handler): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  IF (router.client # NIL) OR (handler = NIL) OR (router.routes = maxHandlers) OR
     (S.Length8(uri) = 0) OR (S.Length8(uri) > 1024) OR (S.Length8(name) = 0) OR (S.Length8(name) > 128) THEN RETURN FALSE END;
  FOR i := 0 TO router.routes-1 DO
    IF (router.handlers[i].uri^ = uri) & (router.handlers[i].name^ = name) THEN RETURN FALSE END
  END;
  router.handlers[router.routes].uri := Items.Copy8(uri); router.handlers[router.routes].name := Items.Copy8(name);
  router.handlers[router.routes].handler := handler; INC(router.routes); RETURN TRUE
END Register;

PROCEDURE (router: Router) Unregister*(handler: Handler): BOOLEAN;
  VAR i, count: LONGINT; removed: BOOLEAN;
BEGIN
  IF router.client # NIL THEN RETURN FALSE END;
  count := 0; removed := FALSE;
  FOR i := 0 TO router.routes-1 DO
    IF router.handlers[i].handler = handler THEN removed := TRUE
    ELSE router.handlers[count] := router.handlers[i]; INC(count)
    END
  END;
  FOR i := count TO router.routes-1 DO
    router.handlers[i].handler := NIL; router.handlers[i].uri := NIL; router.handlers[i].name := NIL
  END;
  router.routes := count; RETURN removed
END Unregister;

PROCEDURE (router: Router) Query*(peer: ARRAY OF T.CodeUnit; payload: Items.Item; set: BOOLEAN;
                                  timeoutMS: LONGINT; action: Action; VAR error: Msg.Msg): Request;
  VAR request: Request; stanza: Core.Stanza; item: Items.Item; text, target: T.String;
    number: ARRAY 24 OF CHAR; id: ARRAY 48 OF T.CodeUnit; slot: LONGINT;
BEGIN
  error := NIL;
  IF ~router.active OR (router.client.state # Client.online) THEN error := Msg.New(context, offline); RETURN NIL END;
  IF (payload = NIL) OR (payload.parent # NIL) OR (action = NIL) OR
     (timeoutMS <= 0) OR (timeoutMS > maxTimeoutMS) OR (router.serial = MAX(LONGINT)) THEN
    error := Msg.New(context, invalidRequest); RETURN NIL
  END;
  IF peer[0] = 0 THEN target := Items.Latin1("") ELSE target := CanonicalJID(peer) END;
  IF target = NIL THEN error := Msg.New(context, invalidRequest); RETURN NIL END;
  slot := 0; WHILE (slot < maxPending) & (router.requests[slot] # NIL) DO INC(slot) END;
  IF slot = maxPending THEN error := Msg.New(context, queueFull); RETURN NIL END;
  INC(router.serial); IntStr.IntToStr(router.serial, number); S.Long("voc-iq-", id); S.Append8(number, id);
  item := Items.New("iq", Const.jabberClient); item.SetParam("id", id);
  IF set THEN text := Items.Latin1("set") ELSE text := Items.Latin1("get") END;
  item.SetParam("type", text^); IF target[0] # 0 THEN item.SetParam("to", target^) END;
  item.AddChild(payload); stanza := Core.Wrap(item, NIL);
  NEW(request); request.id := Items.Copy16(id); request.peer := target;
  request.action := action; request.remaining := timeoutMS; request.payload := payload;
  router.requests[slot] := request; INC(router.count); router.client.Send(stanza, error);
  IF (error # NIL) & (router.requests[slot] = request) THEN Finish(router, slot, sendFailed, NIL) END;
  RETURN request
END Query;

PROCEDURE Addressed(router: Router; stanza: Core.Stanza): BOOLEAN;
  VAR to: T.String;
BEGIN
  IF stanza.to[0] = 0 THEN RETURN stanza.item.GetAttribute("", "to") = NIL END;
  to := CanonicalJID(stanza.to^);
  RETURN (to # NIL) & (S.Equal(to^, router.full^) OR S.Equal(to^, router.bare^))
END Addressed;

PROCEDURE Matches(router: Router; request: Request; stanza: Core.Stanza): BOOLEAN;
  VAR from, bare: T.String; user: ARRAY maxJIDUnits+1 OF T.CodeUnit; status: LONGINT;
BEGIN
  IF ~Addressed(router, stanza) THEN RETURN FALSE END;
  IF stanza.from[0] = 0 THEN
    RETURN (stanza.item.GetAttribute("", "from") = NIL) &
      ((request.peer[0] = 0) OR S.Equal(request.peer^, router.domain^) OR S.Equal(request.peer^, router.bare^))
  END;
  from := CanonicalJID(stanza.from^); IF from = NIL THEN RETURN FALSE END;
  IF request.peer[0] = 0 THEN
    RETURN S.Equal(from^, router.domain^) OR S.Equal(from^, router.bare^) OR S.Equal(from^, router.full^)
  END;
  IF S.Equal(from^, request.peer^) THEN RETURN TRUE END;
  bare := Bare(from);
  (* A request to a bare account can be answered by one of that account's resources. *)
  J.UsernameFromJid(request.peer^, user, status);
  RETURN (status = 0) & S.Equal(bare^, request.peer^)
END Matches;

PROCEDURE (router: Router) Ready*(client: Client.Client; jid: T.String);
  VAR domain: ARRAY maxJIDUnits+1 OF T.CodeUnit; status: LONGINT;
BEGIN
  ASSERT(router.client = NIL); router.client := client; router.full := CanonicalJID(jid^);
  IF router.full = NIL THEN client.Abort; router.hook.Error(client, Msg.New(context, invalidRequest)); RETURN END;
  router.bare := Bare(router.full); J.ServerFromJid(router.full^, domain, status); ASSERT(status = 0);
  router.domain := Items.Copy16(domain); router.active := TRUE; router.hook.Ready(client, jid)
END Ready;

PROCEDURE (router: Router) Received*(client: Client.Client; stanza: Core.Stanza);
  VAR payload: Items.Item; response: Core.Stanza; i, count, errors: LONGINT; error: Msg.Msg; from: T.String;
BEGIN
  ASSERT(client = router.client);
  IF router.active & (client.state = Client.online) & (stanza.kind = Core.iq) &
     (stanza.id[0] # 0) & (S.Length(stanza.id^) <= maxIDUnits) THEN
    count := Children(stanza, payload, errors);
    IF S.Equal8(stanza.type^, "result") OR S.Equal8(stanza.type^, "error") THEN
      FOR i := 0 TO maxPending-1 DO
        IF (router.requests[i] # NIL) & S.Equal(router.requests[i].id^, stanza.id^) & Matches(router, router.requests[i], stanza) THEN
          IF S.Equal8(stanza.type^, "result") & (count >= 0) & (count <= 1) & (errors = 0) THEN Finish(router, i, result, stanza)
          ELSIF S.Equal8(stanza.type^, "error") & (count >= 0) & (count <= 1) & (errors = 1) & ValidError(stanza) THEN Finish(router, i, stanzaError, stanza)
          ELSE Finish(router, i, malformed, stanza)
          END;
          RETURN
        END
      END
    ELSIF (S.Equal8(stanza.type^, "get") OR S.Equal8(stanza.type^, "set")) & Addressed(router, stanza) THEN
      IF (stanza.from[0] = 0) & (stanza.item.GetAttribute("", "from") # NIL) THEN RETURN END;
      IF stanza.from[0] # 0 THEN
        from := CanonicalJID(stanza.from^); IF from = NIL THEN RETURN END
      END;
      IF (count # 1) OR (errors # 0) THEN response := ErrorReply(stanza, "modify", "bad-request")
      ELSE
        response := NIL; i := 0;
        WHILE (i < router.routes) & (response = NIL) DO
          IF Named(payload, router.handlers[i].uri^, router.handlers[i].name^) THEN
            response := router.handlers[i].handler.Handle(router, stanza, payload)
          END;
          INC(i)
        END;
        IF response = NIL THEN response := ErrorReply(stanza, "cancel", "service-unavailable") END
      END;
      client.Send(response, error); RETURN
    END
  END;
  router.hook.Received(client, stanza)
END Received;

PROCEDURE (router: Router) Sent*(client: Client.Client; stanza: Core.Stanza);
BEGIN router.hook.Sent(client, stanza) END Sent;
PROCEDURE (router: Router) Error*(client: Client.Client; error: Msg.Msg);
BEGIN Stop(router, sendFailed); router.hook.Error(client, error) END Error;
PROCEDURE (router: Router) Closed*(client: Client.Client);
BEGIN Stop(router, cancelled); router.hook.Closed(client) END Closed;

PROCEDURE New*(hook: Client.Hook): Router;
  VAR router: Router;
BEGIN ASSERT(hook # NIL); NEW(router); router.hook := hook; RETURN router END New;

BEGIN NEW(context); Msg.InitContext(context, "XmppIQ")
END XmppIQ.
