MODULE XmppRegister;

(* XEP-0077 legacy fields, explicit submissions and authenticated removal. *)

IMPORT Msg, S := LongStrings, T := XmppTypes, Items := XmppItems,
  Const := XmppConst, Client := XmppClient, IQ := XmppIQ, Sasl := XmppSasl;

CONST
  namespaceURI* = Const.uriRegister;
  maxFields* = 32; maxFieldUnits* = 4096; maxTotalUnits* = 16384; maxParts* = 128;
  invalidRequest* = 1; offline* = 2; unsupported* = 3; authenticationRequired* = 4;

TYPE
  Field* = RECORD name-: Items.Bytes; value-: T.String END;
  Form* = POINTER TO FormDesc;
  FormDesc* = RECORD
    instructions-: T.String;
    registered-, legacy-, dataForm-, outOfBand-: BOOLEAN;
    count-: LONGINT;
    fields-: ARRAY maxFields OF Field;
    peer: T.String;
    owner: Client.Client;
    source: Items.Item;
    units: LONGINT;
    cleared: BOOLEAN
  END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR text: Msg.LString);
BEGIN
  CASE message.code OF
  | offline: S.Long("XMPP registration transport is not ready", text)
  | unsupported: S.Long("This registration response requires an unsupported form or workflow", text)
  | authenticationRequired: S.Long("Removing an XMPP registration requires an authenticated client", text)
  ELSE S.Long("Invalid bounded XMPP registration request", text)
  END
END GetTemplate;

PROCEDURE Invalid(code: SHORTINT; VAR error: Msg.Msg): IQ.Request;
BEGIN error := Msg.New(context, code); RETURN NIL END Invalid;

PROCEDURE Known(name: ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN (name = "username") OR (name = "nick") OR (name = "password") OR
    (name = "name") OR (name = "first") OR (name = "last") OR (name = "email") OR
    (name = "address") OR (name = "city") OR (name = "state") OR (name = "zip") OR
    (name = "phone") OR (name = "url") OR (name = "date") OR (name = "misc") OR
    (name = "text") OR (name = "key")
END Known;

PROCEDURE Layout(item: Items.Item): BOOLEAN;
  VAR content: Items.Content; attribute: Items.Attribute; count, units, i, length: LONGINT;
BEGIN
  count := 0; attribute := item.attributes;
  WHILE attribute # NIL DO
    INC(count); IF count > maxParts THEN RETURN FALSE END; attribute := attribute.next
  END;
  content := item.content; count := 0; units := 0;
  WHILE content # NIL DO
    INC(count); IF count > maxParts THEN RETURN FALSE END;
    IF content.element = NIL THEN
      length := S.Length(content.text^); IF length > maxTotalUnits-units THEN RETURN FALSE END;
      INC(units, length);
      FOR i := 0 TO length-1 DO
        IF (content.text[i] # 32) & (content.text[i] # 9) & (content.text[i] # 10) & (content.text[i] # 13) THEN RETURN FALSE END
      END
    END;
    content := content.next
  END;
  RETURN TRUE
END Layout;

PROCEDURE Scalar(item: Items.Item): T.String;
  VAR content: Items.Content; count, units, length: LONGINT; text: T.String;
BEGIN
  content := item.content; count := 0; units := 0;
  WHILE content # NIL DO
    INC(count); IF (count > maxParts) OR (content.element # NIL) THEN RETURN NIL END;
    length := S.Length(content.text^); IF length > maxFieldUnits-units THEN RETURN NIL END;
    INC(units, length); content := content.next
  END;
  text := item.Text(); IF ~IQ.Value(text^, maxFieldUnits) THEN RETURN NIL END; RETURN text
END Scalar;

PROCEDURE Target(router: IQ.Router; peer: ARRAY OF T.CodeUnit; VAR error: Msg.Msg): T.String;
  VAR text: T.String; bytes: Items.Bytes;
BEGIN
  error := NIL;
  IF (router = NIL) OR (router.client = NIL) OR
     ((router.client.state # Client.online) & (router.client.state # Client.registering)) THEN
    error := Msg.New(context, offline); RETURN NIL
  END;
  IF peer[0] = 0 THEN bytes := router.client.Domain(); text := Items.UTF8(bytes^)
  ELSE text := IQ.CanonicalJID(peer)
  END;
  IF text = NIL THEN error := Msg.New(context, invalidRequest) END;
  RETURN text
END Target;

PROCEDURE Query*(router: IQ.Router; peer: ARRAY OF T.CodeUnit; timeoutMS: LONGINT;
                 action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
  VAR target: T.String;
BEGIN
  target := Target(router, peer, error); IF target = NIL THEN RETURN NIL END;
  RETURN router.QueryExact(target^, Items.New("query", namespaceURI), FALSE, timeoutMS, action, error)
END Query;

PROCEDURE Read*(request: IQ.Request): Form;
  VAR form: Form; query, child: Items.Item; content: Items.Content; text: T.String;
    name, domain: Items.Bytes; peer, service, from: T.String; instructions, registered, i: LONGINT;
BEGIN
  IF (request = NIL) OR (request.client = NIL) OR ~IQ.Named(request.payload, namespaceURI, "query") OR
     ~IQ.Empty(request.payload) THEN RETURN NIL END;
  query := IQ.Payload(request, namespaceURI, "query"); IF (query = NIL) OR ~Layout(query) THEN RETURN NIL END;
  domain := request.client.Domain(); text := Items.UTF8(domain^); service := IQ.CanonicalJID(text^);
  IF request.peer[0] = 0 THEN peer := service ELSE peer := IQ.CanonicalJID(request.peer^) END;
  IF (peer = NIL) OR (service = NIL) THEN RETURN NIL END;
  IF request.reply.from[0] = 0 THEN
    IF (request.reply.item.GetAttribute("", "from") # NIL) OR ~S.Equal(peer^, service^) THEN RETURN NIL END
  ELSE
    from := IQ.CanonicalJID(request.reply.from^); IF (from = NIL) OR ~S.Equal(from^, peer^) THEN RETURN NIL END
  END;
  NEW(form); form.instructions := Items.Latin1(""); form.legacy := TRUE;
  form.owner := request.client; form.peer := peer; form.source := query;
  instructions := 0; registered := 0; content := query.content;
  WHILE content # NIL DO
    child := content.element;
    IF child # NIL THEN
      name := Items.UTF8Bytes(child.name^); IF name = NIL THEN RETURN NIL END;
      IF child.namespaceURI^ = namespaceURI THEN
        IF name^ = "instructions" THEN
          INC(instructions); IF instructions > 1 THEN RETURN NIL END;
          form.instructions := Scalar(child); IF form.instructions = NIL THEN RETURN NIL END;
          INC(form.units, S.Length(form.instructions^))
        ELSIF name^ = "registered" THEN
          INC(registered); IF (registered > 1) OR ~Layout(child) OR ~IQ.Empty(child) THEN RETURN NIL END;
          form.registered := TRUE
        ELSIF Known(name^) THEN
          IF form.count = maxFields THEN RETURN NIL END;
          FOR i := 0 TO form.count-1 DO IF form.fields[i].name^ = name^ THEN RETURN NIL END END;
          text := Scalar(child); IF text = NIL THEN RETURN NIL END;
          form.fields[form.count].name := name; form.fields[form.count].value := text;
          INC(form.count); INC(form.units, S.Length(text^))
        ELSE form.legacy := FALSE
        END
      ELSIF IQ.Named(child, "jabber:x:data", "x") THEN
        form.dataForm := TRUE; form.legacy := FALSE
      ELSIF IQ.Named(child, "jabber:x:oob", "x") THEN
        form.outOfBand := TRUE; form.legacy := FALSE
      ELSE form.legacy := FALSE
      END;
      IF form.units > maxTotalUnits THEN RETURN NIL END
    END;
    content := content.next
  END;
  IF form.count = 0 THEN form.legacy := FALSE END;
  RETURN form
END Read;

PROCEDURE (form: Form) Get*(name: ARRAY OF CHAR): T.String;
  VAR i: LONGINT;
BEGIN
  IF form.cleared THEN RETURN NIL END;
  FOR i := 0 TO form.count-1 DO
    IF form.fields[i].name^ = name THEN RETURN Items.Copy16(form.fields[i].value^) END
  END;
  RETURN NIL
END Get;

PROCEDURE (form: Form) Set*(name: ARRAY OF CHAR; value: ARRAY OF T.CodeUnit): BOOLEAN;
  VAR i, units: LONGINT; copy: T.String;
BEGIN
  IF form.cleared OR ~form.legacy OR ~Known(name) OR ~IQ.Value(value, maxFieldUnits) THEN RETURN FALSE END;
  FOR i := 0 TO form.count-1 DO
    IF form.fields[i].name^ = name THEN
      units := form.units-S.Length(form.fields[i].value^)+S.Length(value);
      IF units > maxTotalUnits THEN RETURN FALSE END;
      copy := Items.Copy16(value); Sasl.Wipe(form.fields[i].value); form.fields[i].value := copy; form.units := units;
      RETURN TRUE
    END
  END;
  RETURN FALSE
END Set;

PROCEDURE Wipe(query: Items.Item);
  VAR content, text: Items.Content; child: Items.Item; name: Items.Bytes;
BEGIN
  content := query.content;
  WHILE content # NIL DO
    child := content.element;
    IF (child # NIL) & (child.namespaceURI^ = namespaceURI) THEN
      name := Items.UTF8Bytes(child.name^);
      IF (name # NIL) & (Known(name^) OR (name^ = "instructions")) THEN
        text := child.content;
        WHILE text # NIL DO
          IF text.element = NIL THEN Sasl.Wipe(text.text) END;
          text := text.next
        END
      END
    END;
    content := content.next
  END
END Wipe;

PROCEDURE (form: Form) Clear*;
  VAR i: LONGINT;
BEGIN
  IF form.cleared THEN RETURN END;
  FOR i := 0 TO form.count-1 DO Sasl.Wipe(form.fields[i].value) END;
  Sasl.Wipe(form.instructions); IF form.source # NIL THEN Wipe(form.source) END;
  form.units := 0; form.cleared := TRUE; form.legacy := FALSE; form.owner := NIL; form.source := NIL
END Clear;

PROCEDURE Submit*(router: IQ.Router; form: Form; timeoutMS: LONGINT; action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
  VAR query, field: Items.Item; request: IQ.Request; total, i, j: LONGINT;
BEGIN
  IF (form = NIL) OR form.cleared OR ~form.legacy THEN RETURN Invalid(unsupported, error) END;
  IF (router = NIL) OR (router.client # form.owner) THEN RETURN Invalid(invalidRequest, error) END;
  total := S.Length(form.instructions^);
  FOR i := 0 TO form.count-1 DO
    IF ~Known(form.fields[i].name^) OR ~IQ.Value(form.fields[i].value^, maxFieldUnits) THEN RETURN Invalid(invalidRequest, error) END;
    FOR j := 0 TO i-1 DO
      IF form.fields[j].name^ = form.fields[i].name^ THEN RETURN Invalid(invalidRequest, error) END
    END;
    INC(total, S.Length(form.fields[i].value^)); IF total > maxTotalUnits THEN RETURN Invalid(invalidRequest, error) END
  END;
  query := Items.New("query", namespaceURI);
  FOR i := 0 TO form.count-1 DO
    field := Items.New(form.fields[i].name^, namespaceURI);
    field.AddText(form.fields[i].value^, 0, S.Length(form.fields[i].value^)); query.AddChild(field)
  END;
  request := router.QueryExact(form.peer^, query, TRUE, timeoutMS, action, error);
  Wipe(query); RETURN request
END Submit;

PROCEDURE Remove*(router: IQ.Router; peer: ARRAY OF T.CodeUnit; timeoutMS: LONGINT;
                  action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
  VAR target: T.String; query: Items.Item;
BEGIN
  IF (router = NIL) OR (router.client = NIL) OR (router.client.state # Client.online) OR
     ~router.client.authenticated THEN RETURN Invalid(authenticationRequired, error) END;
  target := Target(router, peer, error); IF target = NIL THEN RETURN NIL END;
  query := Items.New("query", namespaceURI); query.AddChild(Items.New("remove", namespaceURI));
  RETURN router.QueryExact(target^, query, TRUE, timeoutMS, action, error)
END Remove;

BEGIN NEW(context); Msg.InitContext(context, "XmppRegister")
END XmppRegister.
