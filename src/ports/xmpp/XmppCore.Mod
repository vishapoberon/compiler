MODULE XmppCore;

(* Stanza metadata and transport-independent session delivery. Stanza kinds
   are selected by expanded XML names rather than peer-chosen prefixes. *)

IMPORT S := LongStrings, Msg, Channel, T := XmppTypes, Const := XmppConst,
  Items := XmppItems, C := XmppConnections;

CONST other* = 0; iq* = 1; message* = 2; presence* = 3;
  xmlURI* = "http://www.w3.org/XML/1998/namespace";

TYPE
  Stanza* = POINTER TO StanzaDesc;
  StanzaDesc* = RECORD
    kind-: SHORTINT;
    to-, from-, lang-, id-, type-: T.String;
    item-: Items.Item;
  END;
  Session* = POINTER TO SessionDesc;
  Hook* = POINTER TO HookDesc;
  HookDesc* = RECORD END;
  SessionDesc* = RECORD (C.OwnerDesc)
    connection-: C.Connection;
    header-, features-: Items.Item;
    last-: Stanza;
    error-: Msg.Msg;
    hook: Hook;
  END;

PROCEDURE Kind*(item: Items.Item): SHORTINT;
BEGIN
  IF item.namespaceURI^ # Const.jabberClient THEN RETURN other END;
  IF S.Equal8(item.name^, Const.iq) THEN RETURN iq
  ELSIF S.Equal8(item.name^, Const.message) THEN RETURN message
  ELSIF S.Equal8(item.name^, Const.presence) THEN RETURN presence
  ELSE RETURN other
  END
END Kind;

PROCEDURE Param(item: Items.Item; name: ARRAY OF CHAR): T.String;
  VAR value: T.String;
BEGIN
  value := item.GetAttribute("", name);
  IF value = NIL THEN value := Items.Latin1("") END;
  RETURN value
END Param;

PROCEDURE Wrap*(item, header: Items.Item): Stanza;
  VAR stanza: Stanza;
BEGIN
  ASSERT(item # NIL); NEW(stanza); stanza.item := item; stanza.kind := Kind(item);
  stanza.to := Param(item, Const.to); stanza.from := Param(item, Const.from);
  stanza.id := Param(item, Const.id); stanza.type := Param(item, Const.type);
  stanza.lang := item.GetAttribute(xmlURI, "lang");
  IF (stanza.lang = NIL) & (header # NIL) THEN stanza.lang := header.GetAttribute(xmlURI, "lang") END;
  IF stanza.lang = NIL THEN stanza.lang := Items.Latin1("") END;
  RETURN stanza
END Wrap;

PROCEDURE NewStanza*(name: ARRAY OF CHAR): Stanza;
BEGIN RETURN Wrap(Items.New(name, Const.jabberClient), NIL) END NewStanza;

PROCEDURE (s: Stanza) Set*(to, from, lang, id, type: ARRAY OF T.CodeUnit);
  VAR name: T.String;
BEGIN
  s.to := Items.Copy16(to); s.from := Items.Copy16(from); s.lang := Items.Copy16(lang);
  s.id := Items.Copy16(id); s.type := Items.Copy16(type);
  s.item.SetParam(Const.to, to); s.item.SetParam(Const.from, from);
  s.item.SetParam(Const.id, id); s.item.SetParam(Const.type, type);
  name := Items.Latin1("lang"); s.item.SetAttribute(name^, xmlURI, lang)
END Set;

PROCEDURE (s: Stanza) Data*(): Items.Item;
BEGIN RETURN s.item END Data;

PROCEDURE (hook: Hook) Opened*(session: Session; header: Items.Item);
BEGIN END Opened;
PROCEDURE (hook: Hook) In*(session: Session; stanza: Stanza);
BEGIN END In;
PROCEDURE (hook: Hook) Out*(session: Session; stanza: Stanza);
BEGIN END Out;
PROCEDURE (hook: Hook) Other*(session: Session; item: Items.Item);
BEGIN END Other;
PROCEDURE (hook: Hook) Error*(session: Session; error: Msg.Msg);
BEGIN END Error;
PROCEDURE (hook: Hook) Closed*(session: Session);
BEGIN END Closed;

PROCEDURE (s: Session) Opened*(header: Items.Item);
BEGIN s.header := header; s.features := NIL; s.hook.Opened(s, header) END Opened;

PROCEDURE (s: Session) UpdateRead*(item: Items.Item);
BEGIN
  IF Kind(item) # other THEN
    s.last := Wrap(item, s.header); s.hook.In(s, s.last)
  ELSE
    IF (item.namespaceURI^ = Const.uriStream) & S.Equal8(item.name^, "features") THEN s.features := item END;
    s.hook.Other(s, item)
  END
END UpdateRead;

PROCEDURE (s: Session) UpdateWrite*(item: Items.Item);
BEGIN s.hook.Out(s, Wrap(item, NIL)) END UpdateWrite;

PROCEDURE (s: Session) UpdateError*(error: Msg.Msg);
BEGIN s.error := error; s.hook.Error(s, error) END UpdateError;

PROCEDURE (s: Session) Closed*;
BEGIN s.hook.Closed(s) END Closed;

PROCEDURE (s: Session) Feed*(VAR bytes: ARRAY OF CHAR; start, count: LONGINT;
                          VAR consumed: LONGINT): SHORTINT;
BEGIN RETURN s.connection.Feed(bytes, start, count, consumed) END Feed;

PROCEDURE (s: Session) Restart*(): BOOLEAN;
BEGIN
  IF ~s.connection.Restart() THEN RETURN FALSE END;
  s.header := NIL; s.features := NIL; s.last := NIL; RETURN TRUE
END Restart;

PROCEDURE (s: Session) Send*(stanza: Stanza; VAR error: Msg.Msg);
BEGIN s.connection.WriteData(stanza.item, error) END Send;

PROCEDURE (s: Session) StartStream*(to, from, id, lang: ARRAY OF T.CodeUnit; VAR error: Msg.Msg);
BEGIN s.connection.OpenStream(to, from, id, lang, error) END StartStream;

PROCEDURE (s: Session) CloseStream*(VAR error: Msg.Msg);
BEGIN s.connection.CloseStream(error) END CloseStream;

PROCEDURE (s: Session) HasFeature*(namespaceURI, name: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN (s.features # NIL) & (s.features.First(namespaceURI, name) # NIL) END HasFeature;

PROCEDURE NewSession*(hook: Hook; output: Channel.Writer): Session;
  VAR s: Session;
BEGIN
  ASSERT(hook # NIL); NEW(s); s.hook := hook; s.connection := C.New(s, output); RETURN s
END NewSession;

END XmppCore.
