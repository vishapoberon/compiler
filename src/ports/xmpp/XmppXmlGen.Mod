MODULE XmppXmlGen;

(* Encoding namespace-aware stanza trees as bounded, checked UTF-8 XML. *)

IMPORT Msg, S := LongStrings, IntStr, Mem := IOMemory,
  W := XMLWriter, UTF8 := XMLUnicodeCodecUTF8, P := XMLParser,
  NS := XMLBuilderNamespaces, B := XMLBuilder, L := XMLLimits,
  T := XmppTypes, Items := XmppItems, Const := XmppConst;

CONST xmlURI = "http://www.w3.org/XML/1998/namespace";

TYPE
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR template: Msg.LString);
BEGIN S.Long("Cannot encode XMPP stanza XML", template) END GetTemplate;

PROCEDURE QName(prefix: ARRAY OF CHAR; name: T.String): T.String;
  VAR qname: T.String; length: LONGINT;
BEGIN
  length := S.Length8(prefix); NEW(qname, length+S.Length(name^)+2);
  S.Long(prefix, qname^); qname[length] := ORD(":"); qname[length+1] := 0;
  S.Append(name^, qname^); RETURN qname
END QName;

PROCEDURE LocalName(name: T.String; budget: L.Budget): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  IF (name = NIL) OR (name[0] = 0) OR ~P.IsNameChar0(name[0]) THEN RETURN FALSE END;
  i := 0;
  WHILE (i < LEN(name^)) & (name[i] # 0) DO
    IF ~budget.Charge(L.work, 1) OR (name[i] = ORD(":")) OR ~P.IsNameChar(name[i]) THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN i < LEN(name^)
END LocalName;

PROCEDURE Element(item: Items.Item; writer: W.Writer; budget: L.Budget;
                  depth: LONGINT; streamRoot: BOOLEAN);
  VAR attr: Items.Attribute; content: Items.Content; uri, name: T.String;
    index, i: LONGINT; prefix: ARRAY 32 OF CHAR; number: ARRAY 24 OF CHAR;
BEGIN
  IF budget.error # NIL THEN RETURN END;
  IF (item = NIL) OR (item.name = NIL) OR (item.namespaceURI = NIL) THEN budget.Fail(L.work); RETURN END;
  IF depth > 64 THEN budget.Fail(L.nesting); RETURN END;
  IF ~budget.Charge(L.work, 1) THEN RETURN END;
  IF ~LocalName(item.name, budget) THEN budget.Fail(L.work); RETURN END;
  IF streamRoot THEN
    writer.StartTagLatin1("stream:stream", TRUE);
    name := Items.Latin1("xmlns:stream"); uri := Items.Latin1(Const.uriStream);
    writer.AttrString(name^, uri^);
    uri := Items.Latin1(Const.jabberClient)
  ELSE
    writer.StartTag(item.name^, TRUE); uri := Items.UTF8(item.namespaceURI^)
  END;
  name := Items.Latin1("xmlns");
  IF uri = NIL THEN budget.Fail(L.work); RETURN END;
  writer.AttrString(name^, uri^); attr := item.attributes; index := 0;
  WHILE (attr # NIL) & (budget.error = NIL) DO
    IF ~budget.Charge(L.work, 1) THEN RETURN END;
    IF ~LocalName(attr.name, budget) OR
       ((attr.namespaceURI^ = "") & S.Equal8(attr.name^, "xmlns")) THEN
      budget.Fail(L.work); RETURN
    END;
    IF attr.namespaceURI^ = "" THEN name := attr.name
    ELSIF attr.namespaceURI^ = xmlURI THEN name := QName("xml", attr.name)
    ELSE
      IntStr.IntToStr(index, number); prefix[0] := "a"; i := 0;
      REPEAT prefix[i+1] := number[i]; INC(i) UNTIL number[i-1] = 0X;
      name := QName("xmlns", Items.Latin1(prefix)); uri := Items.UTF8(attr.namespaceURI^);
      IF uri = NIL THEN budget.Fail(L.work); RETURN END;
      writer.AttrString(name^, uri^); name := QName(prefix, attr.name)
    END;
    writer.AttrString(name^, attr.value^); INC(index); attr := attr.next
  END;
  content := item.content;
  WHILE (content # NIL) & (budget.error = NIL) DO
    IF ~budget.Charge(L.work, 1) THEN RETURN END;
    IF content.element # NIL THEN Element(content.element, writer, budget, depth+1, FALSE)
    ELSE writer.Write(content.text^)
    END;
    content := content.next
  END;
  IF budget.error = NIL THEN writer.EndTag END
END Element;

PROCEDURE Document(item: Items.Item; maxBytes: LONGINT; streamRoot: BOOLEAN;
                   VAR bytes: Items.Bytes; VAR length: LONGINT; VAR error: Msg.Msg);
  VAR ch: Mem.Channel; writer: W.Writer; budget: L.Budget; parser: P.Parser; i: LONGINT;
BEGIN
  ASSERT((maxBytes > 0) & (maxBytes <= 16*1024*1024));
  bytes := NIL; length := 0; error := NIL;
  ch := Mem.Tmp("", {Mem.read, Mem.write}, error); IF error # NIL THEN RETURN END;
  budget := L.New(); budget.maxOutputBytes := maxBytes;
  writer := W.New(L.WrapWriter(ch.NewWriter(), budget), UTF8.factory, FALSE, -1);
  Element(item, writer, budget, 1, streamRoot);
  IF budget.error # NIL THEN error := budget.error
  ELSE
    writer.EndOfText;
    IF writer.writer.res # NIL THEN error := writer.writer.res
    ELSIF writer.codec.invalidChars # 0 THEN error := Msg.New(context, 1)
    END
  END;
  IF error = NIL THEN
    budget := L.New(); budget.maxInputBytes := maxBytes;
    parser := P.NewChannelLimited(ch, NIL, UTF8.factory, NIL, NS.New(B.New()), budget);
    parser.followExternalRef := FALSE; parser.enforceQNames := TRUE; parser.ParseDocument;
    IF parser.errList.msgCount # 0 THEN error := parser.errList.msgList END
  END;
  IF error = NIL THEN
    length := ch.Length(); NEW(bytes, length+1);
    FOR i := 0 TO length-1 DO bytes[i] := ch.file.data[i] END; bytes[length] := 0X
  END;
  ch.Close
END Document;

PROCEDURE Encode*(item: Items.Item; maxBytes: LONGINT; VAR bytes: Items.Bytes;
                  VAR length: LONGINT; VAR error: Msg.Msg);
BEGIN Document(item, maxBytes, FALSE, bytes, length, error) END Encode;

PROCEDURE OpenStream*(to, from, id, lang: ARRAY OF T.CodeUnit;
                      VAR bytes: Items.Bytes; VAR length: LONGINT; VAR error: Msg.Msg);
(* Checks a complete empty stream document, then exposes its opening tag only. *)
  VAR root: Items.Item; name, version: T.String;
BEGIN
  root := Items.New("stream", Const.uriStream);
  version := Items.Latin1("1.0"); root.SetParam("version", version^);
  IF S.Length(to) > 0 THEN root.SetParam("to", to) END;
  IF S.Length(from) > 0 THEN root.SetParam("from", from) END;
  IF S.Length(id) > 0 THEN root.SetParam("id", id) END;
  IF S.Length(lang) > 0 THEN
    name := Items.Latin1("lang"); root.SetAttribute(name^, xmlURI, lang)
  END;
  Document(root, 16384, TRUE, bytes, length, error);
  IF error = NIL THEN
    ASSERT((length >= 2) & (bytes[length-2] = "/") & (bytes[length-1] = ">"));
    DEC(length); bytes[length-1] := ">"; bytes[length] := 0X
  END
END OpenStream;

PROCEDURE CloseStream*(): Items.Bytes;
BEGIN RETURN Items.Copy8("</stream:stream>") END CloseStream;

BEGIN
  NEW(context); Msg.InitContext(context, "XmppXmlGen")
END XmppXmlGen.
