MODULE XmppClient;

(* A bounded synchronous client negotiation: verified TLS, explicit SASL PLAIN
   opt-in, stream restart and resource binding. Application hooks receive only
   online stanzas. The transport authenticates the configured service domain. *)

IMPORT Msg, S := LongStrings, T := XmppTypes, Items := XmppItems,
  Core := XmppCore, Const := XmppConst, XML := XmppXmlStream,
  Wire := XmppWire, Sasl := XmppSasl, J := XmppStrings;

CONST
  idle* = 0; opening* = 1; features* = 2; proceeding* = 3;
  upgrading* = 4; authenticating* = 5; restarting = 6; binding* = 7;
  online* = 8; closing* = 9; closed* = 10; failed* = 11;
  protocolError* = 1; tlsRequired* = 2; mechanismRequired* = 3;
  authenticationFailed* = 4; bindingFailed* = 5; transportError* = 6;
  negotiationLimit* = 7; invalidConfig* = 8; notOnline* = 9;
  bindID = "voc-bind-1";
  maxNegotiationBytes* = 256*1024; maxNegotiationEvents* = 64;

TYPE
  Client* = POINTER TO ClientDesc;
  Hook* = POINTER TO HookDesc;
  HookDesc* = RECORD END;
  ClientDesc* = RECORD (Core.HookDesc)
    state-: SHORTINT;
    authenticated-: BOOLEAN;
    jid-: T.String;
    error-: Msg.Msg;
    session: Core.Session;
    wire: Wire.Transport;
    hook: Hook;
    domain: Items.Bytes;
    username, password, resource: T.String;
    allowPlain: BOOLEAN;
    buffer: ARRAY 8192 OF CHAR;
    position, length, negotiationBytes, negotiationEvents: LONGINT;
  END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR text: Msg.LString);
  VAR template: ARRAY 96 OF CHAR;
BEGIN
  CASE message.code OF
  | protocolError: template := "Unexpected XMPP negotiation element or stream state"
  | tlsRequired: template := "XMPP requires TLS authenticated for the configured service domain"
  | mechanismRequired: template := "XMPP requires an explicitly enabled, advertised SASL mechanism"
  | authenticationFailed: template := "XMPP SASL authentication failed"
  | bindingFailed: template := "XMPP resource binding failed or returned an invalid JID"
  | transportError: template := "XMPP transport ended or failed"
  | negotiationLimit: template := "XMPP negotiation byte or event limit exceeded"
  | invalidConfig: template := "Invalid XMPP service domain or bounded UTF-16 credentials"
  ELSE template := "XMPP session is not online"
  END;
  S.Long(template, text)
END GetTemplate;

PROCEDURE (h: Hook) Ready*(client: Client; jid: T.String);
BEGIN END Ready;
PROCEDURE (h: Hook) Received*(client: Client; stanza: Core.Stanza);
BEGIN END Received;
PROCEDURE (h: Hook) Sent*(client: Client; stanza: Core.Stanza);
BEGIN END Sent;
PROCEDURE (h: Hook) Error*(client: Client; error: Msg.Msg);
BEGIN END Error;
PROCEDURE (h: Hook) Closed*(client: Client);
BEGIN END Closed;

PROCEDURE Fail(c: Client; code: SHORTINT; error: Msg.Msg);
BEGIN
  IF (c.state = failed) OR (c.state = closed) THEN RETURN END;
  IF error = NIL THEN error := Msg.New(context, code) END;
  c.error := error; c.state := failed; c.authenticated := FALSE;
  Sasl.Wipe(c.password); c.wire.Close; c.hook.Error(c, error)
END Fail;

PROCEDURE Named(item: Items.Item; uri, name: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN (item # NIL) & (item.namespaceURI^ = uri) & S.Equal8(item.name^, name) END Named;

PROCEDURE Scalar(item: Items.Item): BOOLEAN;
  VAR content: Items.Content;
BEGIN
  content := item.content;
  WHILE content # NIL DO
    IF content.element # NIL THEN RETURN FALSE END;
    content := content.next
  END;
  RETURN TRUE
END Scalar;

PROCEDURE Empty(item: Items.Item): BOOLEAN;
  VAR text: T.String; i: LONGINT;
BEGIN
  IF ~Scalar(item) THEN RETURN FALSE END;
  text := item.Text(); i := 0;
  WHILE text[i] # 0 DO
    IF (text[i] # 32) & (text[i] # 9) & (text[i] # 10) & (text[i] # 13) THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END Empty;

PROCEDURE Unique(item: Items.Item; uri, name: ARRAY OF CHAR): Items.Item;
  VAR content: Items.Content; result: Items.Item;
BEGIN
  result := NIL; content := item.content;
  WHILE content # NIL DO
    IF Named(content.element, uri, name) THEN
      IF result # NIL THEN RETURN NIL END;
      result := content.element
    END;
    content := content.next
  END;
  RETURN result
END Unique;

PROCEDURE SameDomain(c: Client; text: ARRAY OF T.CodeUnit): BOOLEAN;
  VAR bytes, canonical: Items.Bytes;
BEGIN
  bytes := Items.UTF8Bytes(text); IF bytes = NIL THEN RETURN FALSE END;
  RETURN c.wire.DomainName(bytes^, canonical) & (canonical^ = c.domain^)
END SameDomain;

PROCEDURE StartHeader(c: Client);
  VAR domain, empty: T.String; error: Msg.Msg;
BEGIN
  domain := Items.UTF8(c.domain^); empty := Items.Latin1(""); c.state := opening;
  c.session.StartStream(domain^, empty^, empty^, empty^, error);
  IF error # NIL THEN Fail(c, transportError, error) END
END StartHeader;

PROCEDURE Private(c: Client; item: Items.Item);
  VAR error: Msg.Msg;
BEGIN
  c.session.connection.WritePrivate(item, error);
  IF error # NIL THEN Fail(c, transportError, error) END
END Private;

PROCEDURE Authenticate(c: Client; features: Items.Item);
  VAR mechanisms, mechanism, auth: Items.Item; content: Items.Content; text, name: T.String;
    response: T.String; error: Msg.Msg; offered: BOOLEAN;
BEGIN
  IF ~c.allowPlain OR ~c.wire.AuthenticatedFor(c.domain^) THEN Fail(c, mechanismRequired, NIL); RETURN END;
  mechanisms := Unique(features, Const.uriSasl, "mechanisms"); offered := FALSE;
  IF mechanisms # NIL THEN
    content := mechanisms.content;
    WHILE content # NIL DO
      mechanism := content.element;
      IF Named(mechanism, Const.uriSasl, "mechanism") & Scalar(mechanism) THEN
        text := mechanism.Text(); IF S.Equal8(text^, "PLAIN") THEN offered := TRUE END
      END;
      content := content.next
    END
  END;
  IF ~offered THEN Fail(c, mechanismRequired, NIL); RETURN END;
  Sasl.Plain(c.username^, c.password^, c.wire.AuthenticatedFor(c.domain^), response, error);
  Sasl.Wipe(c.password);
  IF error # NIL THEN Fail(c, authenticationFailed, error); RETURN END;
  auth := Items.New("auth", Const.uriSasl); name := Items.Latin1("PLAIN"); auth.SetParam("mechanism", name^);
  auth.AddText(response^, 0, S.Length(response^)); Sasl.Wipe(response);
  c.state := authenticating; Private(c, auth);
  Sasl.Wipe(auth.content.text)
END Authenticate;

PROCEDURE Bind(c: Client; features: Items.Item);
  VAR iq, bind, resource: Items.Item; id, type: T.String;
BEGIN
  IF Unique(features, Const.uriBind, "bind") = NIL THEN Fail(c, bindingFailed, NIL); RETURN END;
  iq := Items.New("iq", Const.jabberClient); id := Items.Latin1(bindID); type := Items.Latin1("set");
  iq.SetParam("id", id^); iq.SetParam("type", type^); bind := Items.New("bind", Const.uriBind);
  IF S.Length(c.resource^) > 0 THEN
    resource := Items.New("resource", Const.uriBind); resource.AddText(c.resource^, 0, S.Length(c.resource^));
    bind.AddChild(resource)
  END;
  iq.AddChild(bind); c.state := binding; Private(c, iq)
END Bind;

PROCEDURE Bound(c: Client; item: Items.Item);
  VAR bind, jid: Items.Item; text, id, type: T.String;
    domain, local, resource: ARRAY 3072 OF T.CodeUnit; result: LONGINT;
BEGIN
  id := item.GetAttribute("", "id"); type := item.GetAttribute("", "type");
  IF ~Named(item, Const.jabberClient, "iq") OR (id = NIL) OR ~S.Equal8(id^, bindID) OR
     (type = NIL) OR ~S.Equal8(type^, "result") THEN Fail(c, bindingFailed, NIL); RETURN END;
  bind := Unique(item, Const.uriBind, "bind");
  IF bind = NIL THEN Fail(c, bindingFailed, NIL); RETURN END;
  jid := Unique(bind, Const.uriBind, "jid");
  IF (jid = NIL) OR ~Scalar(jid) THEN Fail(c, bindingFailed, NIL); RETURN END;
  text := jid.Text();
  IF (S.Length(text^) >= LEN(domain)) OR ~J.JidCorrect(text^) THEN Fail(c, bindingFailed, NIL); RETURN END;
  J.ServerFromJid(text^, domain, result);
  IF (result # 0) OR ~SameDomain(c, domain) THEN Fail(c, bindingFailed, NIL); RETURN END;
  J.UsernameFromJid(text^, local, result); J.ResourceFromJid(text^, resource);
  IF (result # 0) OR (resource[0] = 0) THEN Fail(c, bindingFailed, NIL); RETURN END;
  c.jid := text; c.state := online; c.hook.Ready(c, text)
END Bound;

PROCEDURE (c: Client) Opened*(session: Core.Session; header: Items.Item);
  VAR version, from: T.String;
BEGIN
  IF c.state # opening THEN Fail(c, protocolError, NIL); RETURN END;
  version := header.GetAttribute("", "version");
  IF (version = NIL) OR ~S.Equal8(version^, "1.0") THEN Fail(c, protocolError, NIL); RETURN END;
  from := header.GetAttribute("", "from");
  IF (from # NIL) & ~SameDomain(c, from^) THEN Fail(c, protocolError, NIL); RETURN END;
  c.state := features
END Opened;

PROCEDURE (c: Client) In*(session: Core.Session; stanza: Core.Stanza);
BEGIN
  IF c.state = binding THEN Bound(c, stanza.item)
  ELSIF (c.state = online) OR (c.state = closing) THEN c.hook.Received(c, stanza)
  ELSE Fail(c, protocolError, NIL)
  END
END In;

PROCEDURE (c: Client) Out*(session: Core.Session; stanza: Core.Stanza);
BEGIN IF c.state = online THEN c.hook.Sent(c, stanza) END END Out;

PROCEDURE (c: Client) Other*(session: Core.Session; item: Items.Item);
BEGIN
  IF Named(item, Const.uriStream, "error") THEN Fail(c, protocolError, NIL)
  ELSIF c.state = features THEN
    IF ~Named(item, Const.uriStream, "features") THEN Fail(c, protocolError, NIL)
    ELSIF ~c.wire.AuthenticatedFor(c.domain^) THEN
      IF c.authenticated OR (Unique(item, Const.uriTls, "starttls") = NIL) THEN Fail(c, tlsRequired, NIL)
      ELSE c.state := proceeding; Private(c, Items.New("starttls", Const.uriTls))
      END
    ELSIF c.authenticated THEN Bind(c, item)
    ELSE Authenticate(c, item)
    END
  ELSIF c.state = proceeding THEN
    IF Named(item, Const.uriTls, "proceed") & Empty(item) THEN c.state := upgrading
    ELSE Fail(c, tlsRequired, NIL)
    END
  ELSIF c.state = authenticating THEN
    IF Named(item, Const.uriSasl, "success") & Empty(item) THEN
      c.authenticated := TRUE; c.state := restarting
    ELSE Fail(c, authenticationFailed, NIL)
    END
  ELSIF c.state = online THEN
    Fail(c, protocolError, NIL)
  ELSE Fail(c, protocolError, NIL)
  END
END Other;

PROCEDURE (c: Client) Error*(session: Core.Session; error: Msg.Msg);
BEGIN Fail(c, protocolError, error) END Error;

PROCEDURE (c: Client) Closed*(session: Core.Session);
  VAR error: Msg.Msg;
BEGIN
  IF (c.state # online) & (c.state # closing) THEN Fail(c, protocolError, NIL); RETURN END;
  IF c.state = online THEN
    c.state := closing; c.session.CloseStream(error);
    IF error # NIL THEN Fail(c, transportError, error); RETURN END
  END;
  c.state := closed; c.wire.Close; c.hook.Closed(c)
END Closed;

PROCEDURE (c: Client) Start*(): BOOLEAN;
BEGIN
  IF c.state # idle THEN RETURN FALSE END;
  StartHeader(c); RETURN c.state # failed
END Start;

PROCEDURE (c: Client) Step*(): SHORTINT;
(* Performs at most one read and one XML event. Reads and TLS upgrades may block
   within the transport's deadlines. All unconsumed application bytes stay local. *)
  VAR n, count: LONGINT; event: SHORTINT; negotiating, ok: BOOLEAN;
BEGIN
  IF (c.state = idle) OR (c.state = failed) OR (c.state = closed) THEN RETURN c.state END;
  negotiating := (c.state # online) & (c.state # closing);
  IF negotiating & ((c.negotiationBytes = maxNegotiationBytes) OR
                    (c.negotiationEvents = maxNegotiationEvents)) THEN
    Fail(c, negotiationLimit, NIL); RETURN c.state
  END;
  IF c.position = c.length THEN
    ok := c.wire.Read(c.buffer, c.length); c.position := 0;
    ASSERT((c.length >= 0) & (c.length <= LEN(c.buffer)));
    IF ~ok OR (c.length = 0) THEN
      Fail(c, transportError, c.wire.res); RETURN c.state
    END
  END;
  count := c.length-c.position;
  IF negotiating THEN
    IF count > maxNegotiationBytes-c.negotiationBytes THEN count := maxNegotiationBytes-c.negotiationBytes END
  END;
  event := c.session.Feed(c.buffer, c.position, count, n); INC(c.position, n);
  IF negotiating THEN
    INC(c.negotiationBytes, n);
    IF event # XML.needInput THEN INC(c.negotiationEvents) END
  END;
  IF c.state = upgrading THEN
    (* A TLS server cannot send its handshake before this client sends ClientHello. *)
    IF c.position # c.length THEN Fail(c, protocolError, NIL)
    ELSIF ~c.wire.StartTLS(c.domain^) OR ~c.wire.AuthenticatedFor(c.domain^) THEN Fail(c, tlsRequired, c.wire.res)
    ELSIF ~c.session.Restart() THEN Fail(c, protocolError, NIL)
    ELSE StartHeader(c)
    END
  ELSIF c.state = restarting THEN
    IF ~c.wire.AuthenticatedFor(c.domain^) OR ~c.session.Restart() THEN Fail(c, protocolError, NIL)
    ELSE StartHeader(c)
    END
  END;
  RETURN c.state
END Step;

PROCEDURE (c: Client) Send*(stanza: Core.Stanza; VAR error: Msg.Msg);
BEGIN
  error := NIL;
  IF (c.state # online) OR ~c.wire.AuthenticatedFor(c.domain^) THEN error := Msg.New(context, notOnline); RETURN END;
  c.session.Send(stanza, error);
  IF error # NIL THEN Fail(c, transportError, error) END
END Send;

PROCEDURE (c: Client) Close*(VAR error: Msg.Msg);
BEGIN
  error := NIL;
  IF c.state # online THEN error := Msg.New(context, notOnline); RETURN END;
  c.state := closing; c.session.CloseStream(error);
  IF error # NIL THEN Fail(c, transportError, error) END
END Close;

PROCEDURE (c: Client) Abort*;
BEGIN
  Sasl.Wipe(c.password); c.wire.Close;
  IF c.state # failed THEN c.state := closed END
END Abort;

PROCEDURE New*(wire: Wire.Transport; hook: Hook; domain: ARRAY OF CHAR;
               username, password, resource: ARRAY OF T.CodeUnit; allowPlain: BOOLEAN;
               VAR error: Msg.Msg): Client;
  VAR c: Client; canonical: Items.Bytes; domainUnits: T.String;
BEGIN
  ASSERT((wire # NIL) & (hook # NIL)); error := NIL;
  IF ~wire.DomainName(domain, canonical) OR (S.Length(username) = 0) OR (S.Length(username) > Sasl.maxFieldUnits) OR
     (S.Length(password) = 0) OR (S.Length(password) > Sasl.maxFieldUnits) OR
     (S.Length(resource) > 1024) THEN error := Msg.New(context, invalidConfig); RETURN NIL END;
  domainUnits := Items.UTF8(canonical^);
  IF domainUnits = NIL THEN error := Msg.New(context, invalidConfig); RETURN NIL END;
  NEW(c); c.wire := wire; c.hook := hook; c.domain := canonical;
  c.username := Items.Copy16(username); c.password := Items.Copy16(password); c.resource := Items.Copy16(resource);
  c.allowPlain := allowPlain; c.state := idle; c.session := Core.NewSession(c, wire);
  RETURN c
END New;

BEGIN
  NEW(context); Msg.InitContext(context, "XmppClient")
END XmppClient.
