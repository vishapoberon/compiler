MODULE XmppVersion;

(* XEP-0092 software version. Applications explicitly supply published metadata. *)

IMPORT Msg, S := LongStrings, T := XmppTypes, Items := XmppItems, Core := XmppCore, IQ := XmppIQ;

CONST namespaceURI* = "jabber:iq:version";
TYPE Version* = POINTER TO VersionDesc;
  VersionDesc* = RECORD (IQ.HandlerDesc) name, version, os: T.String END;

PROCEDURE Text(parent: Items.Item; name: ARRAY OF CHAR; text: T.String);
  VAR child: Items.Item;
BEGIN child := Items.New(name, namespaceURI); child.AddText(text^, 0, S.Length(text^)); parent.AddChild(child) END Text;

PROCEDURE (v: Version) Handle*(router: IQ.Router; request: Core.Stanza; payload: Items.Item): Core.Stanza;
  VAR query: Items.Item;
BEGIN
  IF ~S.Equal8(request.type^, "get") OR ~IQ.Empty(payload) THEN RETURN IQ.ErrorReply(request, "modify", "bad-request") END;
  query := Items.New("query", namespaceURI); Text(query, "name", v.name); Text(query, "version", v.version);
  IF v.os[0] # 0 THEN Text(query, "os", v.os) END;
  RETURN IQ.Response(request, query)
END Handle;

PROCEDURE Query*(router: IQ.Router; to: ARRAY OF T.CodeUnit; timeoutMS: LONGINT;
                  action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
BEGIN RETURN router.Query(to, Items.New("query", namespaceURI), FALSE, timeoutMS, action, error) END Query;

PROCEDURE Read*(request: IQ.Request; VAR name, version, os: T.String): BOOLEAN;
  VAR query, child: Items.Item; content, text: Items.Content; value: T.String;
BEGIN
  name := NIL; version := NIL; os := NIL; query := IQ.Payload(request, namespaceURI, "query");
  IF query = NIL THEN RETURN FALSE END;
  content := query.content;
  WHILE content # NIL DO
    child := content.element;
    IF (child # NIL) & (child.namespaceURI^ = namespaceURI) THEN
      IF S.Equal8(child.name^, "name") OR S.Equal8(child.name^, "version") OR S.Equal8(child.name^, "os") THEN
        text := child.content;
        WHILE text # NIL DO IF text.element # NIL THEN RETURN FALSE END; text := text.next END;
        value := child.Text(); IF ~IQ.Value(value^, 256) THEN RETURN FALSE END;
        IF S.Equal8(child.name^, "name") THEN IF name # NIL THEN RETURN FALSE END; name := value
        ELSIF S.Equal8(child.name^, "version") THEN IF version # NIL THEN RETURN FALSE END; version := value
        ELSE IF os # NIL THEN RETURN FALSE END; os := value
        END
      END
    END;
    content := content.next
  END;
  IF (name = NIL) OR (version = NIL) OR (name[0] = 0) OR (version[0] = 0) THEN RETURN FALSE END;
  IF os = NIL THEN os := Items.Latin1("") END;
  RETURN TRUE
END Read;

PROCEDURE New*(router: IQ.Router; name, version, os: ARRAY OF T.CodeUnit): Version;
  VAR v: Version;
BEGIN
  IF (name[0] = 0) OR (version[0] = 0) OR ~IQ.Value(name, 256) OR ~IQ.Value(version, 256) OR ~IQ.Value(os, 256) THEN RETURN NIL END;
  NEW(v); v.name := Items.Copy16(name); v.version := Items.Copy16(version); v.os := Items.Copy16(os);
  IF ~router.Register(namespaceURI, "query", v) THEN RETURN NIL END; RETURN v
END New;

END XmppVersion.
