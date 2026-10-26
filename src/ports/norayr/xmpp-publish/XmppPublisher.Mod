MODULE XmppPublisher;

(* Publishing one entry over verified TLS and reporting success only after a
   matching IQ result. The caller supplies configuration and owns diagnostics. *)

IMPORT Msg, S := LongStrings, Time, JulianDay, Random := TLS13Random,
  T := XmppTypes, Items := XmppItems, J := XmppStrings, C := XmppClient, TCP := XmppTCP,
  IQ := XmppIQ, Ping := XmppPing, Sasl := XmppSasl, PEP := XmppPEP,
  PubSub := XmppPubSub, Config := XmppPublishConfig;

CONST configurationError* = 1; publishError* = 2; deadlineError* = 3; verificationError* = 4;
TYPE
  Hook = POINTER TO HookDesc;
  HookDesc = RECORD (C.HookDesc) END;
  Action = POINTER TO ActionDesc;
  ActionDesc = RECORD (IQ.ActionDesc)
    accepted, verifying: BOOLEAN; itemID: ARRAY 65 OF CHAR; expected: T.String;
  END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR text: Msg.LString);
BEGIN
  CASE message.code OF
  | configurationError: S.Long("Invalid XMPP publisher configuration, timestamp or random source", text)
  | deadlineError: S.Long("XMPP publish deadline exceeded", text)
  | verificationError: S.Long("Published XMPP item could not be verified by retrieval", text)
  ELSE S.Long("XMPP publication was not acknowledged with a valid IQ result", text)
  END
END GetTemplate;

PROCEDURE (a: Action) Done(router: IQ.Router; request: IQ.Request);
  VAR items, item, entry, content: Items.Item; text, type: T.String; node: Items.Content;
BEGIN
  IF ~a.verifying THEN a.accepted := PEP.Accepted(request, a.itemID); RETURN END;
  a.accepted := FALSE; items := PubSub.ReadItems(request); IF items = NIL THEN RETURN END;
  item := items.First(PEP.pubsubURI, "item"); IF item = NIL THEN RETURN END;
  entry := item.First(PEP.atomURI, "entry"); IF entry = NIL THEN RETURN END;
  content := entry.First(PEP.atomURI, "content"); IF content = NIL THEN RETURN END;
  type := content.GetAttribute("", "type"); IF (type # NIL) & ~S.Equal8(type^, "text") THEN RETURN END;
  node := content.content;
  WHILE node # NIL DO IF node.element # NIL THEN RETURN END; node := node.next END;
  text := content.Text(); a.accepted := S.Equal(text^, a.expected^)
END Done;

PROCEDURE UUID(VAR id: ARRAY OF CHAR): BOOLEAN;
  VAR bytes: ARRAY 16 OF CHAR; hex: ARRAY 17 OF CHAR; i, pos, value: LONGINT;
BEGIN
  IF ~Random.Fill(bytes, LEN(bytes)) THEN RETURN FALSE END;
  hex := "0123456789abcdef";
  bytes[6] := CHR(ORD(bytes[6]) MOD 16+64); bytes[8] := CHR(ORD(bytes[8]) MOD 64+128); pos := 0;
  FOR i := 0 TO 15 DO
    IF (i = 4) OR (i = 6) OR (i = 8) OR (i = 10) THEN id[pos] := "-"; INC(pos) END;
    value := ORD(bytes[i]); id[pos] := hex[value DIV 16]; id[pos+1] := hex[value MOD 16]; INC(pos, 2)
  END;
  id[pos] := 0X; RETURN TRUE
END UUID;

PROCEDURE Put2(VAR text: ARRAY OF CHAR; pos, value: LONGINT);
BEGIN text[pos] := CHR(ORD("0")+value DIV 10); text[pos+1] := CHR(ORD("0")+value MOD 10) END Put2;

PROCEDURE Stamp(VAR text: ARRAY OF CHAR);
  VAR now: Time.TimeStamp; day, month: SHORTINT; year: INTEGER;
BEGIN
  Time.GetTime(now); JulianDay.DaysToDate(now.days, day, month, year);
  COPY("0000-00-00T00:00:00Z", text);
  Put2(text, 0, year DIV 100); Put2(text, 2, year MOD 100); Put2(text, 5, month); Put2(text, 8, day);
  Put2(text, 11, now.msecs DIV 3600000); Put2(text, 14, now.msecs DIV 60000 MOD 60); Put2(text, 17, now.msecs DIV 1000 MOD 60)
END Stamp;

PROCEDURE Age(start: Time.TimeStamp): LONGINT;
  VAR now: Time.TimeStamp; days, elapsed: LONGINT;
BEGIN
  Time.GetTime(now); days := now.days-start.days;
  IF (days < 0) OR (days > 1) THEN RETURN MAX(LONGINT) END;
  elapsed := days*Time.msecPerDay+now.msecs-start.msecs;
  IF elapsed < 0 THEN RETURN MAX(LONGINT) END; RETURN elapsed
END Age;

PROCEDURE RunItem*(VAR cfg: Config.Config; itemID: ARRAY OF CHAR; verify: BOOLEAN; VAR error: Msg.Msg): BOOLEAN;
  VAR jid, password, message: T.String; domainBytes: Items.Bytes;
    user, domain, resource, bare: ARRAY IQ.maxJIDUnits+1 OF T.CodeUnit;
    host: ARRAY 1024 OF CHAR; stamp: ARRAY 21 OF CHAR; payload: Items.Item;
    wire: TCP.Transport; client: C.Client; hook: Hook; router: IQ.Router; ping: Ping.Pinger;
    action: Action; request: IQ.Request; status, steps, elapsed: LONGINT;
    start: Time.TimeStamp; state: SHORTINT; ok: BOOLEAN;
BEGIN
  error := NIL; NEW(action); jid := Items.UTF8(cfg.jid); password := Items.UTF8(cfg.password);
  Config.Wipe(cfg); message := Items.UTF8(cfg.message);
  IF jid # NIL THEN jid := IQ.CanonicalJID(jid^) END;
  IF (jid = NIL) OR (password = NIL) OR (message = NIL) OR ~cfg.allowPlain OR
     (cfg.timeoutMS <= 0) OR (cfg.timeoutMS > 60000) OR (S.Length8(itemID) > 64) THEN
    Sasl.Wipe(password); error := Msg.New(context, configurationError); RETURN FALSE
  END;
  IF (S.Length(password^) = 0) OR (S.Length(password^) > Sasl.maxFieldUnits) THEN
    Sasl.Wipe(password); error := Msg.New(context, configurationError); RETURN FALSE
  END;
  J.UsernameFromJid(jid^, user, status);
  IF status # 0 THEN Sasl.Wipe(password); error := Msg.New(context, configurationError); RETURN FALSE END;
  J.ServerFromJid(jid^, domain, status); J.ResourceFromJid(jid^, resource); J.GetShortJidFromFullJid(jid^, bare);
  IF resource[0] = 0 THEN S.Long("voc-publish", resource) END;
  domainBytes := Items.UTF8Bytes(domain); Stamp(stamp);
  COPY(itemID, action.itemID); action.expected := message;
  payload := PEP.Build(domainBytes^, message^, action.itemID, stamp);
  IF payload = NIL THEN Sasl.Wipe(password); error := Msg.New(context, configurationError); RETURN FALSE END;
  IF cfg.host[0] = 0X THEN COPY(domainBytes^, host) ELSE COPY(cfg.host, host) END;
  Time.GetTime(start); wire := TCP.Open(host, cfg.port, domainBytes^, cfg.directTLS, cfg.timeoutMS, error);
  IF wire = NIL THEN Sasl.Wipe(password); RETURN FALSE END;
  NEW(hook); router := IQ.New(hook); ping := Ping.New(router); ASSERT(ping # NIL);
  client := C.New(wire, router, domainBytes^, user, password^, resource, TRUE, error); Sasl.Wipe(password);
  IF client = NIL THEN wire.Close; RETURN FALSE END;
  ok := client.Start(); steps := 0;
  WHILE ok & (client.state # C.online) DO
    state := client.Step(); INC(steps);
    ok := (state # C.failed) & (state # C.closed) & (steps < 10000) & (Age(start) < cfg.timeoutMS)
  END;
  IF ok THEN
    J.GetShortJidFromFullJid(client.jid^, bare);
    request := router.Query(bare, payload, TRUE, cfg.timeoutMS, action, error); ok := (request # NIL) & (error = NIL);
    WHILE ok & (request.status = IQ.pending) DO
      state := client.Step(); INC(steps); elapsed := Age(start);
      ok := (state = C.online) & (steps < 10000) & (elapsed < cfg.timeoutMS)
    END;
    ok := ok & action.accepted
  END;
  IF ok & verify THEN
    action.verifying := TRUE; action.accepted := FALSE;
    message := Items.Latin1(PEP.microblogNode); jid := Items.Latin1(action.itemID);
    request := PubSub.Fetch(router, bare, message^, jid^, 1, cfg.timeoutMS, action, error);
    ok := (request # NIL) & (error = NIL);
    WHILE ok & (request.status = IQ.pending) DO
      state := client.Step(); INC(steps); elapsed := Age(start);
      ok := (state = C.online) & (steps < 10000) & (elapsed < cfg.timeoutMS)
    END;
    ok := ok & action.accepted
  END;
  IF ok THEN
    client.Close(error); ok := error = NIL;
    WHILE ok & (client.state # C.closed) DO
      state := client.Step(); INC(steps);
      ok := (state # C.failed) & (steps < 10000) & (Age(start) < cfg.timeoutMS)
    END
  END;
  IF ~ok & (error = NIL) THEN
    IF client.error # NIL THEN error := client.error
    ELSIF Age(start) >= cfg.timeoutMS THEN error := Msg.New(context, deadlineError)
    ELSIF action.verifying THEN error := Msg.New(context, verificationError)
    ELSE error := Msg.New(context, publishError)
    END
  END;
  router.Stop; client.Abort; RETURN ok
END RunItem;

PROCEDURE Run*(VAR cfg: Config.Config; VAR error: Msg.Msg): BOOLEAN;
  VAR id: ARRAY 37 OF CHAR;
BEGIN
  IF ~UUID(id) THEN Config.Wipe(cfg); error := Msg.New(context, configurationError); RETURN FALSE END;
  RETURN RunItem(cfg, id, FALSE, error)
END Run;

BEGIN NEW(context); Msg.InitContext(context, "XmppPublisher")
END XmppPublisher.
