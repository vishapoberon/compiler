MODULE XmppXmlStream;

(* Receiving the stream header and complete stanzas through ooc-xml. Feed
   returns after one event so the caller can handle stream restarts and TLS. *)

IMPORT Msg, S := LongStrings, D := XMLDTD, B := XMLBuilder, Limits := XMLLimits,
  XML := XMLStream, Items := XmppItems;

CONST
  needInput* = XML.needInput; opened* = XML.opened; stanza* = XML.stanza;
  closed* = XML.closed; failed* = XML.failed;
  streamsURI* = "http://etherx.jabber.org/streams";
  defaultNodes* = 16384;

TYPE
  Capture = POINTER TO CaptureDesc;
  Stream* = POINTER TO StreamDesc;
  StreamDesc* = RECORD
    header-, item-: Items.Item;
    error-: Msg.Msg;
    xml: XML.Stream;
    builder: Capture;
  END;
  CaptureDesc = RECORD (B.BuilderDesc)
    root, current: Items.Item;
    count, maximum: LONGINT;
  END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR template: Msg.LString);
BEGIN S.Long("XMPP requires a stream element in the streams namespace", template) END GetTemplate;

PROCEDURE (b: Capture) StartDocument(document: D.ExternalEntity);
BEGIN b.root := NIL; b.current := NIL; b.count := 0 END StartDocument;

PROCEDURE Take(b: Capture): BOOLEAN;
BEGIN
  IF b.limits.error # NIL THEN RETURN FALSE END;
  IF b.count = b.maximum THEN b.limits.Fail(Limits.work); RETURN FALSE END;
  INC(b.count); RETURN b.Charge(1)
END Take;

PROCEDURE (b: Capture) StartElement(ns: D.NamespaceDeclaration; name: D.String);
  VAR item: Items.Item;
BEGIN
  IF ~Take(b) THEN RETURN END;
  IF ns = NIL THEN item := Items.New16(name^, "") ELSE item := Items.New16(name^, ns.uri^) END;
  IF b.current = NIL THEN b.root := item ELSE b.current.AddChild(item) END;
  b.current := item
END StartElement;

PROCEDURE (b: Capture) EndElement(ns: D.NamespaceDeclaration; name: D.String);
BEGIN IF b.limits.error = NIL THEN b.current := b.current.parent END END EndElement;

PROCEDURE (b: Capture) Attribute(ns: D.NamespaceDeclaration; name: D.String;
  declaration: D.AttrDecl; value: D.AttValue; specified: BOOLEAN);
  VAR text: D.String; normalized: BOOLEAN;
BEGIN
  IF ~Take(b) THEN RETURN END;
  text := value.FlattenValue(FALSE, normalized);
  IF ns = NIL THEN b.current.SetAttribute(name^, "", text^)
  ELSE b.current.SetAttribute(name^, ns.uri^, text^)
  END
END Attribute;

PROCEDURE (b: Capture) Characters(VAR chars: D.StringVar; start, end: D.CharPos;
                                whitespace: D.ElementWhitespaceType);
BEGIN
  IF (b.current # NIL) & (end > start) & Take(b) THEN b.current.AddText(chars, start, end) END
END Characters;

PROCEDURE (s: Stream) Feed*(VAR bytes: ARRAY OF CHAR; start, count: LONGINT;
                          VAR consumed: LONGINT): SHORTINT;
  VAR event: SHORTINT; root: Items.Item;
BEGIN
  consumed := 0; s.item := NIL;
  IF s.error # NIL THEN RETURN failed END;
  event := s.xml.Feed(bytes, start, count, s.builder, consumed);
  IF event = failed THEN s.error := s.xml.error
  ELSIF event = opened THEN
    root := s.builder.root;
    IF ~S.Equal8(root.name^, "stream") OR (root.namespaceURI^ # streamsURI) THEN
      s.error := Msg.New(context, 1); s.builder.root := NIL; RETURN failed
    END;
    s.header := root; s.item := root
  ELSIF event = stanza THEN
    root := s.builder.root;
    IF (root.content # NIL) & (root.content.element # NIL) THEN s.item := root.content.element END
  END;
  IF event # needInput THEN s.builder.root := NIL; s.builder.current := NIL END;
  RETURN event
END Feed;

PROCEDURE (s: Stream) Restart*(): BOOLEAN;
BEGIN
  IF (s.error # NIL) OR ~s.xml.Restart() THEN RETURN FALSE END;
  s.header := NIL; s.item := NIL; RETURN TRUE
END Restart;

PROCEDURE (s: Stream) Finish*(): BOOLEAN;
BEGIN
  IF s.error # NIL THEN RETURN FALSE END;
  IF ~s.xml.Finish() THEN s.error := s.xml.error; RETURN FALSE END;
  RETURN TRUE
END Finish;

PROCEDURE NewLimited*(maxHeaderBytes, maxStanzaBytes, maxNesting, maxNodes: LONGINT): Stream;
  VAR s: Stream;
BEGIN
  ASSERT(maxNodes > 0); NEW(s); NEW(s.builder); B.Init(s.builder);
  s.builder.maximum := maxNodes;
  s.xml := XML.New(maxHeaderBytes, maxStanzaBytes, maxNesting);
  RETURN s
END NewLimited;

PROCEDURE New*(): Stream;
BEGIN RETURN NewLimited(XML.defaultHeaderBytes, XML.defaultStanzaBytes, XML.defaultNesting, defaultNodes) END New;

BEGIN
  NEW(context); Msg.InitContext(context, "XmppXmlStream")
END XmppXmlStream.
