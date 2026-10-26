MODULE XmppProbe;

(* A command-line XMPP login probe. JID and dial address are UTF-8; the password
   is read from standard input. The optional self-test sends only to this bound
   resource and checks that its Unicode message returns. *)

IMPORT Args, In, Out, Msg, S := LongStrings, T := XmppTypes, Items := XmppItems,
  J := XmppStrings, C := XmppClient, TCP := XmppTCP, Core := XmppCore,
  Messenger := XmppMessenger, Sasl := XmppSasl, TLS := TLS13Live;

TYPE
  Hook = POINTER TO HookDesc;
  HookDesc = RECORD (C.HookDesc)
    ready, returned, failed: BOOLEAN;
    expected: T.String;
  END;

VAR jidBytes, host: ARRAY 4096 OF CHAR; domain, port, mode: ARRAY 1024 OF CHAR;
  user, service, resource: ARRAY 1024 OF T.CodeUnit;
  passwordBytes: ARRAY 4097 OF CHAR; jid, password: T.String;
  serviceBytes: Items.Bytes;
  wire: TCP.Transport; client: C.Client; hook: Hook; error: Msg.Msg;
  result, i, steps: LONGINT; state, previous: SHORTINT; stanza: Core.Stanza;

PROCEDURE PrintText(text: T.String);
  VAR bytes: Items.Bytes;
BEGIN
  bytes := Items.UTF8Bytes(text^); IF bytes # NIL THEN Out.String(bytes^) END
END PrintText;

PROCEDURE PrintError(error: Msg.Msg);
  VAR text: ARRAY 1024 OF CHAR;
BEGIN
  IF error # NIL THEN error.GetText(text); Out.String(text) ELSE Out.String("operation failed") END;
  Out.Ln;
  IF TLS.lastError # "" THEN Out.String("TLS: "); Out.String(TLS.lastError); Out.Ln END
END PrintError;

PROCEDURE (h: Hook) Ready(client: C.Client; jid: T.String);
BEGIN h.ready := TRUE; Out.String("Bound JID: "); PrintText(jid); Out.Ln END Ready;

PROCEDURE (h: Hook) Received(client: C.Client; stanza: Core.Stanza);
  VAR text: T.String;
BEGIN
  IF stanza.kind = Core.message THEN
    text := Messenger.Body(stanza);
    IF (text # NIL) & S.Equal(text^, h.expected^) THEN
      h.returned := TRUE; Out.String("Unicode self-message received"); Out.Ln
    END
  END
END Received;

PROCEDURE (h: Hook) Error(client: C.Client; error: Msg.Msg);
BEGIN h.failed := TRUE; PrintError(error) END Error;

BEGIN
  IF Args.argc < 4 THEN
    Out.String("Usage: XmppProbe jid dial-host port [self-test]; password on standard input"); Out.Ln; HALT(2)
  END;
  Args.Get(1, jidBytes); Args.Get(2, host); Args.Get(3, port); Args.Get(4, mode);
  jid := Items.UTF8(jidBytes);
  IF (jid = NIL) OR ~J.JidCorrect(jid^) THEN Out.String("Invalid UTF-8 JID"); Out.Ln; HALT(2) END;
  J.UsernameFromJid(jid^, user, result); IF result # 0 THEN HALT(2) END;
  J.ServerFromJid(jid^, service, result); IF result # 0 THEN HALT(2) END;
  J.ResourceFromJid(jid^, resource);
  IF resource[0] = 0 THEN jid := Items.UTF8("voc-մուտք"); S.Assign(jid^, resource) END;
  serviceBytes := Items.UTF8Bytes(service);
  IF (serviceBytes = NIL) OR (S.Length8(serviceBytes^) >= LEN(domain)) THEN HALT(2) END;
  COPY(serviceBytes^, domain);
  In.Line(passwordBytes);
  IF ~In.Done OR (S.Length8(passwordBytes) >= LEN(passwordBytes)-1) THEN HALT(2) END;
  password := Items.UTF8(passwordBytes);
  FOR i := 0 TO LEN(passwordBytes)-1 DO passwordBytes[i] := 0X END;
  IF password = NIL THEN Out.String("Invalid UTF-8 password"); Out.Ln; HALT(2) END;
  TLS.verbose := FALSE; wire := TCP.Open(host, port, domain, FALSE, 10000, error);
  IF wire = NIL THEN Sasl.Wipe(password); PrintError(error); HALT(1) END;
  NEW(hook); hook.expected := Items.UTF8("VOC Unicode round-trip: Բարեւ, աշխարհ 😀");
  client := C.New(wire, hook, domain, user, password^, resource, TRUE, error); Sasl.Wipe(password);
  IF client = NIL THEN wire.Close; PrintError(error); HALT(1) END;
  IF ~client.Start() THEN HALT(1) END;
  steps := 0; previous := -1;
  REPEAT
    state := client.Step(); INC(steps); IF steps > 100000 THEN client.Abort; HALT(1) END;
    IF state # previous THEN Out.String("Client state: "); Out.Int(state, 0); Out.Ln; previous := state END
  UNTIL (state = C.online) OR (state = C.failed) OR (state = C.closed);
  IF state # C.online THEN client.Abort; HALT(1) END;
  IF mode = "self-test" THEN
    stanza := Core.NewStanza("presence"); client.Send(stanza, error);
    IF error # NIL THEN client.Abort; HALT(1) END;
    stanza := Messenger.NewMessage(client.jid^, hook.expected^); client.Send(stanza, error);
    IF error # NIL THEN client.Abort; HALT(1) END;
    REPEAT state := client.Step() UNTIL hook.returned OR (state = C.failed) OR (state = C.closed);
    IF ~hook.returned THEN client.Abort; HALT(1) END
  END;
  client.Close(error); IF error # NIL THEN client.Abort; HALT(1) END;
  REPEAT state := client.Step() UNTIL (state = C.failed) OR (state = C.closed);
  IF state # C.closed THEN client.Abort; HALT(1) END;
  Out.String("Verified TLS, UTF-8 authentication and resource binding passed"); Out.Ln
END XmppProbe.
